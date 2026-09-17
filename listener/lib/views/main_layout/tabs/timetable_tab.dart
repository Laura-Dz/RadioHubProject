import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/timetable_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/placeholder_image.dart';
import '../../../core/widgets/safe_image.dart';

class TimetableTab extends StatefulWidget {
  const TimetableTab({Key? key}) : super(key: key);

  @override
  State<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<TimetableTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimetableViewModel>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewModel = context.watch<TimetableViewModel>();

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterChip(context, viewModel, 'Weekdays', viewModel.weekdayShows.isNotEmpty),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(context, viewModel, 'Weekends', viewModel.weekendShows.isNotEmpty),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: viewModel.selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: viewModel.categories.map((category) {
                        return DropdownMenuItem(value: category, child: Text(category.toUpperCase()));
                      }).toList(),
                      onChanged: (value) => viewModel.setCategory(value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: viewModel.selectedHost,
                      decoration: InputDecoration(
                        labelText: 'Host',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: viewModel.hosts.map((host) {
                        return DropdownMenuItem(value: host, child: Text(host));
                      }).toList(),
                      onChanged: (value) => viewModel.setHost(value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (viewModel.selectedCategory != null || viewModel.selectedHost != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton.icon(
                  onPressed: viewModel.clearFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear filters'),
                ),
              ),
            ),
          if (viewModel.isLoading && viewModel.filteredShows.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final show = viewModel.filteredShows[index];
                  return _buildShowTile(context, show, viewModel);
                },
                childCount: viewModel.filteredShows.length,
              ),
            ),
          if (viewModel.filteredShows.isEmpty && !viewModel.isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No shows found', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Try adjusting your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, TimetableViewModel viewModel, String label, bool hasData) {
    final isSelected = label == 'Weekdays'
        ? viewModel.selectedDayType == 'weekday'
        : viewModel.selectedDayType == 'weekend';

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final dayType = label == 'Weekdays' ? 'weekday' : 'weekend';
          viewModel.setDayType(dayType);
        } else {
          viewModel.setDayType(null);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.surface,
    );
  }

  Widget _buildShowTile(BuildContext context, dynamic show, TimetableViewModel viewModel) {
    final timeRange = '${_formatTime(show.startTime)} - ${_formatTime(show.endTime)}';
    final dayLabel = show.dayType == 'weekday' ? 'Mon - Fri' : 'Sat - Sun';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SafeImage(
            imageUrl: show.imageUrl,
            width: 56,
            height: 56,
            fallback: const PlaceholderImage(width: 56, height: 56),
          ),
        ),
        title: Text(
          show.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${show.host} • ${show.category}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(timeRange, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(dayLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            show.isFollowed == true ? Icons.favorite : Icons.favorite_border,
            color: show.isFollowed == true ? Colors.red : Colors.grey,
          ),
          onPressed: () => viewModel.toggleFollow(show.id, show.isFollowed != true),
        ),
        onTap: () {},
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
