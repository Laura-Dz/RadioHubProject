import 'dart:html' as html;

class VoipAudioService {
  static html.MediaStream? _stream;

  static Future<bool> requestMicAndSpeaker() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      _stream = stream;
      return true;
    } catch (e) {
      return false;
    }
  }

  static void stopAudio() {
    try {
      _stream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      _stream = null;
    } catch (_) {}
  }
}
