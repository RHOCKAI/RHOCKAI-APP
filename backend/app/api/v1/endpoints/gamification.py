"""
Gamification and Social Endpoints
Daily global leaderboard, AI fitness rating, daily AI fitness challenge, and video sharing.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, nullslast
from typing import List, Optional
from datetime import datetime, timezone, timedelta
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User, FitnessLevel
from app.models.workout_session import WorkoutSession
from app.api.v1.endpoints.ai import EXERCISE_CATALOGUE, ExerciseInfo

router = APIRouter()

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class LeaderboardEntry(BaseModel):
    user_id: int
    full_name: Optional[str] = None
    total_score: float
    sessions_completed: int
    rank: int


class DailyChallenge(BaseModel):
    date: str
    target_exercise: ExerciseInfo
    target_reps: int
    target_duration_seconds: Optional[int] = None
    difficulty_multiplier: float
    description: str


class FitnessRatingUpdateResponse(BaseModel):
    previous_rating: int
    new_rating: int
    level_changed: bool
    new_level: str


class VideoShareRequest(BaseModel):
    video_url: str


class VideoShareResponse(BaseModel):
    session_id: int
    video_url: str
    shared_to_social: bool


# ---------------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------------

def _calculate_session_score(session: WorkoutSession) -> float:
    """Calculate a score for a single workout session."""
    # Simple score: correct reps * accuracy. Can be weighted by exercise difficulty.
    return session.correct_reps * (session.average_accuracy / 100.0)


def _determine_fitness_level(rating: int) -> FitnessLevel:
    """Map a 0-100 rating to a FitnessLevel enum."""
    if rating < 30:
        return FitnessLevel.beginner
    elif rating < 70:
        return FitnessLevel.intermediate
    else:
        return FitnessLevel.advanced


def _get_daily_challenge_for_user(user: User) -> DailyChallenge:
    """Generate a challenge scaled to the user's AI fitness rating."""
    # Determine a base exercise based on the day of the year to ensure it changes daily
    # but is consistent globally for the day.
    day_of_year = datetime.now(timezone.utc).timetuple().tm_yday
    exercise_index = day_of_year % len(EXERCISE_CATALOGUE)
    base_exercise = EXERCISE_CATALOGUE[exercise_index]

    # Scale reps/duration based on user's ai_fitness_rating (0-100 scale)
    base_reps_map = {
        "beginner": 10,
        "intermediate": 20,
        "advanced": 30
    }
    
    # Base target based on exercise's default difficulty
    base_target = base_reps_map.get(base_exercise.difficulty, 15)
    
    # Multiplier based on user's actual 0-100 rating
    # E.g., rating 0 -> multiplier 0.5 (half reps)
    # E.g., rating 50 -> multiplier 1.0 (base reps)
    # E.g., rating 100 -> multiplier 2.0 (double reps)
    multiplier = 0.5 + (user.ai_fitness_rating / 100.0) * 1.5
    
    target_reps = int(base_target * multiplier)
    
    return DailyChallenge(
        date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        target_exercise=base_exercise,
        target_reps=target_reps,
        difficulty_multiplier=round(multiplier, 2),
        description=f"Complete {target_reps} {base_exercise.name}s today based on your fitness level of {user.ai_fitness_rating}/100!"
    )

# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get(
    "/leaderboard/daily",
    response_model=List[LeaderboardEntry],
    summary="Get the daily global leaderboard",
)
async def get_daily_leaderboard(
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> List[LeaderboardEntry]:
    """
    Returns the top users for the current UTC day based on their combined workout session scores.
    """
    now = datetime.now(timezone.utc)
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Get structural data first. It's difficult to aggregate custom score formula fully in generic SQLAlchemy
    # without DB-specific functions, so we aggregate sessions in memory for the top N.
    # For a real scale production app, this should be pre-aggregated in a redis sorted set.
    
    sessions_today = db.query(WorkoutSession).filter(
        WorkoutSession.created_at >= start_of_day
    ).all()
    
    user_scores = {}
    user_names = {}
    user_counts = {}
    
    for session in sessions_today:
        uid = session.user_id
        score = _calculate_session_score(session)
        
        if uid not in user_scores:
            user_scores[uid] = 0.0
            user_counts[uid] = 0
            if session.user.full_name:
                user_names[uid] = session.user.full_name
            else:
                user_names[uid] = f"User {uid}"
                
        user_scores[uid] += score
        user_counts[uid] += 1
        
    # Sort and rank
    sorted_users = sorted(user_scores.items(), key=lambda x: x[1], reverse=True)
    
    leaderboard = []
    for rank, (uid, total_score) in enumerate(sorted_users[:limit], start=1):
        leaderboard.append(
            LeaderboardEntry(
                user_id=uid,
                full_name=user_names.get(uid),
                total_score=round(total_score, 2),
                sessions_completed=user_counts.get(uid, 0),
                rank=rank
            )
        )
        
    return leaderboard


@router.get(
    "/daily-challenge",
    response_model=DailyChallenge,
    summary="Get the personalized daily AI challenge",
)
async def get_daily_challenge(
    current_user: User = Depends(get_current_active_user),
) -> DailyChallenge:
    """
    Generates a daily challenge tailored to the user's specific `ai_fitness_rating`.
    """
    challenge = _get_daily_challenge_for_user(current_user)
    return challenge


@router.post(
    "/recalculate-rating",
    response_model=FitnessRatingUpdateResponse,
    summary="Recalculate and update the user's AI fitness rating",
)
async def recalculate_fitness_rating(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> FitnessRatingUpdateResponse:
    """
    Analyzes the user's recent workout history and recalculates their 0-100 `ai_fitness_rating`.
    If the rating crosses a threshold, their overall `fitness_level` enum is also updated.
    """
    # Fetch last 10 completed sessions
    recent_sessions = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.end_time != None
    ).order_by(desc(WorkoutSession.created_at)).limit(10).all()
    
    previous_rating = current_user.ai_fitness_rating
    previous_level = current_user.fitness_level
    
    if not recent_sessions:
        # Not enough data yet, return current state
        return FitnessRatingUpdateResponse(
            previous_rating=previous_rating,
            new_rating=previous_rating,
            level_changed=False,
            new_level=previous_level.value
        )
        
    # Simple algorithm: average of recent correct_reps * accuracy, normalized to 100
    # A true AI algorithm would use an ML model or more complex scaling.
    total_score = sum(_calculate_session_score(s) for s in recent_sessions)
    average_score = total_score / len(recent_sessions)
    
    # Scale: let's assume a "perfect" session score (e.g. 50 correct reps @ 100% accuracy = 50) maps to max fitness.
    # So we cap at 100, and scale appropriately.
    new_rating_raw = (average_score / 30.0) * 100 
    new_rating = min(max(int(new_rating_raw), 0), 100)
    
    new_level = _determine_fitness_level(new_rating)
    level_changed = new_level != previous_level
    
    current_user.ai_fitness_rating = new_rating
    current_user.fitness_level = new_level
    db.commit()
    
    return FitnessRatingUpdateResponse(
        previous_rating=previous_rating,
        new_rating=new_rating,
        level_changed=level_changed,
        new_level=new_level.value
    )


@router.post(
    "/sessions/{session_id}/video",
    response_model=VideoShareResponse,
    summary="Attach a video URL to a session and mark for social sharing",
)
async def add_session_video(
    session_id: int,
    request: VideoShareRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> VideoShareResponse:
    """
    Saves a captured video URL to a workout session metadata, indicating it was intended for social sharing.
    """
    session = db.query(WorkoutSession).filter(
        WorkoutSession.id == session_id,
        WorkoutSession.user_id == current_user.id
    ).first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
        
    session.video_url = request.video_url
    session.shared_to_social = True
    db.commit()
    
    return VideoShareResponse(
        session_id=session.id,
        video_url=session.video_url,
        shared_to_social=session.shared_to_social
    )
