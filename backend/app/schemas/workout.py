"""
Workout-related schemas
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum


class ExerciseType(str, Enum):
    PUSHUP = "pushup"
    SQUAT = "squat"
    PLANK = "plank"


class WorkoutDifficulty(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class WorkoutSummary(BaseModel):
    exercise_type: str
    total_sessions: int
    total_reps: int
    best_session_reps: int
    average_reps_per_session: float
    total_calories: int
    average_accuracy: float
    best_accuracy: float
    total_duration_minutes: int
    last_workout_date: Optional[datetime]


class WorkoutStreak(BaseModel):
    current_streak: int = Field(..., description="Current consecutive days")
    longest_streak: int = Field(..., description="Longest streak ever")
    total_workout_days: int = Field(..., description="Total unique days")
    last_workout_date: Optional[datetime] = None


class PersonalRecord(BaseModel):
    exercise_type: str
    max_reps_single_session: int
    max_reps_single_set: int
    best_accuracy: float
    longest_duration_minutes: int
    achieved_at: datetime


class ProgressData(BaseModel):
    date: str
    sessions: int
    reps: int
    calories: int
    accuracy: float