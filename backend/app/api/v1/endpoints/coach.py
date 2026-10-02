from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Any
from pydantic import BaseModel

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.ai_coach_service import AICoachService

router = APIRouter()

class VoiceCommandRequest(BaseModel):
    planned_exercise_id: int
    transcript: str

@router.post("/voice-command", response_model=dict)
def process_voice_command(
    request: VoiceCommandRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Process a voice command from the user during a workout.
    """
    coach_service = AICoachService(db)
    
    try:
        response = coach_service.process_voice_command(
            user_id=current_user.id,
            planned_exercise_id=request.planned_exercise_id,
            transcript=request.transcript
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
