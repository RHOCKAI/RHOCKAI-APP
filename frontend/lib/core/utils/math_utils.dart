import 'dart:math' as math;

/// Mathematical utilities for pose analysis
class MathUtils {
  /// Calculate angle between three points (in degrees)
  /// 
  /// Example: To calculate elbow angle, pass:
  /// - point1: shoulder
  /// - point2: elbow (vertex)
  /// - point3: wrist
  static double calculateAngle(
    math.Point<double> point1,
    math.Point<double> point2,
    math.Point<double> point3,
  ) {
    // Vector from point2 to point1
    final dx1 = point1.x - point2.x;
    final dy1 = point1.y - point2.y;
    
    // Vector from point2 to point3
    final dx2 = point3.x - point2.x;
    final dy2 = point3.y - point2.y;
    
    // Calculate dot product
    final dotProduct = dx1 * dx2 + dy1 * dy2;
    
    // Calculate magnitudes
    final magnitude1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    final magnitude2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
    
    // Avoid division by zero
    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0;
    }
    
    // Calculate angle in radians
    final angleRad = math.acos(
      (dotProduct / (magnitude1 * magnitude2)).clamp(-1.0, 1.0),
    );
    
    // Convert to degrees
    return angleRad * 180 / math.pi;
  }
  
  /// Calculate Euclidean distance between two points
  static double calculateDistance(
    math.Point<double> point1,
    math.Point<double> point2,
  ) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// Normalize coordinates to 0-1 range based on image dimensions
  static math.Point<double> normalizePoint(
    math.Point<double> point,
    int imageWidth,
    int imageHeight,
  ) {
    return math.Point(
      point.x / imageWidth,
      point.y / imageHeight,
    );
  }
  
  /// Check if an angle is within a target range with tolerance
  static bool isAngleInRange(
    double angle,
    double targetAngle,
    double tolerance,
  ) {
    return (angle - targetAngle).abs() <= tolerance;
  }
  
  /// Calculate the midpoint between two points
  static math.Point<double> midpoint(
    math.Point<double> point1,
    math.Point<double> point2,
  ) {
    return math.Point(
      (point1.x + point2.x) / 2,
      (point1.y + point2.y) / 2,
    );
  }
  
  /// Check if two angles are symmetric (within tolerance)
  static bool areAnglesSymmetric(
    double angle1,
    double angle2,
    double tolerance,
  ) {
    return (angle1 - angle2).abs() <= tolerance;
  }
}
