"""
Smoke tests for the Exercise Catalogue endpoints.
"""

import pytest
from datetime import datetime, timezone

from app.models import Exercise, PlannedExercise, ScheduledWorkout, User, WorkoutPlan


class TestListExercises:
    def test_returns_all_exercises(self, client, auth_headers):
        response = client.get("/api/v1/workouts/catalogue/exercises", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 3

    def test_exercise_detail_fields(self, client, auth_headers):
        response = client.get("/api/v1/workouts/catalogue/exercises", headers=auth_headers)
        exercise = response.json()[0]
        required = {"id", "name", "category", "difficulty", "muscle_groups",
                    "instructions", "tips", "common_mistakes", "calories_per_rep"}
        assert required.issubset(exercise.keys())

    def test_filter_by_difficulty(self, client, auth_headers):
        response = client.get(
            "/api/v1/workouts/catalogue/exercises?difficulty=beginner",
            headers=auth_headers,
        )
        assert response.status_code == 200
        for ex in response.json():
            assert ex["difficulty"] == "beginner"

    def test_filter_by_category(self, client, auth_headers):
        response = client.get(
            "/api/v1/workouts/catalogue/exercises?category=strength",
            headers=auth_headers,
        )
        assert response.status_code == 200
        for ex in response.json():
            assert ex["category"] == "strength"

    def test_requires_auth(self, client):
        response = client.get("/api/v1/workouts/catalogue/exercises")
        assert response.status_code == 401


class TestGetExerciseById:
    def test_valid_id_returns_exercise(self, client, auth_headers):
        response = client.get("/api/v1/workouts/catalogue/exercises/pushup", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "pushup"
        assert data["name"] == "Push-up"

    def test_invalid_id_returns_404(self, client, auth_headers):
        response = client.get(
            "/api/v1/workouts/catalogue/exercises/invalid_exercise",
            headers=auth_headers,
        )
        assert response.status_code == 404

    def test_requires_auth(self, client):
        response = client.get("/api/v1/workouts/catalogue/exercises/pushup")
        assert response.status_code == 401


def test_adaptation_is_scoped_to_the_owning_user(client, auth_headers, db, test_user):
    other_user = User(
        email="otheruser@example.com",
        hashed_password="not-used",
        full_name="Other User",
    )
    exercise = Exercise(
        name="Push-up",
        slug="pushup",
        description="A bodyweight push exercise.",
        difficulty="beginner",
        muscle_groups=["chest"],
        default_reps=10,
        default_sets=3,
    )
    substitute = Exercise(
        name="Chest Press",
        slug="chest-press",
        description="A machine chest exercise.",
        difficulty="beginner",
        muscle_groups=["chest"],
        default_reps=8,
        default_sets=3,
    )
    db.add_all([other_user, exercise, substitute])
    db.flush()

    plan = WorkoutPlan(
        user_id=other_user.id,
        name="Other user's plan",
        focus="strength",
        start_date=datetime.now(timezone.utc),
        is_active=True,
    )
    db.add(plan)
    db.flush()

    workout = ScheduledWorkout(
        plan_id=plan.id,
        day_number=1,
        name="Chest day",
        focus_muscle_groups=["chest"],
    )
    db.add(workout)
    db.flush()

    planned_exercise = PlannedExercise(
        scheduled_workout_id=workout.id,
        exercise_id=exercise.id,
        order=1,
        target_sets=3,
        target_reps=10,
    )
    db.add(planned_exercise)
    db.commit()

    response = client.post(
        f"/api/v1/workouts/plan/adapt/{planned_exercise.id}",
        headers=auth_headers,
    )

    assert response.status_code == 404
    db.refresh(planned_exercise)
    assert planned_exercise.exercise_id == exercise.id
    assert planned_exercise.is_substituted is False

    voice_response = client.post(
        "/api/v1/coach/voice-command",
        headers=auth_headers,
        json={
            "planned_exercise_id": planned_exercise.id,
            "transcript": "make this too easy",
        },
    )

    assert voice_response.status_code == 200
    assert voice_response.json()["action"] == "error"
    db.refresh(planned_exercise)
    assert planned_exercise.target_reps == 10

    plan.user_id = test_user.id
    db.commit()
    owner_response = client.post(
        f"/api/v1/workouts/plan/adapt/{planned_exercise.id}",
        headers=auth_headers,
    )

    assert owner_response.status_code == 200
    assert owner_response.json()["is_substituted"] is True
    assert owner_response.json()["exercise_id"] == substitute.id
