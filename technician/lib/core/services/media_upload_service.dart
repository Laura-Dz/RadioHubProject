import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class MediaUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int durationSeconds;
  final int fileSizeKb;
  MediaUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.durationSeconds,
    required this.fileSizeKb,
  });
}

class MediaUploadService {
  final _storage = FirebaseStorage.instance;
  static const maxBytes = 200 * 1024 * 1024; // 200 MB

  Future<MediaUploadResult> upload({
    required String radioId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    void Function(double)? onProgress,
  }) async {
    if (bytes.length > maxBytes) {
      throw Exception('File too large. Maximum is 200 MB.');
    }

    final path =
        'radios/$radioId/media/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });

    try {
      final snap = await task;
      final url = await snap.ref.getDownloadURL();
      return MediaUploadResult(
        downloadUrl: url,
        storagePath: path,
        durationSeconds: 0, // extracted client-side before upload
        fileSizeKb: bytes.length ~/ 1024,
      );
    } finally {
      await sub.cancel();
    }
  }
}
