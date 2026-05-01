"""
Authentication endpoints for AI Workout Tracker
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.user import UserCreate, UserResponse, LoginRequest, UserUpdate
from app.schemas.response import TokenResponse
from app.services.auth_service import auth_service
from app.api.deps import get_current_active_user
from app.models.user import User

# Create router
router = APIRouter()

@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserCreate, 
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Register a new user
    """
    try:
        user = auth_service.register_user(db, user_data)
        
        return UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            gender=user.gender,
            age=user.age,
            height=user.height,
            weight=user.weight,
            fitness_level=user.fitness_level,
            is_premium=user.is_premium,
            language=user.language,
            theme=user.theme,
            voice_feedback=user.voice_feedback,
            created_at=user.created_at
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
) -> TokenResponse:
    """
    Authenticate user and return JWT token
    """
    try:
        return auth_service.login(db, login_data.email, login_data.password)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )

@router.post("/token", response_model=TokenResponse)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
) -> TokenResponse:
    """
    OAuth2 compatible token login (alternative endpoint)
    """
    try:
        return auth_service.login(db, form_data.username, form_data.password)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Token generation failed: {str(e)}"
        )

@router.get("/me", response_model=UserResponse)
async def read_users_me(
    current_user = Depends(get_current_active_user)
) -> UserResponse:
    """
    Get current user information
    """
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        gender=current_user.gender,
        age=current_user.age,
        height=current_user.height,
        weight=current_user.weight,
        fitness_level=current_user.fitness_level,
        is_premium=current_user.is_premium,
        language=current_user.language,
        theme=current_user.theme,
        voice_feedback=current_user.voice_feedback,
        created_at=current_user.created_at
    )

@router.patch("/me", response_model=UserResponse)
async def update_user_profile(
    user_update: UserUpdate,
    current_user = Depends(get_current_active_user),
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Update current user profile
    """
    # Update user fields
    for field, value in user_update.dict(exclude_unset=True).items():
        if hasattr(current_user, field):
            setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        gender=current_user.gender,
        age=current_user.age,
        height=current_user.height,
        weight=current_user.weight,
        fitness_level=current_user.fitness_level,
        is_premium=current_user.is_premium,
        language=current_user.language,
        theme=current_user.theme,
        voice_feedback=current_user.voice_feedback,
        created_at=current_user.created_at
    )