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
      return 'http://127.0.0.1:$defaultBackendPort';
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
        link = link.replaceAll('://localhost:', '://127.0.0.1:');
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
    defaultValue: 'AQ.Ab8RN6IhPptg5tRK0sTYWMfyiLTj3KSKEsHNFFwSGDtRzeS8Xw',
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
