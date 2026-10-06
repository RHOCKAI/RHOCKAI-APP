"""
AI Analysis endpoints
Pose form analysis and exercise catalogue
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User
from app.services.ai.pose_analyzer import PoseAnalyzer
from app.core.config import settings

router = APIRouter()

# ---------------------------------------------------------------------------
# Schemas (local to this module — no DB persistence needed for AI inference)
# ---------------------------------------------------------------------------

class KeypointData(BaseModel):
    """Single pose keypoint with confidence score"""
    name: str
    x: float
    y: float
    confidence: float = Field(ge=0.0, le=1.0)


class PoseAnalysisRequest(BaseModel):
    """Incoming pose data from the Flutter camera AI module"""
    exercise_type: str = Field(..., example="pushup")
    keypoints: List[KeypointData]
    rep_number: Optional[int] = Field(None, ge=1)


class FormFeedback(BaseModel):
    """Structured form feedback response"""
    exercise_type: str
    is_valid_pose: bool
    accuracy_score: float = Field(ge=0.0, le=100.0)
    issues: List[str]
    suggestions: List[str]
    rep_counted: bool


class ExerciseInfo(BaseModel):
    """Exercise catalogue entry"""
    id: str
    name: str
    muscle_groups: List[str]
    difficulty: str
    calories_per_rep: float
    description: str


# ---------------------------------------------------------------------------
# Exercise catalogue (static data — could be DB-driven in future)
# ---------------------------------------------------------------------------

EXERCISE_CATALOGUE = [
    ExerciseInfo(
        id="pushup",
        name="Push-up",
        muscle_groups=["chest", "triceps", "shoulders", "core"],
        difficulty="beginner",
        calories_per_rep=settings.CALORIES_PER_REP.get("pushup", 0.5),
        description="A classic upper body compound movement targeting the chest and triceps.",
    ),
    ExerciseInfo(
        id="squat",
        name="Squat",
        muscle_groups=["quadriceps", "glutes", "hamstrings", "core"],
        difficulty="beginner",
        calories_per_rep=settings.CALORIES_PER_REP.get("squat", 0.32),
        description="A fundamental lower body exercise for building leg and glute strength.",
    ),
    ExerciseInfo(
        id="plank",
        name="Plank",
        muscle_groups=["core", "shoulders", "glutes"],
        difficulty="beginner",
        calories_per_rep=settings.CALORIES_PER_REP.get("plank", 0.25),
        description="An isometric core exercise that builds stability and endurance.",
    ),
    ExerciseInfo(
        id="lunge",
        name="Lunge",
        muscle_groups=["quadriceps", "glutes", "hamstrings", "calves"],
        difficulty="intermediate",
        calories_per_rep=0.35,
        description="A unilateral lower body exercise improving balance and leg strength.",
    ),
]

# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "/analyze",
    response_model=FormFeedback,
    summary="Analyze pose and provide real-time form feedback",
)
async def analyze_pose(
    request: PoseAnalysisRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> FormFeedback:
    """
    Accepts pose keypoints detected by Google ML Kit on-device and returns:
    - Form accuracy score (0–100)
    - A list of form issues detected
    - Correction suggestions
    - Whether this keyframe represents a valid counted rep
    """
    # Validate exercise type
    normalized_exercise_type = request.exercise_type.strip().lower()
    valid_ids = {e.id.lower() for e in EXERCISE_CATALOGUE}
    if normalized_exercise_type not in valid_ids:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Unknown exercise type '{request.exercise_type}'. "
                   f"Valid types: {sorted(valid_ids)}",
        )

    # Filter keypoints below minimum confidence threshold
    confident_keypoints = [
        kp for kp in request.keypoints
        if kp.confidence >= settings.MIN_POSE_CONFIDENCE
    ]

    # Require at least 5 confident keypoints to analyse pose
    if len(confident_keypoints) < 5:
        return FormFeedback(
            exercise_type=request.exercise_type,
            is_valid_pose=False,
            accuracy_score=0.0,
            issues=["Not enough body landmarks detected. Ensure your full body is in frame."],
            suggestions=["Step back from the camera", "Ensure good lighting"],
            rep_counted=False,
        )

    # Use pose analyser service for accuracy scoring
    analyzer = PoseAnalyzer()
    keypoints_dict = {kp.name: {"x": kp.x, "y": kp.y, "score": kp.confidence}
                      for kp in confident_keypoints}
    missing_keypoints = analyzer.missing_keypoints(keypoints_dict, normalized_exercise_type)
    if missing_keypoints:
        return FormFeedback(
            exercise_type=request.exercise_type,
            is_valid_pose=False,
            accuracy_score=0.0,
            issues=[f"Missing required landmarks: {', '.join(missing_keypoints)}."],
            suggestions=["Turn so the required joints are visible to the camera."],
            rep_counted=False,
        )

    accuracy = analyzer.calculate_accuracy(keypoints_dict, normalized_exercise_type)

    # Generate contextual feedback based on accuracy band
    issues: List[str] = []
    suggestions: List[str] = []

    if accuracy < 50:
        issues.append("Overall form needs significant improvement.")
        suggestions.append("Watch the exercise tutorial before continuing.")
        suggestions.append("Try slowing down to focus on form.")
    elif accuracy < 75:
        issues.append("Form is acceptable but can be improved.")
        suggestions.append("Focus on keeping your core engaged throughout.")
        suggestions.append("Maintain a steady, controlled pace.")
    else:
        suggestions.append("Great form! Keep it up.")

    # Count rep if accuracy is sufficient
    rep_counted = request.rep_number is not None and accuracy >= 60.0

    return FormFeedback(
        exercise_type=request.exercise_type,
        is_valid_pose=True,
        accuracy_score=round(accuracy, 1),
        issues=issues,
        suggestions=suggestions,
        rep_counted=rep_counted,
    )


@router.get(
    "/exercises",
    response_model=List[ExerciseInfo],
    summary="Get the catalogue of supported exercises",
)
async def get_exercises(
    current_user: User = Depends(get_current_active_user),
) -> List[ExerciseInfo]:
    """
    Returns all exercises supported by the AI pose detection engine,
    including muscle groups, difficulty, and calorie estimates.
    """
    return EXERCISE_CATALOGUE
