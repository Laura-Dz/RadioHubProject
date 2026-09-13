import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_file_picker.dart';

class AvatarPicker extends StatefulWidget {
  final String? initialUrl;
  final String name;
  final ValueChanged<String?> onPhotoChanged;
  final double radius;

  const AvatarPicker({
    Key? key,
    this.initialUrl,
    required this.name,
    required this.onPhotoChanged,
    this.radius = 42,
  }) : super(key: key);

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _currentUrl;
  Uint8List? _previewBytes;
  bool _isUploading = false;
  bool _showUrlInput = false;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _urlCtrl = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant AvatarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl && _previewBytes == null) {
      _currentUrl = widget.initialUrl;
      _urlCtrl.text = widget.initialUrl ?? '';
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final file = await AppFilePicker.pickImage();
      if (file == null) return;

      setState(() {
        _previewBytes = file.bytes;
        _isUploading = true;
      });

      final vm = context.read<RadioAdminViewModel>();
      String finalUrl = '';

      try {
        finalUrl = await vm.uploadStaffAvatar(file.toXFile());
      } catch (e) {
        debugPrint('Avatar S3 upload failed, using Data URI fallback: $e');
        // Fallback: store as data URI if <= 800 KB
        if (file.bytes.lengthInBytes <= 800 * 1024) {
          final ext = file.name.contains('.')
              ? file.name.split('.').last.toLowerCase()
              : 'png';
          final mime = (ext == 'jpg' || ext == 'jpeg')
              ? 'image/jpeg'
              : (ext == 'webp' ? 'image/webp' : 'image/png');
          finalUrl = 'data:$mime;base64,${base64Encode(file.bytes)}';
        } else {
          rethrow;
        }
      }

      if (mounted) {
        setState(() {
          _currentUrl = finalUrl;
          _urlCtrl.text = finalUrl;
          _isUploading = false;
        });
        widget.onPhotoChanged(finalUrl);
      }
    } catch (e) {
      debugPrint('Avatar picker error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _applyUrl(String val) {
    final trimmed = val.trim();
    setState(() {
      _previewBytes = null;
      _currentUrl = trimmed.isEmpty ? null : trimmed;
    });
    widget.onPhotoChanged(trimmed.isEmpty ? null : trimmed);
  }

  void _clearPhoto() {
    setState(() {
      _previewBytes = null;
      _currentUrl = null;
      _urlCtrl.clear();
    });
    widget.onPhotoChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _previewBytes != null ||
        (_currentUrl != null && _currentUrl!.trim().isNotEmpty);

    ImageProvider? imageProvider;
    if (_previewBytes != null) {
      imageProvider = MemoryImage(_previewBytes!);
    } else if (_currentUrl != null && _currentUrl!.startsWith('data:')) {
      try {
        final commaIdx = _currentUrl!.indexOf(',');
        if (commaIdx != -1) {
          final rawBase64 = _currentUrl!.substring(commaIdx + 1);
          imageProvider = MemoryImage(base64Decode(rawBase64));
        }
      } catch (_) {}
    } else if (_currentUrl != null && _currentUrl!.trim().isNotEmpty) {
      imageProvider = NetworkImage(_currentUrl!.trim());
    }

    final initial = widget.name.trim().isNotEmpty
        ? widget.name.trim()[0].toUpperCase()
        : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar with camera button overlay
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: widget.radius,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: widget.radius * 0.85,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _isUploading ? null : _pickAndUpload,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUpload,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(hasPhoto ? 'Change Photo' : 'Upload Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      if (hasPhoto) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Remove photo',
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          onPressed: _isUploading ? null : _clearPhoto,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => setState(() => _showUrlInput = !_showUrlInput),
                    child: Text(
                      _showUrlInput ? 'Hide URL input' : 'Or enter image URL',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showUrlInput) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Image Web URL (HTTPS)',
                    hintText: 'https://example.com/avatar.jpg',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: _applyUrl,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _applyUrl(_urlCtrl.text),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
