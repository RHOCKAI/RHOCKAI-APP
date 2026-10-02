from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any

from app.models.user import User
from app.models.workout_session import WorkoutSession
from app.models.workout_plan import ScheduledWorkout
from app.models.wearable import DailyHealthMetric

class CoachDashboardService:
    """
    Aggregation service for the Human-in-the-Loop Coaching Portal.
    Flags users who need human intervention based on AI anomalies.
    """
    
    def __init__(self, db: Session):
        self.db = db

    def get_flagged_clients(self, coach_id: int) -> List[Dict[str, Any]]:
        """
        Retrieves all users assigned to a specific coach and flags them if:
        1. Average accuracy < 70% (Form issues)
        2. Daily Readiness < 50 (Overtraining risk)
        3. Missed recent scheduled workouts (Accountability)
        """
        # Note: In a full implementation, we would have a CoachClient table linking users to coaches.
        # For this logic, we assume all regular users are retrieved or filtered appropriately.
        # We will fetch the latest 50 users for demonstration.
        clients = self.db.query(User).filter(User.is_admin == False).limit(50).all()
        
        flagged_clients = []
        today = datetime.now(timezone.utc).date()
        
        for client in clients:
            flags = []
            
            # 1. Check for Form/Accuracy Issues
            recent_sessions = self.db.query(WorkoutSession).filter(
                WorkoutSession.user_id == client.id
            ).order_by(desc(WorkoutSession.created_at)).limit(3).all()
            
            if recent_sessions:
                avg_accuracy = sum(s.average_accuracy for s in recent_sessions) / len(recent_sessions)
                if avg_accuracy < 70.0:
                    flags.append({
                        "type": "poor_form",
                        "severity": "high",
                        "message": f"Average posture accuracy dropped to {avg_accuracy:.1f}% over last 3 sessions."
                    })
            
            # 2. Check for Recovery / Overtraining Risk
            latest_health = self.db.query(DailyHealthMetric).filter(
                DailyHealthMetric.user_id == client.id,
                func.date(DailyHealthMetric.date) == today
            ).first()
            
            if latest_health and latest_health.readiness_score < 50:
                flags.append({
                    "type": "low_recovery",
                    "severity": "medium",
                    "message": f"Daily readiness is critically low ({latest_health.readiness_score}%). At risk of injury."
                })
                
            # 3. Check for Accountability (Missed Workouts)
            three_days_ago = datetime.now(timezone.utc) - timedelta(days=3)
            missed_workouts = self.db.query(ScheduledWorkout).join(ScheduledWorkout.plan).filter(
                ScheduledWorkout.plan.has(user_id=client.id),
                ScheduledWorkout.is_completed == False,
                ScheduledWorkout.target_date >= three_days_ago,
                ScheduledWorkout.target_date < datetime.now(timezone.utc)
            ).count()
            
            if missed_workouts >= 2:
                flags.append({
                    "type": "missed_workouts",
                    "severity": "high",
                    "message": f"User has missed {missed_workouts} scheduled workouts in the last 3 days."
                })
                
            # If the user has any flags, add them to the dashboard alert list
            if flags:
                flagged_clients.append({
                    "user_id": client.id,
                    "name": client.full_name or client.email,
                    "profile_picture": client.profile_picture,
                    "flags": flags,
                    "total_severity": "high" if any(f['severity'] == 'high' for f in flags) else "medium"
                })
                
        # Sort flagged clients: High severity first
        flagged_clients.sort(key=lambda x: 0 if x["total_severity"] == "high" else 1)
        
        return flagged_clients
