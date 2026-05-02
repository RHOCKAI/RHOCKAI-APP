import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShareCardController {
  static const String _watermarkKey = 'show_rhockai_watermark';

  Future<bool> getWatermarkPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_watermarkKey) ?? true;
  }

  Future<void> saveWatermarkPreference(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_watermarkKey, visible);
  }

  Future<void> shareCard({
    required GlobalKey repaintKey,
    required String exercise,
    required int reps,
    required double accuracy,
    required int streak,
    required bool watermarkVisible,
    String? platform,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Wait for any ongoing animations or frames
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/rhockai_share.png').create();
      await imagePath.writeAsBytes(pngBytes);

      final text = 'My Rhockai Workout: $reps reps of $exercise with ${accuracy.toInt()}% accuracy! 🔥 $streak day streak. 🦾 #Rhockai #AITraining';

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: text,
      );

      // In a real app, you would POST to /track here
      debugPrint('Analytics: share_completed event tracked');
      debugPrint('Payload: {exercise: $exercise, reps: $reps, accuracy: $accuracy, streak: $streak, watermark: $watermarkVisible, platform: $platform}');

    } catch (e) {
      debugPrint('Error sharing card: $e');
    }
  }

  Future<void> saveToCameraRoll(GlobalKey repaintKey) async {
    // This usually requires a package like gallery_saver or image_gallery_saver
    // For now we'll just demonstrate the capture part
    try {
      final RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Implementation depends on platform and permission packages
      debugPrint('Saving ${pngBytes.length} bytes to gallery...');
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
    }
  }
}
