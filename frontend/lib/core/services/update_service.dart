import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rhockai/core/constants/api_constants.dart';

/// 🚀 In-App Over-The-Air (OTA) Remote Update Service
///
/// Enables 100% free, decentralized updates without Google Play Store fees:
/// 1. Queries GitHub Releases CDN (`RHOCKAI/RHOCKAI-APP`) directly (serverless)
/// 2. Falls back to backend API (`/system/version`) if available
/// 3. Downloads release APK with real-time progress bar
/// 4. Automatically triggers Android Package Installer
class UpdateService {
  static const String repoOwner = 'RHOCKAI';
  static const String repoName = 'RHOCKAI-APP';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Accept': 'application/vnd.github.v3+json'},
    ),
  );

  static bool _hasCheckedThisSession = false;

  /// Checks for an update and shows an installation dialog if one is available
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool force = false,
  }) async {
    // Direct APK update is designed for Android
    if (!Platform.isAndroid) {
      return;
    }

    if (_hasCheckedThisSession && !force) {
      return;
    }
    _hasCheckedThisSession = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "2.0.0"

      String? latestVersion;
      String? downloadUrl;
      String? releaseNotes;
      bool isForced = false;

      // 1. Primary: Try GitHub Releases (Free cloud CDN, zero backend server needed)
      try {
        final ghResponse = await _dio.get<Map<String, dynamic>>(
          'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
        );

        if (ghResponse.statusCode == 200 && ghResponse.data != null) {
          final data = ghResponse.data!;
          final rawTag = (data['tag_name'] as String? ?? '').trim();
          latestVersion = rawTag.replaceAll(RegExp(r'^[vV]'), '');
          releaseNotes = data['body'] as String? ?? '';

          final assets = data['assets'] as List? ?? [];
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }
      } catch (ghError) {
        debugPrint('UpdateService: GitHub release check skipped: $ghError');
      }

      // 2. Fallback: Try self-hosted backend if GitHub didn't return an APK
      if (downloadUrl == null) {
        try {
          final backendResponse = await _dio.get<Map<String, dynamic>>(
            '${ApiConstants.baseUrl}/system/version',
          );
          if (backendResponse.statusCode == 200 && backendResponse.data != null) {
            final data = backendResponse.data!;
            latestVersion = data['latest_version'] as String?;
            downloadUrl = data['download_url'] as String?;
            isForced = data['force_update'] as bool? ?? false;
          }
        } catch (_) {}
      }

      // 3. Compare versions and prompt user
      if (latestVersion != null &&
          downloadUrl != null &&
          _isUpdateAvailable(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion: latestVersion,
            currentVersion: currentVersion,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
            forceUpdate: isForced,
          );
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Error checking for updates: $e');
    }
  }

  /// Compares semantic versions (e.g. 2.0.1 > 2.0.0)
  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final current = i < currentParts.length ? currentParts[i] : 0;
        final latest = i < latestParts.length ? latestParts[i] : 0;

        if (latest > current) {
          return true;
        }
        if (current > latest) {
          return false;
        }
      }
    } catch (_) {
      return currentVersion != latestVersion;
    }
    return false;
  }

  /// Shows the Rhockai Cyber-HUD update modal with live in-app download progress
  static void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String currentVersion,
    required String downloadUrl,
    String? releaseNotes,
    bool forceUpdate = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogCtx) {
        double downloadProgress = 0.0;
        bool isDownloading = false;
        String statusText = 'Ready to upgrade';

        return StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              canPop: !forceUpdate && !isDownloading,
              child: Dialog(
                backgroundColor: const Color(0xFF12121A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.system_update_alt_rounded,
                              color: Color(0xFF00FF88),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UPDATE AVAILABLE',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'v$currentVersion ➔ v$latestVersion',
                                  style: const TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 13,
                                    color: Color(0xFF00D9FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        releaseNotes != null && releaseNotes.isNotEmpty
                            ? releaseNotes
                            : 'A new version of Rhockai AI is ready with upgraded on-device pose intelligence, performance, and stability fixes.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      if (isDownloading) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: downloadProgress > 0 ? downloadProgress / 100 : null,
                            minHeight: 8,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00FF88),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              '${downloadProgress.toInt()}%',
                              style: const TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00FF88),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!forceUpdate && !isDownloading)
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: Text(
                                'LATER',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (!isDownloading)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF88),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  isDownloading = true;
                                  statusText = 'Downloading APK...';
                                });
                                _startOtaDownload(
                                  downloadUrl: downloadUrl,
                                  onProgress: (progress, status) {
                                    setState(() {
                                      downloadProgress = progress;
                                      statusText = status;
                                    });
                                  },
                                );
                              },
                              child: const Text(
                                'UPDATE NOW',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Triggers OTA download stream and launches Android Package Installer
  static void _startOtaDownload({
    required String downloadUrl,
    required void Function(double progress, String status) onProgress,
  }) {
    try {
      OtaUpdate().execute(
        downloadUrl,
        destinationFilename: 'rhockai_release.apk',
      ).listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final val = double.tryParse(event.value ?? '0') ?? 0.0;
              onProgress(val, 'Downloading package...');
              break;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              onProgress(100.0, 'Launching installer...');
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              onProgress(0.0, 'Download already in progress');
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              onProgress(0.0, 'Permission denied');
              break;
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            default:
              onProgress(0.0, 'Update failed. Try again later.');
              break;
          }
        },
        onError: (e) {
          debugPrint('UpdateService OTA Error: $e');
          onProgress(0.0, 'Download error');
        },
      );
    } catch (e) {
      debugPrint('UpdateService Execute Error: $e');
      onProgress(0.0, 'Failed to launch installer');
    }
  }
}
