import 'package:uuid/uuid.dart';

class TrackSessionRequest {
  final String sessionId;
  final String deviceType;
  final String deviceModel;
  final String osName;
  final String osVersion;
  final String appVersion;
  final String? country;
  final String? city;
  final String? timezone;
  final String? connectionType;

  TrackSessionRequest({
    required this.sessionId,
    required this.deviceType,
    required this.deviceModel,
    required this.osName,
    required this.osVersion,
    required this.appVersion,
    this.country,
    this.city,
    this.timezone,
    this.connectionType = 'wifi',
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'device_type': deviceType,
        'device_model': deviceModel,
        'os_name': osName,
        'os_version': osVersion,
        'app_version': appVersion,
        'country': country,
        'city': city,
        'timezone': timezone,
        'connection_type': connectionType,
      };

  factory TrackSessionRequest.generate({
    required String appVersion,
    String? deviceType,
    String? deviceModel,
    String? osName,
    String? osVersion,
  }) {
    return TrackSessionRequest(
      sessionId: const Uuid().v4(),
      deviceType: deviceType ?? 'unknown',
      deviceModel: deviceModel ?? 'unknown',
      osName: osName ?? 'unknown',
      osVersion: osVersion ?? 'unknown',
      appVersion: appVersion,
    );
  }
}

class TrackScreenRequest {
  final String sessionId;
  final String screenName;
  final String? previousScreen;
  final int? timeOnScreen;
  final Map<String, dynamic>? extraData;

  TrackScreenRequest({
    required this.sessionId,
    required this.screenName,
    this.previousScreen,
    this.timeOnScreen,
    this.extraData,
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'screen_name': screenName,
        'previous_screen': previousScreen,
        'time_on_screen': timeOnScreen,
        'extra_data': extraData,
      };
}

class TrackFeatureRequest {
  final String featureName;
  final String action;
  final Map<String, dynamic>? extraData;

  TrackFeatureRequest({
    required this.featureName,
    required this.action,
    this.extraData,
  });

  Map<String, dynamic> toJson() => {
        'feature_name': featureName,
        'action': action,
        'extra_data': extraData,
      };
}

class TrackErrorRequest {
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final String? screen;
  final String? appVersion;
  final String? osName;
  final String? osVersion;
  final String? deviceModel;

  TrackErrorRequest({
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    this.screen,
    this.appVersion,
    this.osName,
    this.osVersion,
    this.deviceModel,
  });

  Map<String, dynamic> toJson() => {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'screen': screen,
        'app_version': appVersion,
        'os_name': osName,
        'os_version': osVersion,
        'device_model': deviceModel,
      };
}
