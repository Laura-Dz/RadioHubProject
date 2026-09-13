import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/media_item_model.dart';
import '../../../core/constants/app_colors.dart';
import 'upload_media_modal.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({Key? key}) : super(key: key);
  @override
  State<MediaScreen> createState() => _State();
}

class _State extends State<MediaScreen> {
  final _search = TextEditingController();
  MediaType? _typeFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    final filtered = vm.mediaItems.where((m) {
      final s = _search.text.toLowerCase();
      final matchesSearch = s.isEmpty || m.name.toLowerCase().contains(s);
      final matchesType = _typeFilter == null || m.type == _typeFilter;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Media Library'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const UploadMediaModal(),
              ),
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search media...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.4)),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _typeChip(null, 'All'),
                const SizedBox(width: 8),
                _typeChip(MediaType.audio, 'Audio'),
                const SizedBox(width: 8),
                _typeChip(MediaType.video, 'Video'),
                const SizedBox(width: 8),
                _typeChip(MediaType.podcast, 'Podcast'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? _empty()
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _MediaRow(item: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(MediaType? t, String label) {
    final sel = _typeFilter == t;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _typeFilter = t),
      selectedColor: AppColors.primary.withOpacity(0.12),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: sel ? AppColors.primary : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined,
                size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No media yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Upload audio, video, or podcasts for your sessions.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const UploadMediaModal(),
              ),
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Upload media'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
}

class _MediaRow extends StatefulWidget {
  final MediaItem item;
  const _MediaRow({required this.item});
  @override
  State<_MediaRow> createState() => _RowState();
}

class _RowState extends State<_MediaRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hover ? AppColors.hover : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _typeColor(m.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(m.type), color: _typeColor(m.type), size: 20),
          ),
          title: Text(m.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${m.durationDisplay} · ${m.typeLabel} · ${(m.fileSizeKb / 1024).toStringAsFixed(1)} MB'
            '${m.programId != null ? " · linked to program" : ""}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Play',
                icon: const Icon(Icons.play_circle_outline,
                    color: AppColors.primary),
                onPressed: () {},
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(MediaType t) => switch (t) {
        MediaType.audio => Icons.music_note,
        MediaType.video => Icons.videocam,
        MediaType.podcast => Icons.podcasts,
      };

  Color _typeColor(MediaType t) => switch (t) {
        MediaType.audio => AppColors.primary,
        MediaType.video => AppColors.gold,
        MediaType.podcast => AppColors.success,
      };

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${widget.item.name}"?'),
        content: const Text('This permanently removes the file from storage and Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TechnicianViewModel>().deleteMedia(widget.item);
    }
  }
}
