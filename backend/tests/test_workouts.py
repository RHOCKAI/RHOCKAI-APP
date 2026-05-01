"""
Smoke tests for the Exercise Catalogue endpoints.
"""

import pytest


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
