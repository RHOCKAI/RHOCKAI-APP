# app/api/v1/endpoints/sessions.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User
from app.models.workout_session import WorkoutSession
from app.schemas.session import SessionCreate, SessionUpdate, SessionResponse

router = APIRouter()

@router.post("/sessions", response_model=SessionResponse)
async def create_session(
    session_data: SessionCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create new workout session"""
    db_session = WorkoutSession(
        user_id=current_user.id,
        exercise_type=session_data.exercise_type,
        start_time=session_data.start_time,
    )
    
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    
    return db_session

@router.patch("/sessions/{session_id}", response_model=SessionResponse)
async def update_session(
    session_id: int,
    session_data: SessionUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update workout session (complete session)"""
    db_session = db.query(WorkoutSession).filter(
        WorkoutSession.id == session_id,
        WorkoutSession.user_id == current_user.id
    ).first()
    
    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Update fields
    data = session_data.dict(exclude_unset=True)
    
    # Auto-calculate power_score if not provided but dependencies are present
    if "power_score" not in data and "total_reps" in data and "average_accuracy" in data:
        data["power_score"] = (data["total_reps"] * data["accuracy"] / 100) if "accuracy" in data else (data["total_reps"] * (session_data.average_accuracy or db_session.average_accuracy) / 100)
    
    # Wait, the field is average_accuracy in schema. Let's be precise.
    if "power_score" not in data:
        reps = data.get("total_reps", db_session.total_reps)
        accuracy = data.get("average_accuracy", db_session.average_accuracy)
        if reps is not None and accuracy is not None:
            data["power_score"] = (reps * accuracy) / 100

    for field, value in data.items():
        setattr(db_session, field, value)
    
    db.commit()
    db.refresh(db_session)
    
    return db_session

@router.get("/sessions", response_model=List[SessionResponse])
async def get_user_sessions(
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user's workout sessions"""
    sessions = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id
    ).order_by(WorkoutSession.start_time.desc()).offset(skip).limit(limit).all()
    
    return sessions

@router.get("/sessions/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get specific session details"""
    session = db.query(WorkoutSession).filter(
        WorkoutSession.id == session_id,
        WorkoutSession.user_id == current_user.id
    ).first()
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    return session