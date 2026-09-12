import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/media_model.dart';
import '../../../core/widgets/common_widgets.dart';

class MediaTab extends StatelessWidget {
  final String radioId;

  const MediaTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Media Library',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your audio and video content',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ActionButton(
                    label: 'Upload Audio',
                    icon: Icons.audiotrack,
                    onPressed: () => _showUploadDialog(context, viewModel, MediaType.audio),
                    backgroundColor: RadioAdminColors.primary,
                  ),
                  const SizedBox(width: 12),
                  ActionButton(
                    label: 'Upload Video',
                    icon: Icons.videocam,
                    onPressed: () => _showUploadDialog(context, viewModel, MediaType.video),
                    backgroundColor: RadioAdminColors.warning,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter tabs
          Container(
            decoration: BoxDecoration(
              color: RadioAdminColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RadioAdminColors.divider),
            ),
            child: DefaultTabController(
              length: 3,
              child: TabBar(
                labelColor: RadioAdminColors.primary,
                unselectedLabelColor: RadioAdminColors.textSecondary,
                indicatorColor: RadioAdminColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Audio'),
                  Tab(text: 'Video'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.media.isEmpty
                    ? EmptyState(
                        title: 'No media yet',
                        subtitle: 'Upload your first audio or video file',
                        icon: Icons.library_music,
                        actionLabel: 'Upload Media',
                        onAction: () => _showUploadDialog(context, viewModel, MediaType.audio),
                      )
                    : _buildMediaGrid(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(RadioAdminViewModel viewModel) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.media.length,
      itemBuilder: (context, index) {
        final media = viewModel.media[index];
        return _buildMediaCard(context, media, viewModel);
      },
    );
  }

  Widget _buildMediaCard(BuildContext context, MediaItem media, RadioAdminViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: RadioAdminColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      media.mediaType == MediaType.audio ? Icons.audiotrack : Icons.videocam,
                      size: 48,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                  if (media.thumbnailUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          media.thumbnailUrl!,
                          fit: BoxFit.cover,
                           errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                         ),
                       ),
                     ),
                   Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: media.mediaType == MediaType.audio
                            ? RadioAdminColors.primary.withOpacity(0.9)
                            : RadioAdminColors.warning.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        media.mediaType == MediaType.audio ? 'AUDIO' : 'VIDEO',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RadioAdminColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (media.duration != null) ...[
                      Icon(
                        Icons.timer,
                        size: 12,
                        color: RadioAdminColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(media.duration!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: RadioAdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.play_circle,
                      size: 12,
                      color: RadioAdminColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${media.playCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: RadioAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      color: RadioAdminColors.textSecondary,
                      onPressed: () {},
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      color: RadioAdminColors.error,
                      onPressed: () => _confirmDeleteMedia(context, media),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, RadioAdminViewModel viewModel, MediaType type) {
    // TODO: Implement upload dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload ${type == MediaType.audio ? "Audio" : "Video"} - Coming Soon')),
    );
  }

  void _confirmDeleteMedia(BuildContext context, MediaItem media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${media.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // viewModel.deleteMedia(media.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: RadioAdminColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}