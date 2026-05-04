import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rhockai/core/constants/api_constants.dart';

class UpdateService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 50),
    receiveTimeout: const Duration(seconds: 50),
  ));

  /// Checks for an update and shows a dialog if one is available
  static Future<void> checkForUpdate(BuildContext context) async {
    // Only check on Android for this specific direct APK deployment
    if (!Platform.isAndroid) return;

    try {
      final response = await _dio.get('/system/version');
      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['latest_version'] as String;
        final downloadUrl = data['download_url'] as String;
        final forceUpdate = data['force_update'] as bool? ?? false;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl, forceUpdate);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    // Simple version comparison (assumes semver e.g., "1.0.0")
    final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final current = i < currentParts.length ? currentParts[i] : 0;
      final latest = i < latestParts.length ? latestParts[i] : 0;

      if (latest > current) return true;
      if (current > latest) return false;
    }
    return false; // Same version
  }

  static void _showUpdateDialog(
      BuildContext context, String latestVersion, String downloadUrl, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            title: const Text('Update Available! 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                'A new version of Rhockai ($latestVersion) is available. Would you like to download and install it now?'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: <Widget>[
              if (!forceUpdate)
                TextButton(
                  child: const Text('Later', style: TextStyle(color: Colors.grey)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Download Update', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final Uri url = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open the download link.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
