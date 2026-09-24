/// Application-wide configuration for backend networking and audio streaming.
class AppConfig {
  /// The local WiFi IP of the development host computer.
  /// Overridable at compile time via: --dart-define=BACKEND_HOST=192.168.x.x
  static const String defaultBackendHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '192.168.1.211',
  );

  /// Default port for the Django backend.
  /// Overridable at compile time via: --dart-define=BACKEND_PORT=8000
  static const int defaultBackendPort = int.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: 8000,
  );

  /// Base URL for the central Django backend API.
  static String get backendUrl {
    const customUrl = String.fromEnvironment('BACKEND_URL');
    if (customUrl.isNotEmpty) return customUrl;
    return 'http://$defaultBackendHost:$defaultBackendPort';
  }

  /// Resolve live audio stream URL for a given radio station ID.
  /// Format: http://<HOST>:8000/api/stream/<radio_id>/
  static String getStreamUrl(String radioId) {
    final cleanId = radioId.trim().isNotEmpty ? radioId.trim() : 'radio_1';
    return '$backendUrl/api/stream/$cleanId/';
  }

  /// Verified public fallback radio stream URL for phone audio hardware test
  /// in case the local Django/Shoutcast server is not actively transmitting audio.
  static const String testAudioStreamUrl =
      'https://stream.zeno.fm/f3wvbbqmdg8uv';
}
