import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_interaction_view_model.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBell({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserInteractionViewModel>();

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onTap,
          tooltip: 'Notifications',
        ),
        if (viewModel.unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  viewModel.unreadCount > 9 ? '9+' : '${viewModel.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
