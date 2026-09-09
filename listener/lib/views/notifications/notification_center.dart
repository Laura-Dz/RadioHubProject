import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_interaction_view_model.dart';
import '../../core/models/user_interaction_model.dart';

class NotificationCenter extends StatelessWidget {
  const NotificationCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserInteractionViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (viewModel.unreadCount > 0)
            TextButton(
              onPressed: viewModel.markAllNotificationsAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: viewModel.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications will appear here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: viewModel.notifications.length,
              itemBuilder: (context, index) {
                final notification = viewModel.notifications[index];
                return _notificationTile(context, notification, viewModel);
              },
            ),
    );
  }

  Widget _notificationTile(
    BuildContext context,
    NotificationModel notification,
    UserInteractionViewModel viewModel,
  ) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          viewModel.markNotificationAsRead(notification.id);
        }
        _handleNotificationTap(context, notification);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? Colors.blue.shade100 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _getNotificationIcon(notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;
    switch (type) {
      case NotificationType.showLive:
        icon = Icons.radio;
        color = Colors.red;
        break;
      case NotificationType.showUpcoming:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case NotificationType.showReminder:
        icon = Icons.alarm;
        color = Colors.blue;
        break;
      case NotificationType.newEpisode:
        icon = Icons.fiber_new;
        color = Colors.purple;
        break;
      case NotificationType.channelUpdate:
        icon = Icons.update;
        color = Colors.green;
        break;
      case NotificationType.general:
        icon = Icons.notifications;
        color = Colors.grey;
        break;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.showLive:
      case NotificationType.showUpcoming:
      case NotificationType.showReminder:
        if (notification.showId != null) {
          // Navigate to show/radio station
        }
        break;
      default:
        break;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
