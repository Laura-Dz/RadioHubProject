import 'dart:async';
import 'app_file_picker.dart';

Future<SelectedImageFile?> pickImageFilePlatform() async {
  throw UnsupportedError('File picking is not supported on this platform.');
}

Future<SelectedImageFile?> pickMediaFilePlatform({String accept = 'audio/*,video/*'}) async {
  throw UnsupportedError('Media picking is not supported on this platform.');
}
