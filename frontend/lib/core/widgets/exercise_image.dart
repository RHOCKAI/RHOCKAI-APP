import 'package:flutter/material.dart';

/// Reusable exercise image widget that handles both local asset images
/// and network image URLs gracefully with loading and fallback support.
class ExerciseImage extends StatelessWidget {
  final String imageUrl;
  final String emoji;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double emojiSize;
  final Color fallbackColor;

  const ExerciseImage({
    super.key,
    required this.imageUrl,
    this.emoji = '🏋️',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.emojiSize = 36,
    this.fallbackColor = const Color(0xFF1E2749),
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Container(
        width: width,
        height: height,
        color: fallbackColor,
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: emojiSize),
          ),
        ),
      );
    }

    if (imageUrl.trim().isEmpty) {
      return fallback();
    }

    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) {
            return child;
          }
          return fallback();
        },
      );
    }

    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }
}
