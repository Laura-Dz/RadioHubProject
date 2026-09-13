import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'app_file_picker.dart';

Future<SelectedImageFile?> pickImageFilePlatform() async {
  try {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1024,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return SelectedImageFile(
      name: file.name,
      bytes: bytes,
      size: bytes.lengthInBytes,
    );
  } catch (e) {
    rethrow;
  }
}

Future<SelectedImageFile?> pickMediaFilePlatform({String accept = 'audio/*,video/*'}) async {
  try {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return SelectedImageFile(
      name: file.name,
      bytes: bytes,
      size: bytes.lengthInBytes,
    );
  } catch (e) {
    rethrow;
  }
}
