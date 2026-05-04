"""
User-related Pydantic schemas
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from app.models.user import Gender, FitnessLevel

class UserBase(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    full_name: Optional[str] = Field(None, description="User's full name")
    gender: Optional[Gender] = Field(None, description="User's gender")
    age: Optional[int] = Field(None, ge=0, le=120, description="User's age")
    height: Optional[int] = Field(None, ge=50, le=250, description="Height in cm")
    weight: Optional[int] = Field(None, ge=20, le=300, description="Weight in kg")
    fitness_level: FitnessLevel = Field(
        default=FitnessLevel.beginner, 
        description="User's fitness level"
    )

class UserCreate(UserBase):
    password: str = Field(..., min_length=6, description="User password")

class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, description="User's full name")
    gender: Optional[Gender] = Field(None, description="User's gender")
    age: Optional[int] = Field(None, ge=0, le=120, description="User's age")
    height: Optional[int] = Field(None, ge=50, le=250, description="Height in cm")
    weight: Optional[int] = Field(None, ge=20, le=300, description="Weight in kg")
    fitness_level: Optional[FitnessLevel] = Field(None, description="User's fitness level")
    language: Optional[str] = Field(None, description="Preferred language")
    theme: Optional[str] = Field(None, description="UI theme preference")
    voice_feedback: Optional[bool] = Field(None, description="Enable voice feedback")

class UserResponse(UserBase):
    id: int = Field(..., description="User ID")
    is_premium: bool = Field(default=False, description="Premium access (paid subscription or active trial)")
    is_trial: bool = Field(default=False, description="True if user is in free trial period")
    trial_ends_at: Optional[datetime] = Field(None, description="When the free trial expires")
    language: str = Field(default="en", description="Preferred language")
    theme: str = Field(default="light", description="UI theme")
    voice_feedback: bool = Field(default=True, description="Voice feedback enabled")
    created_at: datetime = Field(..., description="Account creation timestamp")
    updated_at: Optional[datetime] = Field(None, description="Last update timestamp")
    
    class Config:
        from_attributes = True

# ======================
# AUTHENTICATION SCHEMAS
# ======================

class LoginRequest(BaseModel):
    """Schema for user login request"""
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="User password")

class Token(BaseModel):
    """Schema for JWT token response"""
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiration in seconds")

class TokenData(BaseModel):
    """Schema for decoded token data"""
    email: Optional[str] = Field(None, description="User email from token")
    user_id: Optional[int] = Field(None, description="User ID from token")

# ======================
# PASSWORD RESET SCHEMAS
# ======================

class PasswordResetRequest(BaseModel):
    """Schema for password reset request"""
    email: EmailStr = Field(..., description="User email address")

class PasswordResetConfirm(BaseModel):
    """Schema for password reset confirmation"""
    token: str = Field(..., description="Password reset token")
    new_password: str = Field(..., min_length=6, description="New password")

class ChangePassword(BaseModel):
    """Schema for changing password"""
    current_password: str = Field(..., description="Current password")
    new_password: str = Field(..., min_length=6, description="New password")