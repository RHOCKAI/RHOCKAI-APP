from sqlalchemy.orm import Session
from typing import Dict, Any, Optional
import re

from app.models.workout_plan import PlannedExercise, ScheduledWorkout
from app.services.ai_workout_generator import AIWorkoutGenerator

class AICoachService:
    """
    Handles natural language voice commands during a workout session.
    Parses user intent and modifies the workout parameters in real-time.
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.workout_generator = AIWorkoutGenerator(db)

    def process_voice_command(self, user_id: int, planned_exercise_id: int, transcript: str) -> Dict[str, Any]:
        """
        Takes a raw transcript (e.g., "This weight is too heavy") and returns an actionable response.
        In a full production environment, this would hit an LLM API (like Gemini).
        For now, we use a heuristic intent matcher.
        """
        transcript = transcript.lower().strip()
        
        # 1. Intent: Reduce Difficulty / Weight
        if any(phrase in transcript for phrase in ["too heavy", "can't do", "too hard", "reduce weight", "lighter"]):
            return self._handle_reduce_difficulty(planned_exercise_id)
            
        # 2. Intent: Pain / Injury / Swap Exercise
        elif any(phrase in transcript for phrase in ["hurts", "pain", "swap", "different exercise", "adapt"]):
            return self._handle_swap_exercise(planned_exercise_id)
            
        # 3. Intent: Increase Difficulty
        elif any(phrase in transcript for phrase in ["too easy", "too light", "more weight", "heavier"]):
            return self._handle_increase_difficulty(planned_exercise_id)
            
        # 4. Fallback Intent: Motivation / General Query
        else:
            return {
                "action": "motivate",
                "message": "You're doing great! Keep your core tight and focus on the movement. You've got this!",
                "data": None
            }

    def _handle_reduce_difficulty(self, planned_exercise_id: int) -> Dict[str, Any]:
        ex = self.db.query(PlannedExercise).filter(PlannedExercise.id == planned_exercise_id).first()
        if not ex:
            return {"action": "error", "message": "Exercise not found."}
            
        if ex.target_weight_kg and ex.target_weight_kg > 5:
            # Reduce weight by ~10%
            new_weight = max(1, int(ex.target_weight_kg * 0.9))
            ex.target_weight_kg = new_weight
            self.db.commit()
            return {
                "action": "update_weight",
                "message": f"I hear you. Let's drop the weight down to {new_weight} kg. Focus on your form.",
                "data": {"new_weight": new_weight}
            }
        else:
            # Bodyweight exercise, reduce reps
            new_reps = max(1, int(ex.target_reps * 0.8))
            ex.target_reps = new_reps
            self.db.commit()
            return {
                "action": "update_reps",
                "message": f"No problem. Let's reduce the target to {new_reps} reps. Quality over quantity.",
                "data": {"new_reps": new_reps}
            }

    def _handle_swap_exercise(self, planned_exercise_id: int) -> Dict[str, Any]:
        try:
            new_ex = self.workout_generator.adapt_exercise_for_equipment(planned_exercise_id)
            return {
                "action": "swap_exercise",
                "message": f"Got it. Let's switch to {new_ex.exercise.name} to target the same muscles without the discomfort.",
                "data": {
                    "exercise_id": new_ex.exercise.id,
                    "exercise_name": new_ex.exercise.name,
                    "target_reps": new_ex.target_reps
                }
            }
        except Exception as e:
            return {
                "action": "motivate",
                "message": "I couldn't find a good substitute right now. Let's just rest for a minute and skip this one.",
                "data": None
            }

    def _handle_increase_difficulty(self, planned_exercise_id: int) -> Dict[str, Any]:
        ex = self.db.query(PlannedExercise).filter(PlannedExercise.id == planned_exercise_id).first()
        if not ex:
            return {"action": "error", "message": "Exercise not found."}
            
        if ex.target_weight_kg:
            # Increase weight
            new_weight = int(ex.target_weight_kg * 1.1) + 1
            ex.target_weight_kg = new_weight
            self.db.commit()
            return {
                "action": "update_weight",
                "message": f"Love the energy! Let's bump that up to {new_weight} kg. Let's work!",
                "data": {"new_weight": new_weight}
            }
        else:
            # Increase reps
            new_reps = int(ex.target_reps * 1.2)
            ex.target_reps = new_reps
            self.db.commit()
            return {
                "action": "update_reps",
                "message": f"Too easy? Alright, let's push it to {new_reps} reps. Show me what you've got!",
                "data": {"new_reps": new_reps}
            }
