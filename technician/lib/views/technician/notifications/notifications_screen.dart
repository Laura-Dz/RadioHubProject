import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final items = vm.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (vm.unreadNotifications > 0)
            TextButton.icon(
              onPressed: () => vm.markAllNotificationsRead(),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all read'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: items.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _notifRow(context, vm, items[i]),
            ),
    );
  }

  Widget _notifRow(BuildContext context, TechnicianViewModel vm, dynamic n) {
    return InkWell(
      onTap: () {
        if (!n.isRead) vm.markNotificationRead(n.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? AppColors.surface : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isRead ? AppColors.border : AppColors.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconBg(n.type),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(n.type), size: 18, color: _iconColor(n.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w700,
                            )),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n.body,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(_timeAgo(n.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('You\'re all caught up.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  IconData _iconFor(String type) {
    switch (type) {
      case 'session_started': return Icons.play_circle;
      case 'session_ended': return Icons.stop_circle;
      case 'program_updated': return Icons.edit;
      case 'staff_change': return Icons.person;
      case 'special_event': return Icons.warning_amber_rounded;
      default: return Icons.notifications;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'session_started': return AppColors.success;
      case 'session_ended': return AppColors.textMuted;
      case 'special_event': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  Color _iconBg(String type) => _iconColor(type).withOpacity(0.1);

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
