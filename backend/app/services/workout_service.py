"""
Workout service
"""

from typing import List, Dict, Optional
from sqlalchemy.orm import Session

from app.repositories.workout_repo import workout_repo
from app.schemas.workout import WorkoutStreak
from app.core.config import settings


class WorkoutService:
    def get_leaderboard(
        self,
        db: Session,
        exercise_type: Optional[str] = None,
        period: str = "week",
        limit: int = 10
    ) -> List[Dict]:
        return workout_repo.get_leaderboard(
            db,
            exercise_type=exercise_type,
            period=period,
            limit=limit
        )
    
    def get_progress_chart(
        self,
        db: Session,
        user_id: int,
        days: int = 30
    ) -> List[Dict]:
        return workout_repo.get_progress_chart(
            db,
            user_id=user_id,
            days=days
        )
    
    def get_workout_streak(
        self,
        db: Session,
        user_id: int
    ) -> WorkoutStreak:
        streak_data = workout_repo.get_workout_streak(db, user_id=user_id)
        return WorkoutStreak(**streak_data)
    
    def get_personal_records(
        self,
        db: Session,
        user_id: int
    ) -> Dict:
        return workout_repo.get_personal_records(db, user_id=user_id)
    
    def calculate_calories(
        self,
        exercise_type: str,
        total_reps: int,
        user_weight: Optional[int] = None
    ) -> int:
        base_calories = settings.CALORIES_PER_REP.get(exercise_type, 0.5)
        
        if user_weight:
            weight_multiplier = user_weight / 70
            base_calories *= weight_multiplier
        
        return int(total_reps * base_calories)


workout_service = WorkoutService()