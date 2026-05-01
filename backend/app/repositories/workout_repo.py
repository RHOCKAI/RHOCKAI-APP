"""
Workout repository for analytics
"""

from typing import List, Dict, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, desc

from app.models.workout_session import WorkoutSession
from app.models.user import User


class WorkoutRepository:
    def get_leaderboard(
        self,
        db: Session,
        *,
        exercise_type: Optional[str] = None,
        period: str = "week",
        limit: int = 10
    ) -> List[Dict]:
        if period == "week":
            since_date = datetime.utcnow() - timedelta(days=7)
        elif period == "month":
            since_date = datetime.utcnow() - timedelta(days=30)
        else:
            since_date = datetime.min
        
        query = db.query(
            User.id,
            User.full_name,
            func.count(WorkoutSession.id).label('total_sessions'),
            func.sum(WorkoutSession.total_reps).label('total_reps'),
            func.avg(WorkoutSession.average_accuracy).label('avg_accuracy'),
        ).join(
            WorkoutSession,
            WorkoutSession.user_id == User.id
        ).filter(
            WorkoutSession.created_at >= since_date
        )
        
        if exercise_type:
            query = query.filter(WorkoutSession.exercise_type == exercise_type)
        
        results = query.group_by(User.id).order_by(desc('total_reps')).limit(limit).all()
        
        leaderboard = []
        for idx, result in enumerate(results, 1):
            leaderboard.append({
                'rank': idx,
                'user_id': result.id,
                'user_name': result.full_name or 'Anonymous',
                'total_sessions': result.total_sessions,
                'total_reps': int(result.total_reps or 0),
                'average_accuracy': round(float(result.avg_accuracy or 0), 2),
            })
        
        return leaderboard
    
    def get_progress_chart(
        self,
        db: Session,
        *,
        user_id: int,
        days: int = 30
    ) -> List[Dict]:
        since_date = datetime.utcnow() - timedelta(days=days)
        
        sessions = db.query(WorkoutSession).filter(
            and_(
                WorkoutSession.user_id == user_id,
                WorkoutSession.created_at >= since_date
            )
        ).order_by(WorkoutSession.created_at).all()
        
        daily_data = {}
        for session in sessions:
            date_key = session.created_at.date().isoformat()
            
            if date_key not in daily_data:
                daily_data[date_key] = {
                    'date': date_key,
                    'sessions': 0,
                    'reps': 0,
                    'calories': 0,
                    'accuracies': [],
                }
            
            daily_data[date_key]['sessions'] += 1
            daily_data[date_key]['reps'] += session.total_reps
            daily_data[date_key]['calories'] += session.calories_burned
            daily_data[date_key]['accuracies'].append(session.average_accuracy)
        
        progress = []
        for date, data in sorted(daily_data.items()):
            avg_accuracy = sum(data['accuracies']) / len(data['accuracies']) if data['accuracies'] else 0
            
            progress.append({
                'date': date,
                'sessions': data['sessions'],
                'reps': data['reps'],
                'calories': data['calories'],
                'accuracy': round(avg_accuracy, 2),
            })
        
        return progress
    
    def get_workout_streak(self, db: Session, *, user_id: int) -> Dict:
        sessions = db.query(WorkoutSession).filter(
            WorkoutSession.user_id == user_id
        ).order_by(WorkoutSession.created_at.desc()).all()
        
        if not sessions:
            return {
                'current_streak': 0,
                'longest_streak': 0,
                'total_workout_days': 0,
                'last_workout_date': None,
            }
        
        workout_dates = list(set(session.created_at.date() for session in sessions))
        workout_dates.sort(reverse=True)
        
        current_streak = 0
        today = datetime.utcnow().date()
        
        for i, date in enumerate(workout_dates):
            expected_date = today - timedelta(days=i)
            if date == expected_date:
                current_streak += 1
            else:
                break
        
        longest_streak = 1
        temp_streak = 1
        
        for i in range(len(workout_dates) - 1):
            if (workout_dates[i] - workout_dates[i + 1]).days == 1:
                temp_streak += 1
                longest_streak = max(longest_streak, temp_streak)
            else:
                temp_streak = 1
        
        return {
            'current_streak': current_streak,
            'longest_streak': longest_streak,
            'total_workout_days': len(workout_dates),
            'last_workout_date': workout_dates[0] if workout_dates else None,
        }
    
    def get_personal_records(self, db: Session, *, user_id: int) -> Dict:
        exercises = ['pushup', 'squat', 'plank']
        records = {}
        
        for exercise in exercises:
            best_session = db.query(WorkoutSession).filter(
                and_(
                    WorkoutSession.user_id == user_id,
                    WorkoutSession.exercise_type == exercise
                )
            ).order_by(desc(WorkoutSession.total_reps)).first()
            
            if best_session:
                records[exercise] = {
                    'max_reps': best_session.total_reps,
                    'best_accuracy': best_session.average_accuracy,
                    'achieved_at': best_session.created_at.isoformat(),
                }
            else:
                records[exercise] = {
                    'max_reps': 0,
                    'best_accuracy': 0.0,
                    'achieved_at': None,
                }
        
        return records


workout_repo = WorkoutRepository()