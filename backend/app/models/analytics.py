"""
Analytics, Demographics & Subscription Tracking Models
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.core.database import Base

class AppSession(Base):
    """Tracks every app open/close session"""
    __tablename__ = "app_sessions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Session Info
    session_start = Column(DateTime(timezone=True), server_default=func.now())
    session_end = Column(DateTime(timezone=True), nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    
    # Device & OS
    device_type = Column(String, nullable=True)
    device_model = Column(String, nullable=True)
    os_name = Column(String, nullable=True)
    os_version = Column(String, nullable=True)
    app_version = Column(String, nullable=True)
    
    # Location
    country = Column(String, nullable=True)
    city = Column(String, nullable=True)
    timezone = Column(String, nullable=True)
    
    # Network
    connection_type = Column(String, nullable=True)
    
    user = relationship("User", back_populates="app_sessions")


class ScreenView(Base):
    """Tracks every screen/page the user visits"""
    __tablename__ = "screen_views"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    session_id = Column(String, ForeignKey("app_sessions.id"))
    
    screen_name = Column(String, nullable=False)
    previous_screen = Column(String, nullable=True)
    time_on_screen = Column(Integer, nullable=True)
    viewed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Extra context
    extra_data = Column(JSON, nullable=True)
    
    user = relationship("User", back_populates="screen_views")


class FeatureUsage(Base):
    """Tracks which features are used"""
    __tablename__ = "feature_usage"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    feature_name = Column(String, nullable=False)
    action = Column(String, nullable=False)
    used_at = Column(DateTime(timezone=True), server_default=func.now())
    extra_data = Column(JSON, nullable=True)
    
    user = relationship("User", back_populates="feature_usage")


class UserDemographic(Base):
    """User demographic profile"""
    __tablename__ = "user_demographics"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    
    # Personal
    age_range = Column(String, nullable=True)
    gender = Column(String, nullable=True)
    fitness_level = Column(String, nullable=True)
    fitness_goal = Column(String, nullable=True)
    
    # Location
    country = Column(String, nullable=True)
    city = Column(String, nullable=True)
    timezone = Column(String, nullable=True)
    
    # Device preference
    primary_device = Column(String, nullable=True)
    primary_os = Column(String, nullable=True)
    
    # Language
    app_language = Column(String, default="en")
    
    # Onboarding data
    how_found_app = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    user = relationship("User", back_populates="demographic")


class SubscriptionEvent(Base):
    """Tracks every subscription change"""
    __tablename__ = "subscription_events"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Event type
    event_type = Column(String, nullable=False)
    
    # Plan details
    plan_from = Column(String, nullable=True)
    plan_to = Column(String, nullable=True)
    
    # Financial
    amount = Column(Float, nullable=True)
    currency = Column(String, default="USD")
    payment_method = Column(String, nullable=True)
    
    # Stripe/Flutterwave references
    external_subscription_id = Column(String, nullable=True)
    external_transaction_id = Column(String, nullable=True)
    
    # Trial
    trial_start = Column(DateTime(timezone=True), nullable=True)
    trial_end = Column(DateTime(timezone=True), nullable=True)
    converted_from_trial = Column(Boolean, default=False)
    
    # Churn
    cancellation_reason = Column(String, nullable=True)
    
    occurred_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="subscription_events")


class RetentionCohort(Base):
    """Weekly/monthly retention tracking"""
    __tablename__ = "retention_cohorts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    cohort_week = Column(String, nullable=True)
    cohort_month = Column(String, nullable=True)
    
    # Track which weeks user was active after joining
    week_0_active = Column(Boolean, default=True)
    week_1_active = Column(Boolean, default=False)
    week_2_active = Column(Boolean, default=False)
    week_4_active = Column(Boolean, default=False)
    week_8_active = Column(Boolean, default=False)
    week_12_active = Column(Boolean, default=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="retention_cohorts")


class RevenueRecord(Base):
    """Daily revenue tracking for MRR/ARR calculations"""
    __tablename__ = "revenue_records"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    amount = Column(Float, nullable=False)
    currency = Column(String, default="USD")
    amount_usd = Column(Float, nullable=False)
    
    revenue_type = Column(String, nullable=False)
    plan = Column(String, nullable=True)
    
    payment_method = Column(String, nullable=True)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # For MRR normalization
    mrr_contribution = Column(Float, default=0.0)
    
    user = relationship("User", back_populates="revenue_records")


class ErrorLog(Base):
    """Track app errors for quality monitoring"""
    __tablename__ = "error_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    error_type = Column(String, nullable=False)
    error_message = Column(Text, nullable=False)
    stack_trace = Column(Text, nullable=True)
    
    screen = Column(String, nullable=True)
    app_version = Column(String, nullable=True)
    os_name = Column(String, nullable=True)
    os_version = Column(String, nullable=True)
    device_model = Column(String, nullable=True)
    
    occurred_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="error_logs")
