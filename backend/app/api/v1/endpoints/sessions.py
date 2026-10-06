# app/api/v1/endpoints/sessions.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User
from app.models.workout_session import WorkoutSession
from app.schemas.session import SessionCreate, SessionUpdate, SessionResponse

router = APIRouter()

@router.post("/sessions", response_model=SessionResponse)
async def create_session(
    session_data: SessionCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create new workout session"""
    db_session = WorkoutSession(
        user_id=current_user.id,
        exercise_type=session_data.exercise_type,
        start_time=session_data.start_time,
    )
    
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    
    return db_session

@router.patch("/sessions/{session_id}", response_model=SessionResponse)
async def update_session(
    session_id: int,
    session_data: SessionUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update workout session (complete session)"""
    db_session = db.query(WorkoutSession).filter(
        WorkoutSession.id == session_id,
        WorkoutSession.user_id == current_user.id
    ).first()
    
    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Update fields
    data = session_data.dict(exclude_unset=True)
    
    if "power_score" not in data:
        reps = data.get("total_reps", db_session.total_reps)
        accuracy = data.get("average_accuracy", db_session.average_accuracy)
        data["power_score"] = (reps * accuracy) / 100

    for field, value in data.items():
        setattr(db_session, field, value)
    
    db.commit()
    db.refresh(db_session)
    
    return db_session

@router.get("/sessions", response_model=List[SessionResponse])
async def get_user_sessions(
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user's workout sessions"""
    sessions = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id
    ).order_by(WorkoutSession.start_time.desc()).offset(skip).limit(limit).all()
    
    return sessions

@router.get("/sessions/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get specific session details"""
    session = db.query(WorkoutSession).filter(
        WorkoutSession.id == session_id,
        WorkoutSession.user_id == current_user.id
    ).first()
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    return session


# ---------------------------------------------------------------------------
# AI Dynamic Workout Plan Endpoints
# ---------------------------------------------------------------------------

@router.get("/plan/today")
async def get_today_ai_plan(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Fetch or auto-generate today's progressive overload AI workout plan.
    """
    from app.models.workout_plan import WorkoutPlan, ScheduledWorkout, PlannedExercise
    from app.services.ai_workout_generator import AIWorkoutGenerator

    generator = AIWorkoutGenerator(db)

    active_plan = db.query(WorkoutPlan).filter(
        WorkoutPlan.user_id == current_user.id,
        WorkoutPlan.is_active == True
    ).first()

    if not active_plan:
        active_plan = generator.generate_base_plan(
            user_id=current_user.id,
            plan_name="12-Week AI Hypertrophy Protocol",
            focus="hypertrophy",
            duration_weeks=12
        )

    today_workout = db.query(ScheduledWorkout).filter(
        ScheduledWorkout.plan_id == active_plan.id,
        ScheduledWorkout.is_completed == False
    ).order_by(ScheduledWorkout.day_number.asc()).first()

    if not today_workout:
        completed_count = db.query(ScheduledWorkout).filter(
            ScheduledWorkout.plan_id == active_plan.id,
            ScheduledWorkout.is_completed == True
        ).count()

        focus_pool = [
            ["chest", "triceps"],
            ["quads", "hamstrings", "calves"],
            ["shoulders", "abs"],
        ]
        focus = focus_pool[completed_count % len(focus_pool)]
        today_workout = generator.schedule_daily_workout(
            plan_id=active_plan.id,
            day_number=completed_count + 1,
            focus_muscles=focus
        )

    exercises = []
    for pe in today_workout.planned_exercises:
        ex_name = pe.exercise.name if pe.exercise else "Exercise"
        orig_name = pe.original_exercise.name if pe.original_exercise else None

        ai_note = f"Dynamic target: {pe.target_reps} reps based on past form accuracy."
        if pe.is_substituted:
            ai_note = f"Adapted from {orig_name} to match available movement geometry."

        exercises.append({
            "id": pe.id,
            "exercise_id": pe.exercise_id,
            "name": ex_name,
            "exercise_type": pe.exercise.slug if pe.exercise else "pushup",
            "sets": pe.target_sets,
            "reps": pe.target_reps,
            "target_weight": pe.target_weight_kg,
            "ai_note": ai_note,
            "is_substituted": pe.is_substituted,
            "original_exercise": orig_name,
            "rest_seconds": pe.target_rest_seconds,
            "is_completed": pe.is_completed,
        })

    return {
        "plan_id": active_plan.id,
        "plan_name": active_plan.name,
        "current_day": today_workout.day_number,
        "focus_area": " & ".join(today_workout.focus_muscle_groups).title(),
        "scheduled_workout_id": today_workout.id,
        "exercises": exercises
    }


@router.post("/plan/adapt/{planned_exercise_id}")
async def adapt_plan_exercise(
    planned_exercise_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Equipment / Pain adaptation: swaps an exercise while keeping the same muscle group.
    """
    from app.services.ai_workout_generator import AIWorkoutGenerator
    generator = AIWorkoutGenerator(db)

    try:
        updated = generator.adapt_exercise_for_equipment(
            planned_exercise_id,
            user_id=current_user.id,
        )
        ex_name = updated.exercise.name if updated.exercise else "Exercise"
        orig_name = updated.original_exercise.name if updated.original_exercise else None

        return {
            "id": updated.id,
            "exercise_id": updated.exercise_id,
            "name": ex_name,
            "sets": updated.target_sets,
            "reps": updated.target_reps,
            "target_weight": updated.target_weight_kg,
            "ai_note": f"Substituted from {orig_name} for same muscle stimulus.",
            "is_substituted": True,
            "original_exercise": orig_name,
        }
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/plan/exercises/{planned_exercise_id}/complete")
async def complete_ai_plan_exercise(
    planned_exercise_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    from app.models.workout_plan import PlannedExercise, ScheduledWorkout, WorkoutPlan

    planned_exercise = (
        db.query(PlannedExercise)
        .join(ScheduledWorkout)
        .join(WorkoutPlan)
        .filter(
            PlannedExercise.id == planned_exercise_id,
            WorkoutPlan.user_id == current_user.id,
        )
        .first()
    )
    if planned_exercise is None:
        raise HTTPException(status_code=404, detail="Planned exercise not found")

    planned_exercise.is_completed = True
    workout = planned_exercise.scheduled_workout
    workout.is_completed = bool(workout.planned_exercises) and all(
        exercise.is_completed for exercise in workout.planned_exercises
    )
    db.commit()
    return {
        "planned_exercise_id": planned_exercise.id,
        "is_completed": planned_exercise.is_completed,
        "scheduled_workout_id": workout.id,
        "workout_completed": workout.is_completed,
    }
