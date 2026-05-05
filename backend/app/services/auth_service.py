"""
Authentication service
"""

import os
from typing import Optional
from datetime import timedelta
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.repositories.user_repo import user_repo
from app.schemas.user import UserCreate, PasswordResetRequest, PasswordResetConfirm
from app.schemas.response import TokenResponse
from app.core.security import create_access_token, get_password_hash, decode_access_token
from app.core.config import settings
from app.models.user import User
from app.services.email_service import email_service


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
    
    def forgot_password(self, db: Session, data: PasswordResetRequest) -> bool:
        user = user_repo.get_by_email(db, email=data.email)
        if not user:
            # We return True even if user doesn't exist for security (don't reveal registered emails)
            return True
        
        # Create a short-lived token (15 minutes)
        reset_token_expires = timedelta(minutes=15)
        reset_token = create_access_token(
            data={"sub": user.email, "type": "password_reset"},
            expires_delta=reset_token_expires
        )
        
        # Send email
        email_service.send_password_reset_email(user.email, reset_token)
        
        return True

    def reset_password(self, db: Session, data: PasswordResetConfirm) -> bool:
        payload = decode_access_token(data.token)
        if not payload or payload.get("type") != "password_reset":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )
        
        email = payload.get("sub")
        user = user_repo.get_by_email(db, email=email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update password
        user.hashed_password = get_password_hash(data.new_password)
        db.commit()
        
        return True

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

    def login_with_google(self, db: Session, id_token_str: str) -> TokenResponse:
        from google.oauth2 import id_token
        from google.auth.transport import requests

        try:
            # Verify the ID token
            id_info = id_token.verify_oauth2_token(
                id_token_str, 
                requests.Request(), 
                settings.GOOGLE_CLIENT_ID
            )

            if id_info['iss'] not in ['accounts.google.com', 'https://accounts.google.com']:
                raise ValueError('Wrong issuer.')

            email = id_info['email']
            full_name = id_info.get('name', 'Google User')

            # Check if user exists
            user = user_repo.get_by_email(db, email=email)

            if not user:
                # Auto-register if user doesn't exist
                user_create = UserCreate(
                    email=email,
                    password=os.urandom(16).hex(), # Random password for social users
                    full_name=full_name,
                    age=25, # Default age
                    gender='other',
                    height=170,
                    weight=70,
                    fitness_level='beginner'
                )
                user = user_repo.create_user(db, obj_in=user_create)
                
                # Update social fields
                user.social_provider = 'google'
                user.social_id = id_info['sub']
                user.is_verified = True # Google users are verified
                db.commit()

            # Generate Rhockai JWT
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

        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Google authentication failed: {str(e)}"
            )


auth_service = AuthService()