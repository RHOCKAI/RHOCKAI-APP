"""
User database model
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.core.database import Base


class Gender(str, enum.Enum):
    """Gender enum"""
    male = "male"
    female = "female"
    other = "other"


class FitnessLevel(str, enum.Enum):
    """Fitness level enum"""
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"


class User(Base):
    """User model"""
    __tablename__ = "users"
    
    # Primary key
    id = Column(Integer, primary_key=True, index=True)
    
    # Authentication
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    # Profile information
    full_name = Column(String, nullable=True)
    gender = Column(Enum(Gender), nullable=True)
    age = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)  # cm
    weight = Column(Integer, nullable=True)  # kg
    fitness_level = Column(
        Enum(FitnessLevel),
        default=FitnessLevel.beginner,
        nullable=False,
    )
    ai_fitness_rating = Column(Integer, default=0, nullable=False)  # 0-100 scale computed by AI
    
    # Preferences
    language = Column(String, default="en", nullable=False)
    theme = Column(String, default="light", nullable=False)
    voice_feedback = Column(Boolean, default=True, nullable=False)
    
    # Subscription
    is_premium = Column(Boolean, default=False, nullable=False)
    subscription_end = Column(DateTime(timezone=True), nullable=True)
    stripe_customer_id = Column(String, nullable=True)
    lemon_squeezy_customer_id = Column(String, nullable=True)
    
    # Account status
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now(),
        nullable=True,
    )
    
    # Relationships
    sessions = relationship("WorkoutSession", back_populates="user")
    subscription = relationship("Subscription", back_populates="user", uselist=False)
    app_sessions = relationship("AppSession", back_populates="user")
    screen_views = relationship("ScreenView", back_populates="user")
    feature_usage = relationship("FeatureUsage", back_populates="user")
    demographic = relationship("UserDemographic", back_populates="user", uselist=False)
    subscription_events = relationship("SubscriptionEvent", back_populates="user")
    retention_cohorts = relationship("RetentionCohort", back_populates="user")
    revenue_records = relationship("RevenueRecord", back_populates="user")
    error_logs = relationship("ErrorLog", back_populates="user")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"