import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/session_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/models/radio_admin/host_model.dart';
import '../../../core/widgets/common_widgets.dart';
import 'widgets/session_form_dialog.dart';

class SessionsTab extends StatelessWidget {
  final String radioId;

  const SessionsTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();

    return DefaultTabController(
      length: 3,
      child: Padding(
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
                      'Sessions',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: RadioAdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your sessions',
                      style: TextStyle(
                        fontSize: 14,
                        color: RadioAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ActionButton(
                  label: 'New Session',
                  icon: Icons.add,
                  onPressed: () => _showSessionDialog(viewModel.radioId, viewModel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: RadioAdminColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RadioAdminColors.divider),
              ),
              child: const TabBar(
                labelColor: RadioAdminColors.primary,
                unselectedLabelColor: RadioAdminColors.textSecondary,
                indicatorColor: RadioAdminColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Live'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUpcomingTab(viewModel),
                  _buildLiveTab(viewModel),
                  _buildPastTab(viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(RadioAdminViewModel viewModel) {
    final upcoming = viewModel.upcomingSessions;

    return upcoming.isEmpty
        ? EmptyState(
            title: 'No upcoming sessions',
            subtitle: 'Create your first session to get started',
            icon: Icons.schedule,
            actionLabel: 'Create Session',
            onAction: () => _showSessionDialog(viewModel.radioId, viewModel),
          )
        : _buildSessionsList(upcoming, viewModel);
  }

  Widget _buildLiveTab(RadioAdminViewModel viewModel) {
    final live = viewModel.sessions.where((s) => s.status == SessionStatus.live).toList();

    return live.isEmpty
        ? EmptyState(
            title: 'No live sessions',
            subtitle: 'Sessions currently on air will appear here',
            icon: Icons.radio,
          )
        : _buildSessionsList(live, viewModel);
  }

  Widget _buildPastTab(RadioAdminViewModel viewModel) {
    final past = viewModel.pastSessions;

    return past.isEmpty
        ? EmptyState(
            title: 'No past sessions',
            subtitle: 'Completed sessions will appear here',
            icon: Icons.history,
          )
        : _buildSessionsList(past, viewModel);
  }

  Widget _buildSessionsList(List<Session> sessions, RadioAdminViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: ListView.separated(
        itemCount: sessions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: RadioAdminColors.divider),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionRow(context, session, viewModel);
        },
      ),
    );
  }

  Widget _buildSessionRow(BuildContext context, Session session, RadioAdminViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: session.status == SessionStatus.live
                  ? RadioAdminColors.error.withOpacity(0.1)
                  : session.program.category.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              session.status == SessionStatus.live ? Icons.live_tv : Icons.radio,
              color: session.status == SessionStatus.live
                  ? RadioAdminColors.error
                  : session.program.category.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.programName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: RadioAdminColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${session.hostName ?? 'TBA'} • ${_formatDateTime(session.startTime)} - ${_formatTime(session.endTime)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: RadioAdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(session.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusLabel(session.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(session.status),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${session.listenerCount}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RadioAdminColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (session.status == SessionStatus.scheduled) ...[
                  IconButton(
                    icon: const Icon(Icons.play_circle, size: 18),
                    color: RadioAdminColors.success,
                    onPressed: () => viewModel.startSession(session.id),
                    tooltip: 'Start Live',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
                if (session.status == SessionStatus.live) ...[
                  IconButton(
                    icon: const Icon(Icons.stop_circle, size: 18),
                    color: RadioAdminColors.error,
                    onPressed: () => viewModel.endSession(session.id),
                    tooltip: 'End Session',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: RadioAdminColors.textSecondary,
                  onPressed: () => _showSessionDialog(viewModel.radioId, viewModel, session: session),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: RadioAdminColors.error,
                  onPressed: () => _confirmDeleteSession(context, viewModel, session),
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.live:
        return RadioAdminColors.error;
      case SessionStatus.scheduled:
        return RadioAdminColors.primary;
      case SessionStatus.ended:
        return RadioAdminColors.success;
      case SessionStatus.rediffusion:
        return RadioAdminColors.warning;
    }
  }

  String _getStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.live:
        return 'LIVE';
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.ended:
        return 'Ended';
      case SessionStatus.rediffusion:
        return 'Rediffusion';
    }
  }

  String _formatDateTime(DateTime time) {
    return '${DateFormat('MMM d, HH:mm').format(time)}';
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  void _showSessionDialog(String radioId, RadioAdminViewModel viewModel, {Session? session}) {
    // This would need a proper context
    // showDialog(context: context, builder: (context) => SessionFormDialog(viewModel: viewModel, session: session));
  }

  void _confirmDeleteSession(BuildContext context, RadioAdminViewModel viewModel, Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.programName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // viewModel.deleteSession(session.id); // Need to add delete method
            },
            style: ElevatedButton.styleFrom(backgroundColor: RadioAdminColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}