import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/schedule_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/placeholder_image.dart';
import '../../../core/widgets/safe_image.dart';
import '../widgets/live_badge.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({Key? key}) : super(key: key);

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleViewModel>().loadSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewModel = context.watch<ScheduleViewModel>();

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            title: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: viewModel.selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    await viewModel.setSelectedDate(picked);
                  }
                },
              ),
            ],
          ),
          if (viewModel.isLoading && viewModel.todaySchedule.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            if (viewModel.nowPlaying != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.9), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            buildBadgeForTag(viewModel.nowPlaying!.displayTag),
                            const Spacer(),
                            Text(
                              '${_formatTime(viewModel.nowPlaying!.startTime)} - ${_formatTime(viewModel.nowPlaying!.endTime)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          viewModel.nowPlaying!.title,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'with ${viewModel.nowPlaying!.host}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (viewModel.nowPlaying!.guest != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'Guest: ${viewModel.nowPlaying!.guest}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        if (viewModel.activeFlashes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: viewModel.activeFlashes.map((flash) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flash_on, size: 16, color: Colors.yellowAccent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          flash.title,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.radio_button_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No live show at the moment', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Check the schedule below for upcoming shows', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
              ),
          if (viewModel.todaySchedule.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Today - ${_formatDate(viewModel.selectedDate)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = viewModel.todaySchedule[index];
                final isNow = viewModel.nowPlaying?.id == item.id;
                return _buildScheduleTile(context, item, isNow);
              },
              childCount: viewModel.todaySchedule.length,
            ),
          ),
          if (viewModel.upcomingShows.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Upcoming', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = viewModel.upcomingShows[index];
                return _buildScheduleTile(context, item);
              },
              childCount: viewModel.upcomingShows.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(BuildContext context, dynamic item, [bool isNow = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isNow ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isNow ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeImage(
                  imageUrl: item.imageUrl,
                  width: 60,
                  height: 60,
                  fallback: const PlaceholderImage(width: 60, height: 60),
                ),
              ),
              if (isNow)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(fontWeight: isNow ? FontWeight.bold : FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.host}${item.guest != null ? ' with ${item.guest}' : ''}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (item.type != 'regular') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor(item.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: _getTypeColor(item.type), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: item.isInteractive == true
            ? const Icon(Icons.quiz, color: AppColors.primary, size: 20)
            : null,
        onTap: () {},
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'special':
        return Colors.purple;
      case 'interview':
        return Colors.blue;
      case 'flash':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
