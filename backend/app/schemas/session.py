"""
Workout session schemas
"""
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime


class RepData(BaseModel):
    rep_number: int
    accuracy: float = Field(..., ge=0, le=100)
    form_issues: List[str] = []
    timestamp: datetime


class SessionCreate(BaseModel):
    exercise_type: str
    start_time: datetime
    device_type: Optional[str] = None
    app_version: Optional[str] = None


class SessionUpdate(BaseModel):
    end_time: Optional[datetime] = None
    total_reps: Optional[int] = Field(None, ge=0)
    correct_reps: Optional[int] = Field(None, ge=0)
    average_accuracy: Optional[float] = Field(None, ge=0, le=100)
    average_tempo_score: Optional[float] = Field(None, ge=0, le=100)
    calories_burned: Optional[int] = Field(None, ge=0)
    duration_seconds: Optional[int] = Field(None, ge=0)
    power_score: Optional[float] = Field(None, ge=0)
    reps_data: Optional[List[Dict[str, Any]]] = None


class SessionResponse(BaseModel):
    id: int
    user_id: int
    exercise_type: str
    start_time: datetime
    end_time: Optional[datetime]
    total_reps: int
    correct_reps: int
    average_accuracy: float
    average_tempo_score: float
    calories_burned: int
    duration_seconds: int
    power_score: float
    reps_data: Optional[List[Dict[str, Any]]]
    created_at: datetime
    
    class Config:
        from_attributes = True


class SessionStats(BaseModel):
    """Aggregate statistics for a time period"""
    total_sessions: int = Field(..., description="Total number of workout sessions")
    total_reps: int = Field(..., description="Total reps across all sessions")
    total_calories: int = Field(..., description="Total calories burned")
    average_accuracy: float = Field(..., ge=0, le=100, description="Average form accuracy percentage")
    total_duration_minutes: int = Field(..., description="Total workout time in minutes")


class ProgressData(BaseModel):
    """Daily progress data for charts"""
    date: str = Field(..., description="Date in YYYY-MM-DD format")
    sessions: int = Field(..., description="Number of sessions on this day")
    reps: int = Field(..., description="Total reps on this day")
    calories: int = Field(..., description="Total calories burned on this day")
    accuracy: float = Field(..., ge=0, le=100, description="Average accuracy on this day")