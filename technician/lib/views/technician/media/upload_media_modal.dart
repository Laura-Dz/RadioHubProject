import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_file_picker.dart';

import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/media_item_model.dart';
import '../../../core/utils/media_helpers.dart';
import '../../../core/constants/app_colors.dart';

class UploadMediaModal extends StatefulWidget {
  const UploadMediaModal({Key? key}) : super(key: key);

  @override
  State<UploadMediaModal> createState() => _State();
}

class _State extends State<UploadMediaModal> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _tagCtrl = TextEditingController();

  SelectedImageFile? _file;

  Uint8List? _bytes;
  MediaType _type = MediaType.audio;
  String? _programId;
  List<String> _tags = [];
  int _durationSeconds = 0;
  bool _uploading = false;
  double _progress = 0;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Upload media',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- FILE PICKER ----------
                      _sectionLabel('File'),
                      const SizedBox(height: 6),
                      _fileTile(),
                      const SizedBox(height: 16),

                      // ---------- NAME ----------
                      _label('Display name'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _name,
                        decoration: _dec().copyWith(hintText: 'e.g., Morning Drive intro jingle'),
                      ),
                      const SizedBox(height: 14),

                      // ---------- TYPE ----------
                      _label('Type'),
                      const SizedBox(height: 6),
                      Row(
                        children: MediaType.values.map((t) {
                          final sel = _type == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_typeLabel(t)),
                              selected: sel,
                              onSelected: (_) => setState(() => _type = t),
                              selectedColor: AppColors.primary.withOpacity(0.12),
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                  color: sel ? AppColors.primary : AppColors.border),
                              labelStyle: TextStyle(
                                color: sel ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // ---------- PROGRAM ----------
                      _label('Belongs to program (optional)'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        value: _programId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('Not linked to a program')),
                          ...vm.programs.map((p) => DropdownMenuItem<String?>(
                              value: p.id, child: Text(p.name))),
                        ],
                        onChanged: (v) => setState(() => _programId = v),
                        decoration: _dec(''),
                      ),
                      const SizedBox(height: 14),

                      // ---------- TAGS ----------
                      _label('Tags'),
                      const SizedBox(height: 6),
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _tags.map((t) => Chip(
                                label: Text(t),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => setState(() => _tags.remove(t)),
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.border),
                                labelStyle: const TextStyle(fontSize: 12),
                              )).toList(),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagCtrl,
                              decoration: _dec().copyWith(hintText: 'Add a tag', isDense: true),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---------- DESCRIPTION ----------
                      _label('Description (optional)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _description,
                        maxLines: 3,
                        decoration: _dec(''),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_uploading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text('Uploading ${(_progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          minHeight: 4,
                          color: AppColors.primary,
                          backgroundColor: AppColors.border,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_uploading || _bytes == null) ? null : _submit,
                    icon: _uploading
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload, size: 16),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String s) => Text(s,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));
  Widget _label(String s) => Text(s,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  Widget _fileTile() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _uploading ? null : _pickFile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _file != null ? AppColors.primary.withOpacity(0.4) : AppColors.border,
              width: _file != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _file == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _file?.name ?? 'Choose a file',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _file != null
                          ? '${(_file!.size / 1024 / 1024).toStringAsFixed(1)} MB'
                              '${_durationSeconds > 0 ? " · ${_durationLabel()}" : ""}'
                          : 'Audio, video, or podcast · max 200 MB',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_file == null)
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _durationLabel() {
    final m = _durationSeconds ~/ 60;
    final s = _durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  InputDecoration _dec([String? hint]) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      );

  Future<void> _pickFile() async {
    try {
      final file = await AppFilePicker.pickMedia(
        accept: 'audio/*,video/*,.mp3,.m4a,.wav,.ogg,.aac,.mp4,.mov,.webm,.mkv',
      );
      if (file == null) return;

      // Infer media type from extension
      final ext = file.name.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'webm', 'mkv'].contains(ext);

      setState(() {
        _file = file;
        _bytes = file.bytes;
        _type = isVideo
            ? MediaType.video
            : (ext == 'mp3' ? MediaType.audio : MediaType.podcast);
        if (_name.text.isEmpty) {
          _name.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });

      // Extract duration asynchronously
      final secs = await MediaHelpers.extractDurationSeconds(
        bytes: file.bytes,
        mimeType: MediaHelpers.guessContentType(file.name, isVideo: isVideo),
      );
      if (mounted) setState(() => _durationSeconds = secs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() {
      _tags.add(t);
      _tagCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (_bytes == null || _file == null) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a display name'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      final vm = context.read<TechnicianViewModel>();
      final isVideo = _type == MediaType.video;
      final contentType = MediaHelpers.guessContentType(_file!.name, isVideo: isVideo);

      await vm.uploadMedia(
        bytes: _bytes!,
        fileName: _file!.name,
        contentType: contentType,
        name: _name.text.trim(),
        type: _type,
        durationSeconds: _durationSeconds,
        programId: _programId,
        tags: _tags,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media uploaded'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _typeLabel(MediaType t) => switch (t) {
        MediaType.audio => 'Audio',
        MediaType.video => 'Video',
        MediaType.podcast => 'Podcast',
      };
}
