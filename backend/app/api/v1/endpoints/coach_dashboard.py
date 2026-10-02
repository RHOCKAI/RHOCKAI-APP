from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Any, List, Dict

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.coach_dashboard_service import CoachDashboardService

router = APIRouter()

@router.get("/flagged-clients", response_model=List[Dict[str, Any]])
def get_flagged_clients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Retrieve a list of clients assigned to this coach who require human intervention.
    Requires admin or coach privileges.
    """
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough privileges to access the coach dashboard.")
        
    dashboard_service = CoachDashboardService(db)
    
    try:
        flagged_clients = dashboard_service.get_flagged_clients(coach_id=current_user.id)
        return flagged_clients
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
