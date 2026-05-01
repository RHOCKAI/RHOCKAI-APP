"""
Smoke tests for the AI Pose Analysis endpoints.
"""

import pytest


VALID_KEYPOINTS = [
    {"name": "left_shoulder", "x": 0.3, "y": 0.4, "confidence": 0.9},
    {"name": "right_shoulder", "x": 0.7, "y": 0.4, "confidence": 0.9},
    {"name": "left_hip", "x": 0.3, "y": 0.6, "confidence": 0.85},
    {"name": "right_hip", "x": 0.7, "y": 0.6, "confidence": 0.85},
    {"name": "left_knee", "x": 0.3, "y": 0.75, "confidence": 0.8},
    {"name": "right_knee", "x": 0.7, "y": 0.75, "confidence": 0.8},
    {"name": "left_ankle", "x": 0.3, "y": 0.9, "confidence": 0.75},
    {"name": "right_ankle", "x": 0.7, "y": 0.9, "confidence": 0.75},
]


class TestGetExercises:
    def test_returns_list(self, client, auth_headers):
        response = client.get("/api/v1/ai/exercises", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 3

    def test_exercise_has_required_fields(self, client, auth_headers):
        response = client.get("/api/v1/ai/exercises", headers=auth_headers)
        exercise = response.json()[0]
        required_fields = {"id", "name", "muscle_groups", "difficulty", "calories_per_rep", "description"}
        assert required_fields.issubset(exercise.keys())

    def test_requires_auth(self, client):
        response = client.get("/api/v1/ai/exercises")
        assert response.status_code == 401


class TestAnalyzePose:
    def test_valid_pose_returns_feedback(self, client, auth_headers):
        payload = {
            "exercise_type": "pushup",
            "keypoints": VALID_KEYPOINTS,
        }
        response = client.post("/api/v1/ai/analyze", json=payload, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "accuracy_score" in data
        assert "is_valid_pose" in data
        assert data["exercise_type"] == "pushup"

    def test_insufficient_keypoints_returns_invalid_pose(self, client, auth_headers):
        payload = {
            "exercise_type": "squat",
            "keypoints": [
                {"name": "left_shoulder", "x": 0.3, "y": 0.4, "confidence": 0.9},
                {"name": "right_shoulder", "x": 0.7, "y": 0.4, "confidence": 0.9},
            ],
        }
        response = client.post("/api/v1/ai/analyze", json=payload, headers=auth_headers)
        assert response.status_code == 200
        assert response.json()["is_valid_pose"] is False

    def test_unknown_exercise_returns_422(self, client, auth_headers):
        payload = {
            "exercise_type": "backflip",
            "keypoints": VALID_KEYPOINTS,
        }
        response = client.post("/api/v1/ai/analyze", json=payload, headers=auth_headers)
        assert response.status_code == 422

    def test_requires_auth(self, client):
        response = client.post("/api/v1/ai/analyze", json={})
        assert response.status_code == 401
