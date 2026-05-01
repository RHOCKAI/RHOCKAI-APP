"""
Session service
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.repositories.session_repo import session_repo
from app.schemas.session import SessionCreate, SessionUpdate, SessionResponse


class SessionService:
    def create_session(
        self,
        db: Session,
        user_id: int,
        session_data: SessionCreate
    ) -> SessionResponse:
        session_dict = session_data.dict()
        session_dict['user_id'] = user_id
        
        from pydantic import BaseModel
        
        class SessionCreateWithUser(BaseModel):
            user_id: int
            exercise_type: str
            start_time: object
            device_type: Optional[str] = None
            app_version: Optional[str] = None
        
        session_with_user = SessionCreateWithUser(**session_dict)
        session = session_repo.create(db, obj_in=session_with_user)
        return SessionResponse.from_orm(session)
    
    def update_session(
        self,
        db: Session,
        user_id: int,
        session_id: int,
        session_data: SessionUpdate
    ) -> SessionResponse:
        session = session_repo.get_user_session_by_id(
            db,
            session_id=session_id,
            user_id=user_id
        )
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )
        
        updated_session = session_repo.update(
            db,
            db_obj=session,
            obj_in=session_data
        )
        
        return SessionResponse.from_orm(updated_session)
    
    def get_user_sessions(
        self,
        db: Session,
        user_id: int,
        skip: int = 0,
        limit: int = 20,
        exercise_type: Optional[str] = None
    ) -> List[SessionResponse]:
        sessions = session_repo.get_by_user(
            db,
            user_id=user_id,
            skip=skip,
            limit=limit,
            exercise_type=exercise_type
        )
        
        return [SessionResponse.from_orm(s) for s in sessions]
    
    def get_session(
        self,
        db: Session,
        user_id: int,
        session_id: int
    ) -> SessionResponse:
        session = session_repo.get_user_session_by_id(
            db,
            session_id=session_id,
            user_id=user_id
        )
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )
        
        return SessionResponse.from_orm(session)
    
    def delete_session(
        self,
        db: Session,
        user_id: int,
        session_id: int
    ) -> None:
        session = session_repo.get_user_session_by_id(
            db,
            session_id=session_id,
            user_id=user_id
        )
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )
        
        session_repo.delete(db, id=session_id)
    
    def get_user_stats(
        self,
        db: Session,
        user_id: int,
        days: int = 7,
        exercise_type: Optional[str] = None
    ) -> dict:
        return session_repo.get_stats(
            db,
            user_id=user_id,
            days=days,
            exercise_type=exercise_type
        )


session_service = SessionService()