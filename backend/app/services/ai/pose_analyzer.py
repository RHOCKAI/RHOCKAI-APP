# app/services/ai/pose_analyzer.py

from typing import Dict, List
import math

class PoseAnalyzer:
    """
    Analyze pose landmarks for exercise form
    Note: Frontend does most analysis. Backend validates & stores.
    """
    
    @staticmethod
    def calculate_angle(a: Dict, b: Dict, c: Dict) -> float:
        """Calculate angle between three points"""
        ba_x = a['x'] - b['x']
        ba_y = a['y'] - b['y']
        bc_x = c['x'] - b['x']
        bc_y = c['y'] - b['y']
        
        dot_product = ba_x * bc_x + ba_y * bc_y
        magnitude_ba = math.sqrt(ba_x ** 2 + ba_y ** 2)
        magnitude_bc = math.sqrt(bc_x ** 2 + bc_y ** 2)
        
        angle_rad = math.acos(dot_product / (magnitude_ba * magnitude_bc))
        return math.degrees(angle_rad)
    
    @staticmethod
    def validate_pushup_form(landmarks: Dict) -> Dict:
        """Validate push-up form"""
        # Get relevant angles
        left_elbow_angle = PoseAnalyzer.calculate_angle(
            landmarks['left_shoulder'],
            landmarks['left_elbow'],
            landmarks['left_wrist']
        )
        
        hip_angle = PoseAnalyzer.calculate_angle(
            landmarks['left_shoulder'],
            landmarks['left_hip'],
            landmarks['left_knee']
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
                "hip": hip_angle
            }
        }