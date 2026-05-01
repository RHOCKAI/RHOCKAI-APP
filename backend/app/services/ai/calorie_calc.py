# app/services/ai/calorie_calc.py

class CalorieCalculator:
    """Calculate calories burned during workout"""
    
    # MET (Metabolic Equivalent) values for exercises
    MET_VALUES = {
        'pushup': 8.0,
        'squat': 5.0,
        'plank': 3.5,
        'pullup': 8.0,
        'burpee': 10.0,
    }
    
    @staticmethod
    def calculate_calories(
        exercise_type: str,
        duration_minutes: float,
        weight_kg: float,
        gender: str = 'male'
    ) -> int:
        """
        Calculate calories burned
        Formula: Calories = MET × weight(kg) × duration(hours)
        Adjust for gender (females typically burn 10% less)
        """
        met = CalorieCalculator.MET_VALUES.get(exercise_type, 6.0)
        duration_hours = duration_minutes / 60
        
        calories = met * weight_kg * duration_hours
        
        # Gender adjustment
        if gender == 'female':
            calories *= 0.9
        
        return round(calories)
    
    @staticmethod
    def calculate_from_reps(
        exercise_type: str,
        reps: int,
        weight_kg: float,
        gender: str = 'male'
    ) -> int:
        """Estimate calories from rep count"""
        # Rough estimate: 0.05 calories per rep for most exercises
        calories_per_rep = 0.05 * (weight_kg / 70)  # Normalized to 70kg
        
        calories = reps * calories_per_rep
        
        if gender == 'female':
            calories *= 0.9
        
        return round(calories)