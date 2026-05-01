"""
Authentication service
"""

from typing import Optional
from datetime import timedelta
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.repositories.user_repo import user_repo
from app.schemas.user import UserCreate
from app.schemas.response import TokenResponse
from app.core.security import create_access_token
from app.core.config import settings
from app.models.user import User


class AuthService:
    def register_user(self, db: Session, user_data: UserCreate) -> User:
        existing_user = user_repo.get_by_email(db, email=user_data.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        user = user_repo.create_user(db, obj_in=user_data)
        return user
    
    def login(self, db: Session, email: str, password: str) -> TokenResponse:
        user = user_repo.authenticate(db, email=email, password=password)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Inactive user account"
            )
        
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.email},
            expires_delta=access_token_expires
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
    
    def get_current_user(self, db: Session, email: str) -> Optional[User]:
        user = user_repo.get_by_email(db, email=email)
        return user
    
    def verify_user(self, db: Session, user_id: int) -> User:
        user = user_repo.get(db, id=user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user.is_verified = True
        db.commit()
        db.refresh(user)
        return user


auth_service = AuthService()