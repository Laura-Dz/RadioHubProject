import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/station_media_model.dart';
import '../../../core/services/station_media_service.dart';
import '../../../core/widgets/safe_image.dart';
import '../widgets/media_player_sheet.dart';

class StationMediaScreen extends StatefulWidget {
  final String radioId;
  final String radioName;

  const StationMediaScreen({
    Key? key,
    required this.radioId,
    required this.radioName,
  }) : super(key: key);

  @override
  State<StationMediaScreen> createState() => _StationMediaScreenState();
}

class _StationMediaScreenState extends State<StationMediaScreen> with SingleTickerProviderStateMixin {
  final StationMediaService _mediaService = StationMediaService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _playMedia(StationMediaModel item) {
    _mediaService.incrementPlayCount(item.id);
    MediaPlayerSheet.show(context, media: item, radioName: widget.radioName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0.5,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audios & Videos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.radioName,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Audios'),
            Tab(text: 'Podcasts'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search episodes, podcasts, clips...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Media List
          Expanded(
            child: StreamBuilder<List<StationMediaModel>>(
              stream: _mediaService.streamStationMedia(widget.radioId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final allItems = snapshot.data ?? [];
                final tabIndex = _tabController.index;

                // Filter by tab
                var filtered = allItems.where((item) {
                  if (tabIndex == 1) return item.isAudio;
                  if (tabIndex == 2) return item.isPodcast;
                  if (tabIndex == 3) return item.isVideo;
                  return true;
                }).toList();

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((item) {
                    final t = item.title.toLowerCase();
                    final d = (item.description ?? '').toLowerCase();
                    return t.contains(_searchQuery) || d.contains(_searchQuery);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tabIndex == 3 ? Icons.videocam_off_outlined : Icons.music_off_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No results found for "$_searchQuery"'
                                : 'No media items available in this category.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _mediaCard(item, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard(StationMediaModel item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _playMedia(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail with type overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: SafeImage(
                        imageUrl: item.thumbnailUrl,
                        fit: BoxFit.cover,
                        fallback: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.6),
                                AppColors.secondary.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              item.isVideo
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.graphic_eq_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.formattedDuration.isNotEmpty ? item.formattedDuration : item.typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Title, description, tags, playCount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.isVideo
                                ? Colors.purple.withOpacity(0.12)
                                : (item.isPodcast
                                    ? Colors.orange.withOpacity(0.12)
                                    : AppColors.primary.withOpacity(0.12)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.typeLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: item.isVideo
                                  ? Colors.purple
                                  : (item.isPodcast ? Colors.orange : AppColors.primary),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (item.playCount > 0) ...[
                          const Icon(Icons.headphones_outlined, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${item.playCount}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Play action icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
