import 'package:flutter/foundation.dart';

/// Application-wide configuration for backend networking and audio streaming.
class AppConfig {
  /// The local WiFi IP of the development host computer.
  /// Overridable at compile time via: --dart-define=BACKEND_HOST=192.168.x.x
  static const String defaultBackendHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '192.168.4.119',
  );

  /// Default port for the Django backend.
  /// Overridable at compile time via: --dart-define=BACKEND_PORT=8002
  static const int defaultBackendPort = int.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: 8002,
  );

  /// Base URL for the central Django backend API.
  static String get backendUrl {
    const customUrl = String.fromEnvironment('BACKEND_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return 'http://${Uri.base.host}:$defaultBackendPort';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const customHost = String.fromEnvironment('BACKEND_HOST');
      if (customHost.isNotEmpty) {
        return 'http://$customHost:$defaultBackendPort';
      }
      return 'http://$defaultBackendHost:$defaultBackendPort';
    }
    return 'http://$defaultBackendHost:$defaultBackendPort';
  }

  /// Live audio stream URL decrypted in real-time by the central Django backend.
  static String getStreamUrl(String radioId) {
    final cleanId = radioId.trim().isNotEmpty ? radioId.trim() : 'radio_1790489454722';
    return '$backendUrl/api/stream/$cleanId/';
  }

  /// Resolves any configured broadcast link (handling localhost/IP remapping for Android devices)
  /// or falls back to the decrypted Django stream URL.
  static String resolveStreamUrl(String? configuredLink, {String radioId = 'radio_1790489454722'}) {
    if (configuredLink != null &&
        configuredLink.trim().isNotEmpty &&
        !configuredLink.contains(':8000')) {
      var link = configuredLink.trim();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        link = link
            .replaceAll('://localhost:', '://$defaultBackendHost:')
            .replaceAll('://127.0.0.1:', '://$defaultBackendHost:');
      }
      return link;
    }
    return getStreamUrl(radioId);
  }

  /// OpenAI API Key for content moderation.
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue:
        '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',
  );

  /// Gemini API Key for announcement amelioration.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6K5NisMXNB4wrV6LG80cjS0RvTjJ3xBp1ferZ7SejQ1Ig',
  );

  /// DigiPay API Key for Mobile Money transactions & donations.
  static const String digipayApiKey = String.fromEnvironment(
    'DIGIPAY_API_KEY',
    defaultValue: 'dpk_145e8e14e7d01c6f2f560791bef38836bd2a591352507ccd',
  );

  /// Flutterwave Public Key for Bank Transfers & Card Collections.
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
    defaultValue: 'FLWPUBK_TEST-8cc155c3e7464889d4762b499bf9bb20-X',
  );
}
