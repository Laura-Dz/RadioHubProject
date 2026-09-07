import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for uploading and downloading files from Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file from disk to the given path. Returns the download URL.
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putFile(file, metadata);
    return await task.ref.getDownloadURL();
  }

  /// Upload raw bytes to the given path.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putData(bytes, metadata);
    return await task.ref.getDownloadURL();
  }

  /// Upload a text string to the given path.
  Future<String> uploadString({
    required String path,
    required String data,
    String format = 'raw',
  }) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putString(data, format: _parseFormat(format));
    return await task.ref.getDownloadURL();
  }

  /// Get a download URL for an existing file at the given path.
  Future<String> getDownloadUrl(String path) async {
    return await _storage.ref().child(path).getDownloadURL();
  }

  /// Delete a file at the given path. Returns true if successful.
  Future<bool> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// List all files under a given prefix.
  Future<List<String>> listFiles(String prefix) async {
    final result = await _storage.ref().child(prefix).listAll();
    return result.items.map((item) => item.fullPath).toList();
  }

  /// Get a public reference for direct URL access.
  Reference ref(String path) => _storage.ref().child(path);

  PutStringFormat _parseFormat(String format) {
    switch (format) {
      case 'base64':
        return PutStringFormat.base64;
      case 'base64Url':
        return PutStringFormat.base64Url;
      case 'dataUrl':
        return PutStringFormat.dataUrl;
      default:
        return PutStringFormat.raw;
    }
  }
}
