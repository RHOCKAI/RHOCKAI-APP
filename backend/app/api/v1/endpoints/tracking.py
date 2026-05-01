"""
Tracking API endpoints
"""

from fastapi import APIRouter, Depends, BackgroundTasks, status
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.analytics import (
    AppSession, ScreenView, FeatureUsage, 
    UserDemographic, SubscriptionEvent, ErrorLog, RetentionCohort
)
from app.schemas.analytics import (
    TrackSessionRequest, EndSessionRequest, TrackScreenRequest,
    TrackFeatureRequest, UpdateDemographicRequest, TrackErrorRequest,
    TrackCancellationRequest
)

router = APIRouter()

async def update_retention_cohort(user_id: int, db: Session):
    """Run in background when user opens app"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return
    
    cohort_month = user.created_at.strftime("%Y-%m")
    
    cohort = db.query(RetentionCohort).filter(
        RetentionCohort.user_id == user_id
    ).first()
    
    if not cohort:
        cohort = RetentionCohort(
            user_id=user_id,
            cohort_month=cohort_month,
        )
        db.add(cohort)
    
    # Calculate weeks since joining
    weeks_since_joining = (datetime.utcnow().replace(tzinfo=user.created_at.tzinfo) - user.created_at).days // 7
    
    if weeks_since_joining >= 1:  cohort.week_1_active = True
    if weeks_since_joining >= 2:  cohort.week_2_active = True
    if weeks_since_joining >= 4:  cohort.week_4_active = True
    if weeks_since_joining >= 8:  cohort.week_8_active = True
    if weeks_since_joining >= 12: cohort.week_12_active = True
    
    db.commit()


@router.post("/session/start", status_code=status.HTTP_201_CREATED)
async def start_session(
    request: TrackSessionRequest,
    background_tasks: BackgroundTasks,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Track app session start"""
    session = AppSession(
        id=request.session_id,
        user_id=current_user.id if current_user else None,
        device_type=request.device_type,
        device_model=request.device_model,
        os_name=request.os_name,
        os_version=request.os_version,
        app_version=request.app_version,
        country=request.country,
        city=request.city,
        timezone=request.timezone,
        connection_type=request.connection_type,
    )
    db.add(session)
    db.commit()
    
    if current_user:
        background_tasks.add_task(update_retention_cohort, current_user.id, db)
    
    return {"status": "ok", "session_id": request.session_id}


@router.post("/session/end")
async def end_session(
    request: EndSessionRequest,
    db: Session = Depends(get_db),
):
    """Track app session end"""
    session = db.query(AppSession).filter(AppSession.id == request.session_id).first()
    
    if session:
        session.session_end = datetime.utcnow()
        session.duration_seconds = request.duration_seconds
        db.commit()
    
    return {"status": "ok"}


@router.post("/screen")
async def track_screen(
    request: TrackScreenRequest,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Track screen view"""
    view = ScreenView(
        user_id=current_user.id if current_user else None,
        session_id=request.session_id,
        screen_name=request.screen_name,
        previous_screen=request.previous_screen,
        time_on_screen=request.time_on_screen,
        extra_data=request.extra_data,
    )
    db.add(view)
    db.commit()
    return {"status": "ok"}


@router.post("/feature")
async def track_feature(
    request: TrackFeatureRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Track feature usage"""
    usage = FeatureUsage(
        user_id=current_user.id,
        feature_name=request.feature_name,
        action=request.action,
        extra_data=request.extra_data,
    )
    db.add(usage)
    db.commit()
    return {"status": "ok"}


@router.post("/demographic")
async def update_demographic(
    request: UpdateDemographicRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update user demographics"""
    demo = db.query(UserDemographic).filter(UserDemographic.user_id == current_user.id).first()
    
    if not demo:
        demo = UserDemographic(user_id=current_user.id)
        db.add(demo)
    
    if request.age_range: demo.age_range = request.age_range
    if request.gender: demo.gender = request.gender
    if request.fitness_level: demo.fitness_level = request.fitness_level
    if request.fitness_goal: demo.fitness_goal = request.fitness_goal
    if request.how_found_app: demo.how_found_app = request.how_found_app
    
    db.commit()
    return {"status": "ok"}


@router.post("/error")
async def track_error(
    request: TrackErrorRequest,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Track app error"""
    error = ErrorLog(
        user_id=current_user.id if current_user else None,
        error_type=request.error_type,
        error_message=request.error_message,
        stack_trace=request.stack_trace,
        screen=request.screen,
        app_version=request.app_version,
        os_name=request.os_name,
        os_version=request.os_version,
        device_model=request.device_model,
    )
    db.add(error)
    db.commit()
    return {"status": "ok"}


@router.post("/cancellation")
async def track_cancellation(
    request: TrackCancellationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Track subscription cancellation"""
    event = SubscriptionEvent(
        user_id=current_user.id,
        event_type="cancelled",
        cancellation_reason=request.reason,
        external_subscription_id=request.subscription_id,
    )
    db.add(event)
    db.commit()
    return {"status": "ok"}
