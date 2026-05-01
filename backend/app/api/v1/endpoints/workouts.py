"""
Workout Catalogue endpoints
Static exercise reference data — muscle groups, tips, demo media
"""

from fastapi import APIRouter, HTTPException, status, Depends
from typing import List, Optional
from pydantic import BaseModel

from app.api.deps import get_current_active_user
from app.models.user import User

router = APIRouter()

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class MuscleGroup(BaseModel):
    name: str
    role: str  # "primary" | "secondary"


class ExerciseDetail(BaseModel):
    id: str
    name: str
    category: str           # "strength" | "cardio" | "flexibility" | "balance"
    difficulty: str         # "beginner" | "intermediate" | "advanced"
    equipment: List[str]
    muscle_groups: List[MuscleGroup]
    instructions: List[str]
    tips: List[str]
    common_mistakes: List[str]
    calories_per_rep: float
    duration_type: str      # "reps" | "time"


# ---------------------------------------------------------------------------
# Static exercise catalogue
# ---------------------------------------------------------------------------

EXERCISES: List[ExerciseDetail] = [
    ExerciseDetail(
        id="pushup",
        name="Push-up",
        category="strength",
        difficulty="beginner",
        equipment=["none"],
        muscle_groups=[
            MuscleGroup(name="Chest", role="primary"),
            MuscleGroup(name="Triceps", role="primary"),
            MuscleGroup(name="Shoulders", role="secondary"),
            MuscleGroup(name="Core", role="secondary"),
        ],
        instructions=[
            "Start in a high plank position with hands shoulder-width apart.",
            "Keep your body in a straight line from head to heels.",
            "Lower your chest to just above the floor by bending your elbows.",
            "Push back up to the starting position.",
            "Repeat for desired reps.",
        ],
        tips=[
            "Keep your core tight throughout the movement.",
            "Don't let your hips sag or rise.",
            "Breathe in as you lower, out as you push up.",
        ],
        common_mistakes=[
            "Flaring elbows too wide (should be ~45° from body).",
            "Not achieving full range of motion.",
            "Holding breath during the movement.",
        ],
        calories_per_rep=0.5,
        duration_type="reps",
    ),
    ExerciseDetail(
        id="squat",
        name="Squat",
        category="strength",
        difficulty="beginner",
        equipment=["none"],
        muscle_groups=[
            MuscleGroup(name="Quadriceps", role="primary"),
            MuscleGroup(name="Glutes", role="primary"),
            MuscleGroup(name="Hamstrings", role="secondary"),
            MuscleGroup(name="Core", role="secondary"),
        ],
        instructions=[
            "Stand with feet shoulder-width apart, toes slightly turned out.",
            "Engage your core and keep your chest up.",
            "Push your hips back and bend your knees to lower down.",
            "Lower until your thighs are parallel to the floor (or lower).",
            "Drive through your heels to return to standing.",
        ],
        tips=[
            "Keep your knees tracking over your toes.",
            "Keep your weight on your heels and mid-foot.",
            "Keep your spine neutral — don't round your lower back.",
        ],
        common_mistakes=[
            "Knees caving inward.",
            "Heels lifting off the floor.",
            "Rounding the lower back at the bottom.",
        ],
        calories_per_rep=0.32,
        duration_type="reps",
    ),
    ExerciseDetail(
        id="plank",
        name="Plank",
        category="strength",
        difficulty="beginner",
        equipment=["none"],
        muscle_groups=[
            MuscleGroup(name="Core", role="primary"),
            MuscleGroup(name="Shoulders", role="secondary"),
            MuscleGroup(name="Glutes", role="secondary"),
        ],
        instructions=[
            "Start in a forearm plank with elbows directly under shoulders.",
            "Keep your body in a straight line from head to heels.",
            "Engage your core and squeeze your glutes.",
            "Hold the position for the target duration.",
        ],
        tips=[
            "Focus on breathing steadily throughout.",
            "Keep your gaze toward the floor to maintain a neutral neck.",
        ],
        common_mistakes=[
            "Letting hips sag toward the floor.",
            "Raising hips too high (into a pike position).",
            "Holding breath.",
        ],
        calories_per_rep=0.25,
        duration_type="time",
    ),
    ExerciseDetail(
        id="lunge",
        name="Lunge",
        category="strength",
        difficulty="intermediate",
        equipment=["none"],
        muscle_groups=[
            MuscleGroup(name="Quadriceps", role="primary"),
            MuscleGroup(name="Glutes", role="primary"),
            MuscleGroup(name="Hamstrings", role="secondary"),
            MuscleGroup(name="Calves", role="secondary"),
        ],
        instructions=[
            "Stand tall with feet hip-width apart.",
            "Step forward with one foot, lowering your hips until both knees are at ~90°.",
            "Keep your front knee directly above your ankle.",
            "Push through your front heel to return to standing.",
            "Alternate legs for each rep.",
        ],
        tips=[
            "Keep your torso upright — don't lean forward.",
            "Take a big enough step so your back knee nearly touches the floor.",
        ],
        common_mistakes=[
            "Front knee extending past the toes.",
            "Letting the back knee slam the floor.",
            "Leaning heavily forward.",
        ],
        calories_per_rep=0.35,
        duration_type="reps",
    ),
    ExerciseDetail(
        id="bicep_curl",
        name="Bicep Curl",
        category="strength",
        difficulty="beginner",
        equipment=["dumbbells"],
        muscle_groups=[
            MuscleGroup(name="Biceps", role="primary"),
            MuscleGroup(name="Forearms", role="secondary"),
        ],
        instructions=[
            "Stand holding dumbbells at your sides with palms facing forward.",
            "Keeping your upper arms still, curl the weights toward your shoulders.",
            "Squeeze your biceps at the top of the movement.",
            "Slowly lower back to the starting position.",
        ],
        tips=[
            "Avoid swinging your body to lift the weight.",
            "Control the descent — the eccentric phase is just as important.",
        ],
        common_mistakes=[
            "Using momentum / swinging the torso.",
            "Letting elbows drift forward at the top.",
            "Rushing the lowering phase.",
        ],
        calories_per_rep=0.2,
        duration_type="reps",
    ),
    ExerciseDetail(
        id="shoulder_press",
        name="Shoulder Press",
        category="strength",
        difficulty="intermediate",
        equipment=["dumbbells"],
        muscle_groups=[
            MuscleGroup(name="Deltoids", role="primary"),
            MuscleGroup(name="Triceps", role="secondary"),
            MuscleGroup(name="Upper Trapezius", role="secondary"),
        ],
        instructions=[
            "Sit or stand holding dumbbells at shoulder height, palms facing forward.",
            "Press the weights directly overhead until arms are fully extended.",
            "Lower back to shoulder height in a controlled manner.",
        ],
        tips=[
            "Keep your core braced to protect your lower back.",
            "Don't lock out your elbows with a hard snap at the top.",
        ],
        common_mistakes=[
            "Arching the lower back excessively.",
            "Pressing the weights forward instead of directly overhead.",
        ],
        calories_per_rep=0.4,
        duration_type="reps",
    ),
]

# Index for fast lookup
_EXERCISE_INDEX = {e.id: e for e in EXERCISES}


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get(
    "/exercises",
    response_model=List[ExerciseDetail],
    summary="Get all supported exercises with detailed instructions",
)
async def list_exercises(
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    current_user: User = Depends(get_current_active_user),
) -> List[ExerciseDetail]:
    """
    Returns the full exercise catalogue.
    Optionally filter by `category` (strength/cardio) or `difficulty`
    (beginner/intermediate/advanced).
    """
    results = list(EXERCISES)
    if category:
        results = [e for e in results if e.category == category.lower()]
    if difficulty:
        results = [e for e in results if e.difficulty == difficulty.lower()]
    return results


@router.get(
    "/exercises/{exercise_id}",
    response_model=ExerciseDetail,
    summary="Get detailed info for a specific exercise",
)
async def get_exercise(
    exercise_id: str,
    current_user: User = Depends(get_current_active_user),
) -> ExerciseDetail:
    """Return full detail for a single exercise by its ID."""
    exercise = _EXERCISE_INDEX.get(exercise_id.lower())
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Exercise '{exercise_id}' not found. "
                   f"Valid IDs: {sorted(_EXERCISE_INDEX.keys())}",
        )
    return exercise
