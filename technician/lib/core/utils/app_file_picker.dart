import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'file_picker_stub.dart'
    if (dart.library.html) 'file_picker_web.dart'
    if (dart.library.io) 'file_picker_io.dart';

class SelectedImageFile {
  final String name;
  final Uint8List bytes;
  final int size;

  SelectedImageFile({
    required this.name,
    required this.bytes,
    required this.size,
  });

  XFile toXFile() {
    return XFile.fromData(bytes, name: name);
  }
}

class AppFilePicker {
  /// Picks an image file using the native file explorer.
  /// On Web: Uses native HTML FileUploadInputElement (avoids MissingPluginException when web plugins are not registered).
  /// On Mobile/Desktop: Uses image_picker.
  static Future<SelectedImageFile?> pickImage() {
    return pickImageFilePlatform();
  }

  /// Picks any media file (audio, video, etc.) using native browser/OS file explorer
  static Future<SelectedImageFile?> pickMedia({String accept = 'audio/*,video/*'}) {
    return pickMediaFilePlatform(accept: accept);
  }
}
