from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class DailyHealthMetric(Base):
    """
    Stores daily biometric data fetched from wearables (Apple Health/Google Fit)
    Used to calculate the AI Readiness Score.
    """
    __tablename__ = "daily_health_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    date = Column(DateTime(timezone=True), nullable=False)
    
    # Biometrics
    sleep_duration_hours = Column(Float, nullable=True)
    sleep_quality_score = Column(Integer, nullable=True) # 0-100
    resting_heart_rate = Column(Integer, nullable=True) # bpm
    heart_rate_variability = Column(Float, nullable=True) # ms
    
    # Computed Score
    readiness_score = Column(Integer, nullable=False, default=100) # 0-100
    
    # Timestamps
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    
    user = relationship("User", backref="health_metrics")

    def __repr__(self):
        return f"<DailyHealthMetric(user_id={self.user_id}, readiness={self.readiness_score})>"
