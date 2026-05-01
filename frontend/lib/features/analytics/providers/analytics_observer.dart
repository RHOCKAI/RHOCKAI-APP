import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsObserver extends NavigatorObserver {
  final AnalyticsService _analyticsService;

  AnalyticsObserver(this._analyticsService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackScreen(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackScreen(previousRoute);
    }
  }

  void _trackScreen(Route<dynamic> route) {
    final screenName = route.settings.name;
    if (screenName != null) {
      _analyticsService.trackScreen(screenName);
    }
  }
}
