# app/services/ai/pose_analyzer.py

from typing import Dict, List
import math

class PoseAnalyzer:
    """
    Analyze pose landmarks for exercise form.
    The backend performs lightweight validation and score generation while
    the Flutter app handles most of the on-device pose analysis.
    """

    @staticmethod
    def calculate_angle(a: Dict, b: Dict, c: Dict) -> float:
        """Calculate angle between three points"""
        ba_x = a['x'] - b['x']
        ba_y = a['y'] - b['y']
        bc_x = c['x'] - b['x']
        bc_y = c['y'] - b['y']

        mag_ba = math.hypot(ba_x, ba_y)
        mag_bc = math.hypot(bc_x, bc_y)
        if mag_ba == 0 or mag_bc == 0:
            return 0.0

        dot_product = ba_x * bc_x + ba_y * bc_y
        cosine = dot_product / (mag_ba * mag_bc)
        cosine = max(-1.0, min(1.0, cosine))
        return math.degrees(math.acos(cosine))

    @staticmethod
    def calculate_accuracy(keypoints: Dict[str, Dict[str, float]], exercise_type: str) -> float:
        """Return a 0-100 accuracy score for the given exercise type."""
        exercise_type = (exercise_type or '').lower().strip()

        if exercise_type == 'pushup':
            required = ['left_shoulder', 'left_elbow', 'left_wrist', 'left_hip', 'left_knee']
            if not all(k in keypoints for k in required):
                return 0.0

            elbow_angle = PoseAnalyzer.calculate_angle(
                keypoints['left_shoulder'],
                keypoints['left_elbow'],
                keypoints['left_wrist'],
            )
            hip_angle = PoseAnalyzer.calculate_angle(
                keypoints['left_shoulder'],
                keypoints['left_hip'],
                keypoints['left_knee'],
            )

            score = 100.0
            score -= max(0.0, abs(elbow_angle - 90.0) * 0.5)
            score -= max(0.0, 160.0 - hip_angle) * 0.8
            return max(0.0, min(100.0, score))

        if exercise_type in {'squat', 'lunge'}:
            required = ['left_hip', 'left_knee', 'left_ankle']
            if not all(k in keypoints for k in required):
                return 0.0
            knee_angle = PoseAnalyzer.calculate_angle(
                keypoints['left_hip'],
                keypoints['left_knee'],
                keypoints['left_ankle'],
            )
            score = 100.0 - max(0.0, abs(knee_angle - 90.0) * 0.6)
            return max(0.0, min(100.0, score))

        if exercise_type == 'plank':
            required = ['left_shoulder', 'left_hip', 'left_knee']
            if not all(k in keypoints for k in required):
                return 0.0
            body_angle = PoseAnalyzer.calculate_angle(
                keypoints['left_shoulder'],
                keypoints['left_hip'],
                keypoints['left_knee'],
            )
            score = 100.0 - max(0.0, abs(body_angle - 180.0) * 0.4)
            return max(0.0, min(100.0, score))

        return 75.0

    @staticmethod
    def validate_pushup_form(landmarks: Dict) -> Dict:
        """Validate push-up form"""
        left_elbow_angle = PoseAnalyzer.calculate_angle(
            landmarks['left_shoulder'],
            landmarks['left_elbow'],
            landmarks['left_wrist'],
        )

        hip_angle = PoseAnalyzer.calculate_angle(
            landmarks['left_shoulder'],
            landmarks['left_hip'],
            landmarks['left_knee'],
        )

        issues = []
        if hip_angle < 160:
            issues.append("Keep your back straight")

        accuracy = 100 - (len(issues) * 20)

        return {
            "is_correct": len(issues) == 0,
            "issues": issues,
            "accuracy": max(0, accuracy),
            "angles": {
                "elbow": left_elbow_angle,
                "hip": hip_angle,
            },
        }