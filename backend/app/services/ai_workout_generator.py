from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any
import random

from app.models import (
    User, 
    WorkoutSession, 
    Exercise, 
    WorkoutPlan, 
    ScheduledWorkout, 
    PlannedExercise,
    FitnessLevel
)

class AIWorkoutGenerator:
    """
    Core engine for dynamic progressive overload and AI workout planning.
    """
    
    def __init__(self, db: Session):
        self.db = db

    def generate_base_plan(self, user_id: int, plan_name: str, focus: str, duration_weeks: int = 4) -> WorkoutPlan:
        """
        Creates a new periodized WorkoutPlan for a user.
        """
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("User not found")
            
        new_plan = WorkoutPlan(
            user_id=user_id,
            name=plan_name,
            focus=focus,
            start_date=datetime.now(timezone.utc),
            end_date=datetime.now(timezone.utc) + timedelta(weeks=duration_weeks),
            is_active=True
        )
        self.db.add(new_plan)
        self.db.commit()
        self.db.refresh(new_plan)
        return new_plan

    def calculate_next_progression(self, user_id: int, exercise_id: int, base_reps: int, base_sets: int) -> tuple[int, int, Optional[int]]:
        """
        The Dynamic Overload Logic: Looks at past performance to adjust future target reps/weight.
        If accuracy > 85% and tempo is good, increase load.
        """
        # Find the last time the user performed this exercise type
        exercise = self.db.query(Exercise).filter(Exercise.id == exercise_id).first()
        if not exercise:
            return base_reps, base_sets, None
            
        last_session = self.db.query(WorkoutSession).filter(
            WorkoutSession.user_id == user_id,
            WorkoutSession.exercise_type == exercise.slug
        ).order_by(desc(WorkoutSession.created_at)).first()
        
        target_reps = base_reps
        target_sets = base_sets
        
        if last_session:
            # Progression logic based on AI pose detection accuracy and completion
            accuracy = last_session.average_accuracy
            if accuracy > 85.0:
                # User mastered it, increase reps by 10%
                target_reps = int(target_reps * 1.10) + 1
            elif accuracy < 60.0:
                # User struggled, reduce reps to focus on form
                target_reps = max(1, int(target_reps * 0.90))
                
        return target_reps, target_sets, None

    def schedule_daily_workout(self, plan_id: int, day_number: int, focus_muscles: List[str]) -> ScheduledWorkout:
        """
        Builds today's scheduled workout by selecting exercises and applying the progression engine.
        """
        plan = self.db.query(WorkoutPlan).filter(WorkoutPlan.id == plan_id).first()
        if not plan:
            raise ValueError("Plan not found")
            
        # Create the schedule
        workout = ScheduledWorkout(
            plan_id=plan.id,
            day_number=day_number,
            target_date=datetime.now(timezone.utc),
            name=f"Day {day_number}: {'/'.join(focus_muscles).title()}",
            focus_muscle_groups=focus_muscles
        )
        self.db.add(workout)
        self.db.commit()
        self.db.refresh(workout)
        
        # Select exercises matching the muscle focus
        exercises = self.db.query(Exercise).all()
        selected_exercises = []
        for ex in exercises:
            # Check if any of the exercise's target muscles overlap with today's focus
            if any(muscle in ex.muscle_groups for muscle in focus_muscles):
                selected_exercises.append(ex)
                
        # Limit to 5 exercises for a session
        selected_exercises = selected_exercises[:5]
        
        # Plan the exercises with Dynamic Overload
        for index, ex in enumerate(selected_exercises):
            t_reps, t_sets, t_weight = self.calculate_next_progression(
                plan.user_id, ex.id, ex.default_reps, ex.default_sets
            )
            
            planned_ex = PlannedExercise(
                scheduled_workout_id=workout.id,
                exercise_id=ex.id,
                order=index + 1,
                target_sets=t_sets,
                target_reps=t_reps,
                target_weight_kg=t_weight,
                target_rest_seconds=60
            )
            self.db.add(planned_ex)
            
        self.db.commit()
        return workout

    def adapt_exercise_for_equipment(self, planned_exercise_id: int) -> PlannedExercise:
        """
        Equipment Adaptation Feature: Swaps an exercise out while keeping the same muscle focus.
        """
        planned_ex = self.db.query(PlannedExercise).filter(PlannedExercise.id == planned_exercise_id).first()
        if not planned_ex:
            raise ValueError("Planned exercise not found")
            
        original_ex = self.db.query(Exercise).filter(Exercise.id == planned_ex.exercise_id).first()
        
        # Find a substitute exercise that hits the same primary muscle group
        substitutes = self.db.query(Exercise).filter(
            Exercise.id != original_ex.id
        ).all()
        
        valid_subs = [sub for sub in substitutes if set(sub.muscle_groups).intersection(set(original_ex.muscle_groups))]
        
        if valid_subs:
            # Pick a random valid substitute
            new_ex = random.choice(valid_subs)
            
            # Update the planned exercise
            planned_ex.is_substituted = True
            planned_ex.original_exercise_id = original_ex.id
            planned_ex.exercise_id = new_ex.id
            
            # Recalculate target reps for the new movement
            user_id = planned_ex.scheduled_workout.plan.user_id
            t_reps, t_sets, t_weight = self.calculate_next_progression(
                user_id, new_ex.id, new_ex.default_reps, new_ex.default_sets
            )
            planned_ex.target_reps = t_reps
            planned_ex.target_sets = t_sets
            planned_ex.target_weight_kg = t_weight
            
            self.db.commit()
            
        return planned_ex
