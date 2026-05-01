"""
Session repository
"""

from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func, and_

from app.repositories.base import BaseRepository
from app.models.workout_session import WorkoutSession
from app.schemas.session import SessionCreate, SessionUpdate


class SessionRepository(BaseRepository[WorkoutSession, SessionCreate, SessionUpdate]):
    def __init__(self):
        super().__init__(WorkoutSession)
    
    def get_by_user(
        self,
        db: Session,
        *,
        user_id: int,
        skip: int = 0,
        limit: int = 20,
        exercise_type: Optional[str] = None
    ) -> List[WorkoutSession]:
        query = db.query(WorkoutSession).filter(WorkoutSession.user_id == user_id)
        
        if exercise_type:
            query = query.filter(WorkoutSession.exercise_type == exercise_type)
        
        return query.order_by(WorkoutSession.created_at.desc()).offset(skip).limit(limit).all()
    
    def get_user_session_by_id(
        self,
        db: Session,
        *,
        session_id: int,
        user_id: int
    ) -> Optional[WorkoutSession]:
        return db.query(WorkoutSession).filter(
            and_(
                WorkoutSession.id == session_id,
                WorkoutSession.user_id == user_id
            )
        ).first()
    
    def get_recent_sessions(
        self,
        db: Session,
        *,
        user_id: int,
        days: int = 7
    ) -> List[WorkoutSession]:
        since_date = datetime.utcnow() - timedelta(days=days)
        
        return db.query(WorkoutSession).filter(
            and_(
                WorkoutSession.user_id == user_id,
                WorkoutSession.created_at >= since_date
            )
        ).order_by(WorkoutSession.created_at.desc()).all()
    
    def get_stats(
        self,
        db: Session,
        *,
        user_id: int,
        days: int = 7,
        exercise_type: Optional[str] = None
    ) -> dict:
        since_date = datetime.utcnow() - timedelta(days=days)
        
        query = db.query(
            func.count(WorkoutSession.id).label('total_sessions'),
            func.sum(WorkoutSession.total_reps).label('total_reps'),
            func.sum(WorkoutSession.calories_burned).label('total_calories'),
            func.avg(WorkoutSession.average_accuracy).label('avg_accuracy'),
            func.sum(WorkoutSession.duration_seconds).label('total_duration'),
        ).filter(
            and_(
                WorkoutSession.user_id == user_id,
                WorkoutSession.created_at >= since_date
            )
        )
        
        if exercise_type:
            query = query.filter(WorkoutSession.exercise_type == exercise_type)
        
        result = query.first()
        
        return {
            'total_sessions': result.total_sessions or 0,
            'total_reps': int(result.total_reps or 0),
            'total_calories': int(result.total_calories or 0),
            'average_accuracy': round(float(result.avg_accuracy or 0), 2),
            'total_duration_minutes': int((result.total_duration or 0) / 60),
        }
    
    def count_user_sessions(
        self,
        db: Session,
        *,
        user_id: int,
        exercise_type: Optional[str] = None
    ) -> int:
        query = db.query(WorkoutSession).filter(WorkoutSession.user_id == user_id)
        
        if exercise_type:
            query = query.filter(WorkoutSession.exercise_type == exercise_type)
        
        return query.count()


session_repo = SessionRepository()