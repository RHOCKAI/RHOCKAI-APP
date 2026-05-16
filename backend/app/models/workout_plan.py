"""
Workout Plan models for AI Dynamic Overload
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class WorkoutPlan(Base):
    """Long-term periodized program tied to a user"""
    __tablename__ = "workout_plans"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    name = Column(String, nullable=False) # e.g., "12-Week Hypertrophy Plan"
    focus = Column(String, nullable=False) # e.g., "strength", "hypertrophy", "endurance"
    
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    
    # Relationships
    user = relationship("User", back_populates="workout_plans")
    scheduled_workouts = relationship("ScheduledWorkout", back_populates="plan", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<WorkoutPlan(id={self.id}, user_id={self.user_id}, name={self.name})>"


class ScheduledWorkout(Base):
    """A specific workout day within a WorkoutPlan"""
    __tablename__ = "scheduled_workouts"
    
    id = Column(Integer, primary_key=True, index=True)
    plan_id = Column(
        Integer,
        ForeignKey("workout_plans.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    day_number = Column(Integer, nullable=False) # Day 1, Day 2, etc.
    target_date = Column(DateTime(timezone=True), nullable=True) # Optional specific date
    name = Column(String, nullable=False) # e.g., "Upper Body Power"
    focus_muscle_groups = Column(JSON, nullable=False) # e.g., ["chest", "triceps"]
    
    is_completed = Column(Boolean, default=False, nullable=False)
    completed_session_id = Column(
        Integer,
        ForeignKey("workout_sessions.id", ondelete="SET NULL"),
        nullable=True
    )
    
    # Relationships
    plan = relationship("WorkoutPlan", back_populates="scheduled_workouts")
    planned_exercises = relationship("PlannedExercise", back_populates="scheduled_workout", cascade="all, delete-orphan", order_by="PlannedExercise.order")
    completed_session = relationship("WorkoutSession")

    def __repr__(self):
        return f"<ScheduledWorkout(id={self.id}, plan_id={self.plan_id}, day={self.day_number})>"


class PlannedExercise(Base):
    """A specific movement with target sets/reps within a ScheduledWorkout"""
    __tablename__ = "planned_exercises"
    
    id = Column(Integer, primary_key=True, index=True)
    scheduled_workout_id = Column(
        Integer,
        ForeignKey("scheduled_workouts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    exercise_id = Column(
        Integer,
        ForeignKey("exercises.id", ondelete="CASCADE"),
        nullable=False,
    )
    
    order = Column(Integer, nullable=False) # Order of the exercise in the workout (1, 2, 3...)
    
    # Target metrics prescribed by the AI
    target_sets = Column(Integer, nullable=False)
    target_reps = Column(Integer, nullable=False)
    target_weight_kg = Column(Integer, nullable=True) # Optional, depends on exercise
    target_rest_seconds = Column(Integer, default=60, nullable=False)
    
    # AI adaptation tracking
    is_substituted = Column(Boolean, default=False, nullable=False) # True if user swapped the exercise
    original_exercise_id = Column(Integer, ForeignKey("exercises.id", ondelete="SET NULL"), nullable=True) # If substituted, what was it originally?
    
    # Relationships
    scheduled_workout = relationship("ScheduledWorkout", back_populates="planned_exercises")
    exercise = relationship("Exercise", foreign_keys=[exercise_id])
    original_exercise = relationship("Exercise", foreign_keys=[original_exercise_id])

    def __repr__(self):
        return f"<PlannedExercise(id={self.id}, workout_id={self.scheduled_workout_id}, order={self.order})>"
