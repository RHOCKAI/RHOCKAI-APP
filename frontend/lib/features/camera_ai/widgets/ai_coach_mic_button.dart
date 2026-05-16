import 'package:flutter/material.dart';
import 'package:rhockai/core/config/app_theme.dart';
import 'package:rhockai/shared/widgets/pulse_animation.dart';

class AICoachMicButton extends StatefulWidget {
  final int plannedExerciseId;
  final Function(Map<String, dynamic>) onCommandProcessed;

  const AICoachMicButton({
    super.key,
    required this.plannedExerciseId,
    required this.onCommandProcessed,
  });

  @override
  State<AICoachMicButton> createState() => _AICoachMicButtonState();
}

class _AICoachMicButtonState extends State<AICoachMicButton> {
  bool _isProcessing = false;

  Future<void> _simulateVoiceCommand() async {
    if (_isProcessing) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Mocked Backend Response
      await Future.delayed(const Duration(seconds: 1));
      final mockResponse = {
        'action': 'update_weight',
        'message': 'I hear you. Let\'s drop the weight down. Focus on your form.',
        'data': {'new_weight': 75}
      };

      widget.onCommandProcessed(mockResponse);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _simulateVoiceCommand,
      child: PulseAnimation(
        active: _isProcessing,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: _isProcessing 
                ? AppTheme.neonOrange 
                : AppTheme.neonBlue.withValues(alpha: 0.2),
            child: Icon(
              _isProcessing ? Icons.more_horiz : Icons.mic_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
