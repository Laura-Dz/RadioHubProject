import 'package:flutter/foundation.dart';

/// Application configuration for the RadioAdmin dashboard.
/// Connects to the RadioHub Central Django backend on port 8002.
class AppConfig {
  static const String defaultBackendHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: 'localhost',
  );

  static const int defaultBackendPort = int.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: 8002,
  );

  static String get backendUrl {
    const customUrl = String.fromEnvironment('BACKEND_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return 'http://${Uri.base.host}:$defaultBackendPort';
    }
    return 'http://$defaultBackendHost:$defaultBackendPort';
  }
}
