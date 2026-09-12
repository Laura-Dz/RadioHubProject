import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/radio_admin/media_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_file_picker.dart';
import '../../../core/widgets/empty_state.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({Key? key}) : super(key: key);

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  final _searchCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  MediaItem? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _typeFilter = 'all'; // all, audio, video

  @override
  void initState() {
    super.initState();
    try {
      _player.onPlayerStateChanged.listen(
        (state) {
          if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
        },
        onError: (e) => debugPrint('AudioPlayer state error: $e'),
      );
      _player.onPositionChanged.listen(
        (p) {
          if (mounted) setState(() => _position = p);
        },
        onError: (e) => debugPrint('AudioPlayer position error: $e'),
      );
      _player.onDurationChanged.listen(
        (d) {
          if (mounted) setState(() => _duration = d);
        },
        onError: (e) => debugPrint('AudioPlayer duration error: $e'),
      );
    } catch (e) {
      debugPrint('AudioPlayer initialization warning: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    try {
      _player.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _playTrack(MediaItem item) async {
    try {
      if (_currentTrack?.id == item.id && _isPlaying) {
        await _player.pause();
      } else {
        setState(() => _currentTrack = item);
        if (item.url.isNotEmpty) {
          final validUrl = StorageService.ensureValidUrl(item.url);
          await _player.play(UrlSource(validUrl));
        }
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null || d <= Duration.zero) return '0:00';
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showUploadMediaDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    MediaType selectedType = MediaType.audio;
    SelectedImageFile? selectedFile;
    bool isUploading = false;
    double uploadProgress = 0.0;
    String? uploadError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text('Upload Media Asset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Files will be stored in your secure iDrive e2 S3 bucket (radiohub) and linked to your station library.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Media Type Selector
                    const Text('Media Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(
                              Icons.audiotrack,
                              size: 16,
                              color: selectedType == MediaType.audio ? Colors.white : AppColors.primary,
                            ),
                            label: const Text('Audio Track / Jingle'),
                            selected: selectedType == MediaType.audio,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: selectedType == MediaType.audio ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: isUploading
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        selectedType = MediaType.audio;
                                        selectedFile = null;
                                      });
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(
                              Icons.videocam,
                              size: 16,
                              color: selectedType == MediaType.video ? Colors.white : AppColors.gold,
                            ),
                            label: const Text('Video / Clip'),
                            selected: selectedType == MediaType.video,
                            selectedColor: AppColors.gold,
                            labelStyle: TextStyle(
                              color: selectedType == MediaType.video ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: isUploading
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        selectedType = MediaType.video;
                                        selectedFile = null;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // File Selector Button & Preview
                    const Text('File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isUploading
                          ? null
                          : () async {
                              try {
                                final accept = selectedType == MediaType.audio
                                    ? 'audio/mp3,audio/mpeg,audio/wav,audio/aac,audio/ogg,.mp3,.wav,.aac'
                                    : 'video/mp4,video/webm,.mp4,.webm';
                                final file = await AppFilePicker.pickMedia(accept: accept);
                                if (file != null) {
                                  setDialogState(() {
                                    selectedFile = file;
                                    uploadError = null;
                                    if (titleCtrl.text.trim().isEmpty) {
                                      final rawName = file.name.contains('.')
                                          ? file.name.substring(0, file.name.lastIndexOf('.'))
                                          : file.name;
                                      titleCtrl.text = rawName;
                                    }
                                  });
                                }
                              } catch (e) {
                                setDialogState(() => uploadError = 'Error picking file: $e');
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedFile != null
                              ? AppColors.primary.withOpacity(0.06)
                              : AppColors.background,
                          border: Border.all(
                            color: selectedFile != null ? AppColors.primary : AppColors.border,
                            style: selectedFile != null ? BorderStyle.solid : BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedFile != null
                                  ? (selectedType == MediaType.audio ? Icons.audiotrack : Icons.videocam)
                                  : Icons.file_upload_outlined,
                              color: selectedFile != null ? AppColors.primary : AppColors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFile != null ? selectedFile!.name : 'Choose file from device...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selectedFile != null ? AppColors.textPrimary : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (selectedFile != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatFileSize(selectedFile!.size),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              selectedFile != null ? 'Change' : 'Browse',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text('Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      enabled: !isUploading,
                      decoration: InputDecoration(
                        hintText: 'e.g. Station Theme Song, Morning Jingle',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    const Text('Description (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      enabled: !isUploading,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Broadcast opening signature track',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    // Progress bar / Error display
                    if (isUploading) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Uploading to S3 bucket...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${(uploadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: uploadProgress > 0 ? uploadProgress : null,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],

                    if (uploadError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                uploadError!,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: isUploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload, size: 18),
                label: Text(isUploading ? 'Uploading...' : 'Upload to Cloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (isUploading || selectedFile == null || titleCtrl.text.trim().isEmpty)
                    ? null
                    : () async {
                        setDialogState(() {
                          isUploading = true;
                          uploadProgress = 0.0;
                          uploadError = null;
                        });

                        try {
                          final vm = context.read<RadioAdminViewModel>();
                          await vm.uploadMediaItem(
                            file: selectedFile!.toXFile(),
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                            mediaType: selectedType,
                            onProgress: (p) {
                              setDialogState(() => uploadProgress = p);
                            },
                          );

                          if (mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Media uploaded successfully to iDrive e2 S3 bucket!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isUploading = false;
                            uploadError = 'Upload failed: ${e.toString().replaceAll('Exception: ', '')}';
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteMedia(BuildContext context, MediaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Media Item'),
        content: Text('Are you sure you want to delete "${item.title}"? This will remove the file from your iDrive e2 S3 storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (_currentTrack?.id == item.id) {
          await _player.stop();
          setState(() => _currentTrack = null);
        }
        await context.read<RadioAdminViewModel>().deleteMediaItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Media item deleted.'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete media: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final query = _searchCtrl.text.toLowerCase().trim();

    final filtered = vm.media.where((m) {
      final queryLower = query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          m.title.toLowerCase().contains(queryLower) ||
          (m.description ?? '').toLowerCase().contains(queryLower);
      if (!matchesQuery) return false;
      if (_typeFilter == 'audio') return m.mediaType == MediaType.audio;
      if (_typeFilter == 'video') return m.mediaType == MediaType.video;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Media Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.primary),
                SizedBox(width: 5),
                Text('iDrive e2 (radiohub)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text('Upload Media'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showUploadMediaDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search tracks, jingles, recordings...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _filterChip('all', 'All Media (${vm.media.length})'),
                const SizedBox(width: 8),
                _filterChip('audio', 'Audio only (${vm.media.where((m) => m.mediaType == MediaType.audio).length})'),
                const SizedBox(width: 8),
                _filterChip('video', 'Video only (${vm.media.where((m) => m.mediaType == MediaType.video).length})'),
              ],
            ),
          ),

          // Media List
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.audio_file_outlined,
                    title: 'No media items found',
                    subtitle: 'Upload audio tracks, jingles, and recordings to your iDrive e2 S3 bucket.',
                    action: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text('Upload First Media Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => _showUploadMediaDialog(context),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final isSelected = _currentTrack?.id == item.id;
                      final sizeStr = _formatFileSize(item.fileSizeBytes);
                      final durStr = _formatDuration(item.duration);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: item.mediaType == MediaType.audio
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.gold.withOpacity(0.1),
                            child: Icon(
                              item.mediaType == MediaType.audio ? Icons.audiotrack : Icons.videocam,
                              color: item.mediaType == MediaType.audio ? AppColors.primary : AppColors.gold,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.mediaType == MediaType.audio
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.mediaType == MediaType.audio ? 'AUDIO' : 'VIDEO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.mediaType == MediaType.audio ? AppColors.primary : AppColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                if (durStr != '0:00') ...[
                                  Text(durStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const Text(' · ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                                if (sizeStr.isNotEmpty) ...[
                                  Text(sizeStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const Text(' · ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                                Expanded(
                                  child: Text(
                                    item.description?.isNotEmpty == true
                                        ? item.description!
                                        : 'Uploaded by ${item.uploadedBy}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.mediaType == MediaType.audio && item.url.isNotEmpty)
                                IconButton(
                                  tooltip: isSelected && _isPlaying ? 'Pause' : 'Play Preview',
                                  icon: Icon(
                                    isSelected && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                  onPressed: () => _playTrack(item),
                                ),
                              IconButton(
                                tooltip: 'Copy Cloud URL',
                                icon: const Icon(Icons.link, size: 20, color: AppColors.textSecondary),
                                onPressed: () {
                                  final validUrl = StorageService.ensureValidUrl(item.url);
                                  Clipboard.setData(ClipboardData(text: validUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cloud URL copied to clipboard!')),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete from Storage',
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
                                hoverColor: AppColors.error.withOpacity(0.1),
                                onPressed: () => _confirmDeleteMedia(context, item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Player bar if track selected
          if (_currentTrack != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, size: 36, color: AppColors.primary),
                    onPressed: () => _playTrack(_currentTrack!),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentTrack!.title,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Expanded(
                              child: Slider(
                                value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0),
                                max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
                                onChanged: (v) => _player.seek(Duration(seconds: v.toInt())),
                                activeColor: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close player',
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    onPressed: () async {
                      await _player.stop();
                      setState(() => _currentTrack = null);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String filter, String label) {
    final selected = _typeFilter == filter;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
