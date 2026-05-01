"""
Workout Session database model
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class WorkoutSession(Base):
    """Workout session model - stores completed workout data"""
    __tablename__ = "workout_sessions"
    
    # Primary key
    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign key to user
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    # Session details
    exercise_type = Column(String, nullable=False, index=True)  # pushup, squat, etc.
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=True)
    
    # Metrics
    total_reps = Column(Integer, default=0, nullable=False)
    correct_reps = Column(Integer, default=0, nullable=False)
    average_accuracy = Column(Float, default=0.0, nullable=False)
    average_tempo_score = Column(Float, default=0.0, nullable=False)
    calories_burned = Column(Integer, default=0, nullable=False)
    duration_seconds = Column(Integer, default=0, nullable=False)
    power_score = Column(Float, default=0.0, nullable=False)
    
    # Detailed rep data (stored as JSON array)
    # Format: [{"rep_number": 1, "accuracy": 85.5, "form_issues": [], "timestamp": "..."}]
    reps_data = Column(JSON, nullable=True)
    
    # Additional metadata
    device_type = Column(String, nullable=True)  # ios, android
    app_version = Column(String, nullable=True)
    video_url = Column(String, nullable=True)
    shared_to_social = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    
    # Relationships
    user = relationship("User", back_populates="sessions")
    
    def __repr__(self):
        return f"<WorkoutSession(id={self.id}, user_id={self.user_id}, exercise={self.exercise_type})>"