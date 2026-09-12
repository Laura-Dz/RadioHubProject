import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/metric_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/widgets/common_widgets.dart';

class DashboardTab extends StatelessWidget {
  final String radioId;

  const DashboardTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview of your radio station',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ActionButton(
                label: 'Refresh',
                icon: Icons.refresh,
                onPressed: viewModel.refreshData,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Key Metrics
          if (viewModel.metrics != null) ...[
            _buildMetricsGrid(viewModel.metrics!),
            const SizedBox(height: 24),
          ],

          // Quick Actions
          _buildQuickActions(context, viewModel),
          const SizedBox(height: 24),

          // Upcoming Sessions
          _buildUpcomingSessions(viewModel),
          const SizedBox(height: 24),

          // Top Programs
          _buildTopPrograms(viewModel),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(RadioMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 5 : (constraints.maxWidth > 800 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            MetricCard(
              label: 'Total Programs',
              value: metrics.totalPrograms.toString(),
              subtitle: '${metrics.activePrograms} active',
              icon: Icons.radio,
              iconColor: RadioAdminColors.primary,
            ),
            MetricCard(
              label: 'Total Hosts',
              value: metrics.totalHosts.toString(),
              subtitle: '${metrics.activeHosts} active',
              icon: Icons.person,
              iconColor: RadioAdminColors.success,
            ),
            MetricCard(
              label: 'Total Sessions',
              value: metrics.totalSessions.toString(),
              subtitle: '${metrics.liveSessions} live',
              icon: Icons.play_circle,
              iconColor: RadioAdminColors.warning,
            ),
            MetricCard(
              label: 'Avg Listeners',
              value: metrics.avgListeners.toString(),
              subtitle: 'per session',
              icon: Icons.headphones,
              iconColor: RadioAdminColors.accent,
            ),
            MetricCard(
              label: 'Media Files',
              value: metrics.totalMedia.toString(),
              subtitle: 'in library',
              icon: Icons.library_music,
              iconColor: RadioAdminColors.primaryDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, RadioAdminViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionButton(
              label: 'New Program',
              icon: Icons.add,
              onPressed: () => viewModel.setActiveTab('programs'),
              backgroundColor: RadioAdminColors.primary,
            ),
            ActionButton(
              label: 'New Host',
              icon: Icons.person_add,
              onPressed: () => viewModel.setActiveTab('hosts'),
              backgroundColor: RadioAdminColors.success,
            ),
            ActionButton(
              label: 'Create Session',
              icon: Icons.add_circle,
              onPressed: () => viewModel.setActiveTab('sessions'),
              backgroundColor: RadioAdminColors.warning,
            ),
            ActionButton(
              label: 'Upload Media',
              icon: Icons.upload,
              onPressed: () => viewModel.setActiveTab('media'),
              backgroundColor: RadioAdminColors.primaryDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingSessions(RadioAdminViewModel viewModel) {
    final upcoming = viewModel.upcomingSessions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: RadioAdminColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => viewModel.setActiveTab('sessions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        upcoming.isEmpty
            ? EmptyState(
                title: 'No upcoming sessions',
                subtitle: 'Create your first session to get started',
                icon: Icons.event_available,
                actionLabel: 'Create Session',
                onAction: () => viewModel.setActiveTab('sessions'),
              )
            : Container(
                decoration: BoxDecoration(
                  color: RadioAdminColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RadioAdminColors.divider),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: RadioAdminColors.divider),
                  itemBuilder: (context, index) {
                    final session = upcoming[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: RadioAdminColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radio, color: RadioAdminColors.primary),
                      ),
                      title: Text(
                        session.programName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: RadioAdminColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${session.hostName ?? 'TBA'} • ${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: RadioAdminColors.textSecondary,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: RadioAdminColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Scheduled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: RadioAdminColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildTopPrograms(RadioAdminViewModel viewModel) {
    final activePrograms = viewModel.programs.where((p) => p.isActive).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Programs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        activePrograms.isEmpty
            ? EmptyState(
                title: 'No programs yet',
                subtitle: 'Create your first program to get started',
                icon: Icons.radio,
                actionLabel: 'Create Program',
                onAction: () => viewModel.setActiveTab('programs'),
              )
            : Container(
                decoration: BoxDecoration(
                  color: RadioAdminColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RadioAdminColors.divider),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activePrograms.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: RadioAdminColors.divider),
                  itemBuilder: (context, index) {
                    final program = activePrograms[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: program.category.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          program.category.iconData,
                          color: program.category.iconColor,
                        ),
                      ),
                      title: Text(
                        program.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: RadioAdminColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${program.category.label} • ${_formatDuration(program.duration)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: RadioAdminColors.textSecondary,
                        ),
                      ),
                      trailing: StatusBadge(
                        label: program.isActive ? 'Active' : 'Inactive',
                        color: program.isActive ? RadioAdminColors.success : RadioAdminColors.error,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}