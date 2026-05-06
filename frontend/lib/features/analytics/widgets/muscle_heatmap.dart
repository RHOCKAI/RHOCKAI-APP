import 'package:flutter/material.dart';

enum MuscleGroup {
  chest,
  triceps,
  shoulders,
  core,
  quads,
  glutes,
  hamstrings,
  back,
  calves,
  forearms,
  abs,
  obliques,
  traps,
  biceps,
}

class MuscleHeatmap extends StatelessWidget {
  final Map<String, double> fatigueLevels; // 0.0 to 1.0
  final bool showBack;

  const MuscleHeatmap({
    required this.fatigueLevels,
    this.showBack = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.6,
      child: CustomPaint(
        painter: BodyPainter(
          fatigueLevels: fatigueLevels,
          showBack: showBack,
        ),
      ),
    );
  }
}

class BodyPainter extends CustomPainter {
  final Map<String, double> fatigueLevels;
  final bool showBack;

  BodyPainter({required this.fatigueLevels, required this.showBack});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Helper to get color based on fatigue
    Color getMuscleColor(String muscle) {
      final fatigue = fatigueLevels[muscle.toLowerCase()] ?? 0.0;
      if (fatigue == 0) {
        return Colors.white.withValues(alpha: 0.05);
      }
      
      // Interpolate from Electric Blue (fresh) to Neon Orange/Red (fatigued)
      return Color.lerp(
        const Color(0xFF00D9FF), // Fresh Blue
        const Color(0xFFFF3D00), // Fatigued Red
        fatigue,
      )!.withValues(alpha: 0.8);
    }

    if (!showBack) {
      _drawFrontBody(canvas, size, paint, outlinePaint, getMuscleColor);
    } else {
      _drawBackBody(canvas, size, paint, outlinePaint, getMuscleColor);
    }
  }

  void _drawFrontBody(Canvas canvas, Size size, Paint paint, Paint outline, Color Function(String) getColor) {
    final w = size.width;
    final h = size.height;

    // Draw Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.1), w * 0.08, outline);

    // Chest
    paint.color = getColor('chest');
    final chestPath = Path()
      ..moveTo(w * 0.35, h * 0.2)
      ..lineTo(w * 0.65, h * 0.2)
      ..lineTo(w * 0.65, h * 0.3)
      ..lineTo(w * 0.35, h * 0.3)
      ..close();
    canvas.drawPath(chestPath, paint);
    canvas.drawPath(chestPath, outline);

    // Abs / Core
    paint.color = getColor('core');
    final absPath = Path()
      ..moveTo(w * 0.38, h * 0.31)
      ..lineTo(w * 0.62, h * 0.31)
      ..lineTo(w * 0.6, h * 0.45)
      ..lineTo(w * 0.4, h * 0.45)
      ..close();
    canvas.drawPath(absPath, paint);
    canvas.drawPath(absPath, outline);

    // Quads (Left)
    paint.color = getColor('quads');
    final leftQuad = Path()
      ..moveTo(w * 0.35, h * 0.5)
      ..lineTo(w * 0.48, h * 0.5)
      ..lineTo(w * 0.45, h * 0.7)
      ..lineTo(w * 0.32, h * 0.7)
      ..close();
    canvas.drawPath(leftQuad, paint);
    canvas.drawPath(leftQuad, outline);

    // Quads (Right)
    paint.color = getColor('quads');
    final rightQuad = Path()
      ..moveTo(w * 0.52, h * 0.5)
      ..lineTo(w * 0.65, h * 0.5)
      ..lineTo(w * 0.68, h * 0.7)
      ..lineTo(w * 0.55, h * 0.7)
      ..close();
    canvas.drawPath(rightQuad, paint);
    canvas.drawPath(rightQuad, outline);

    // Shoulders
    paint.color = getColor('shoulders');
    canvas.drawCircle(Offset(w * 0.3, h * 0.22), w * 0.05, paint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.22), w * 0.05, paint);
    canvas.drawCircle(Offset(w * 0.3, h * 0.22), w * 0.05, outline);
    canvas.drawCircle(Offset(w * 0.7, h * 0.22), w * 0.05, outline);
  }

  void _drawBackBody(Canvas canvas, Size size, Paint paint, Paint outline, Color Function(String) getColor) {
    final w = size.width;
    final h = size.height;

    // Draw Head (Back)
    canvas.drawCircle(Offset(w * 0.5, h * 0.1), w * 0.08, outline);

    // Upper Back
    paint.color = getColor('back');
    final backPath = Path()
      ..moveTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.7, h * 0.2)
      ..lineTo(w * 0.65, h * 0.35)
      ..lineTo(w * 0.35, h * 0.35)
      ..close();
    canvas.drawPath(backPath, paint);
    canvas.drawPath(backPath, outline);

    // Glutes
    paint.color = getColor('glutes');
    final glutesPath = Path()
      ..moveTo(w * 0.35, h * 0.45)
      ..lineTo(w * 0.65, h * 0.45)
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w * 0.32, h * 0.55)
      ..close();
    canvas.drawPath(glutesPath, paint);
    canvas.drawPath(glutesPath, outline);

    // Hamstrings
    paint.color = getColor('hamstrings');
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.57, w * 0.13, h * 0.15), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.57, w * 0.13, h * 0.15), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.57, w * 0.13, h * 0.15), outline);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.57, w * 0.13, h * 0.15), outline);

    // Calves
    paint.color = getColor('calves');
    canvas.drawOval(Rect.fromLTWH(w * 0.33, h * 0.75, w * 0.1, h * 0.12), paint);
    canvas.drawOval(Rect.fromLTWH(w * 0.57, h * 0.75, w * 0.1, h * 0.12), paint);
    canvas.drawOval(Rect.fromLTWH(w * 0.33, h * 0.75, w * 0.1, h * 0.12), outline);
    canvas.drawOval(Rect.fromLTWH(w * 0.57, h * 0.75, w * 0.1, h * 0.12), outline);
    
    // Triceps
    paint.color = getColor('triceps');
    canvas.drawOval(Rect.fromLTWH(w * 0.23, h * 0.25, w * 0.06, h * 0.12), paint);
    canvas.drawOval(Rect.fromLTWH(w * 0.71, h * 0.25, w * 0.06, h * 0.12), paint);
    canvas.drawOval(Rect.fromLTWH(w * 0.23, h * 0.25, w * 0.06, h * 0.12), outline);
    canvas.drawOval(Rect.fromLTWH(w * 0.71, h * 0.25, w * 0.06, h * 0.12), outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
