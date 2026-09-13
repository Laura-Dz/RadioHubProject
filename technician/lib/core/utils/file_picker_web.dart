import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'app_file_picker.dart';

Future<SelectedImageFile?> pickImageFilePlatform() {
  return _pickFilePlatform(accept: 'image/png,image/jpeg,image/jpg,image/webp,image/gif');
}

Future<SelectedImageFile?> pickMediaFilePlatform({String accept = 'audio/*,video/*'}) {
  return _pickFilePlatform(accept: accept);
}

Future<SelectedImageFile?> _pickFilePlatform({required String accept}) {
  final completer = Completer<SelectedImageFile?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = accept;
  uploadInput.multiple = false;
  uploadInput.style.display = 'none';
  html.document.body?.children.add(uploadInput);

  bool completed = false;

  void completeWith(SelectedImageFile? file) {
    if (!completed) {
      completed = true;
      try {
        uploadInput.remove();
      } catch (_) {}
      completer.complete(file);
    }
  }

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is Uint8List) {
          completeWith(SelectedImageFile(
            name: file.name,
            bytes: result,
            size: file.size,
          ));
        } else if (result is List<int>) {
          completeWith(SelectedImageFile(
            name: file.name,
            bytes: Uint8List.fromList(result),
            size: file.size,
          ));
        } else if (result is ByteBuffer) {
          completeWith(SelectedImageFile(
            name: file.name,
            bytes: result.asUint8List(),
            size: file.size,
          ));
        } else {
          debugPrint('Unknown reader result type: ${result.runtimeType}');
          completeWith(null);
        }
      });
      reader.onError.listen((err) {
        debugPrint('FileReader error: $err');
        completeWith(null);
      });
    } else {
      completeWith(null);
    }
  });

  uploadInput.addEventListener('cancel', (e) {
    completeWith(null);
  });

  uploadInput.click();

  return completer.future;
}
