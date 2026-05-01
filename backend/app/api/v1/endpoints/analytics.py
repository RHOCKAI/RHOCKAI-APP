"""
Analytics API endpoints - stats and progress tracking
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from typing import List
from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User
from app.models.workout_session import WorkoutSession
from app.schemas.session import SessionStats, ProgressData

router = APIRouter()


@router.get("/stats", response_model=SessionStats)
async def get_user_stats(
    days: int = Query(7, ge=1, le=365),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Get aggregate workout statistics for a time period
    
    - **days**: Number of days to look back (default: 7)
    
    Returns:
    - Total sessions
    - Total reps
    - Total calories burned
    - Average accuracy
    - Total workout duration
    """
    since_date = datetime.utcnow() - timedelta(days=days)
    
    # Total sessions
    total_sessions = db.query(func.count(WorkoutSession.id)).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.created_at >= since_date,
    ).scalar() or 0
    
    # Total reps
    total_reps = db.query(func.sum(WorkoutSession.total_reps)).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.created_at >= since_date,
    ).scalar() or 0
    
    # Total calories
    total_calories = db.query(func.sum(WorkoutSession.calories_burned)).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.created_at >= since_date,
    ).scalar() or 0
    
    # Average accuracy
    avg_accuracy = db.query(func.avg(WorkoutSession.average_accuracy)).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.created_at >= since_date,
    ).scalar() or 0.0
    
    # Total duration
    total_duration = db.query(func.sum(WorkoutSession.duration_seconds)).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.created_at >= since_date,
    ).scalar() or 0
    
    return SessionStats(
        total_sessions=total_sessions,
        total_reps=int(total_reps),
        total_calories=int(total_calories),
        average_accuracy=round(float(avg_accuracy), 2),
        total_duration_minutes=int(total_duration / 60),
    )


@router.get("/progress", response_model=List[ProgressData])
async def get_progress_chart(
    days: int = Query(30, ge=7, le=365),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Get daily progress data for charts
    
    - **days**: Number of days to look back (default: 30)
    
    Returns array of daily data with:
    - Date
    - Number of sessions
    - Total reps
    - Total calories
    - Average accuracy
    """
    since_date = datetime.utcnow() - timedelta(days=days)
    
    # Get all sessions in the time period
    sessions = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.created_at >= since_date,
    ).order_by(WorkoutSession.created_at).all()
    
    # Group sessions by date
    daily_data = {}
    for session in sessions:
        date_key = session.created_at.date().isoformat()
        
        if date_key not in daily_data:
            daily_data[date_key] = {
                "date": date_key,
                "sessions": 0,
                "reps": 0,
                "calories": 0,
                "accuracies": [],
            }
        
        daily_data[date_key]["sessions"] += 1
        daily_data[date_key]["reps"] += session.total_reps
        daily_data[date_key]["calories"] += session.calories_burned
        daily_data[date_key]["accuracies"].append(session.average_accuracy)
    
    # Calculate averages and format response
    progress = []
    for date, data in sorted(daily_data.items()):
        avg_accuracy = sum(data["accuracies"]) / len(data["accuracies"]) if data["accuracies"] else 0
        
        progress.append(ProgressData(
            date=date,
            sessions=data["sessions"],
            reps=data["reps"],
            calories=data["calories"],
            accuracy=round(avg_accuracy, 2),
        ))
    
    return progress


@router.get("/leaderboard")
async def get_leaderboard(
    exercise_type: str = Query(None),
    period: str = Query("week", pattern="^(week|month|all)$"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    """
    Get leaderboard (top performers)
    
    - **exercise_type**: Filter by exercise (optional)
    - **period**: Time period (week, month, all)
    - **limit**: Number of users to return
    
    Public endpoint - does not require authentication
    """
    # Calculate date filter
    if period == "week":
        since_date = datetime.utcnow() - timedelta(days=7)
    elif period == "month":
        since_date = datetime.utcnow() - timedelta(days=30)
    else:
        since_date = datetime.min
    
    # Build query
    query = db.query(
        User.id,
        User.full_name,
        func.count(WorkoutSession.id).label("total_sessions"),
        func.sum(WorkoutSession.total_reps).label("total_reps"),
        func.avg(WorkoutSession.average_accuracy).label("avg_accuracy"),
    ).join(
        WorkoutSession,
        WorkoutSession.user_id == User.id,
    ).filter(
        WorkoutSession.created_at >= since_date,
    )
    
    # Filter by exercise type if provided
    if exercise_type:
        query = query.filter(WorkoutSession.exercise_type == exercise_type)
    
    # Group by user and order by total reps
    leaderboard = query.group_by(User.id).order_by(
        func.sum(WorkoutSession.total_reps).desc()
    ).limit(limit).all()
    
    # Format response
    return [
        {
            "rank": idx + 1,
            "user_name": entry.full_name or "Anonymous",
            "total_sessions": entry.total_sessions,
            "total_reps": int(entry.total_reps or 0),
            "average_accuracy": round(float(entry.avg_accuracy or 0), 2),
        }
        for idx, entry in enumerate(leaderboard)
    ]