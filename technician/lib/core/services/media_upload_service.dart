import 'dart:typed_data';
import 'storage_service.dart';

class MediaUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int fileSizeKb;
  MediaUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSizeKb,
  });
}

class MediaUploadService {
  final StorageService _storageService;
  static const int maxBytes = 200 * 1024 * 1024; // 200 MB

  MediaUploadService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  Future<MediaUploadResult> upload({
    required String radioId,
    required Uint8List bytes,
    required String fileName,
    required String contentType, // 'audio/mpeg', 'video/mp4', ...
    void Function(double)? onProgress,
  }) async {
    if (bytes.isEmpty) throw Exception('File is empty.');
    if (bytes.length > maxBytes) {
      final mb = (bytes.length / 1024 / 1024).toStringAsFixed(1);
      throw Exception('File is too large ($mb MB). Maximum is 200 MB.');
    }

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'radios/$radioId/media/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final url = await _storageService.uploadBytes(
      bytes: bytes,
      path: path,
      contentType: contentType,
      onProgress: onProgress,
    );

    return MediaUploadResult(
      downloadUrl: url,
      storagePath: path,
      fileSizeKb: bytes.length ~/ 1024,
    );
  }

  Future<void> deleteByStoragePath(String path) async {
    await _storageService.deleteOldFile(path);
  }
}
