import 'package:flutter/material.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/dependency.dart' as di;

class AppRouteObserver extends NavigatorObserver {
  final LoggerUtil _logger = di.sl<LoggerUtil>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('Route PUSHED: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('Route POPPED: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _logger.info('Route REPLACED: ${newRoute?.settings.name}');
  }
}
