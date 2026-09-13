import 'dart:typed_data';

class MediaHelpers {
  /// Returns duration in seconds, or 0 if extraction fails.
  /// Note: Detailed duration extraction on web can be handled via audio metadata or players.
  static Future<int> extractDurationSeconds({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return 0;
  }

  static String guessContentType(String fileName, {required bool isVideo}) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp3': return 'audio/mpeg';
      case 'm4a': return 'audio/mp4';
      case 'wav': return 'audio/wav';
      case 'ogg': return 'audio/ogg';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'webm': return 'video/webm';
      default: return isVideo ? 'video/mp4' : 'audio/mpeg';
    }
  }
}
