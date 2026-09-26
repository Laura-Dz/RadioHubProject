import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:listener/core/theme/app_colors.dart';
import '../../widgets/notification_bell.dart';
import '../../notifications/notification_center.dart';
import '../../../view_models/user_interaction_view_model.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isStationPage;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.isStationPage,
    required this.onThemeToggle,
    required this.isDarkMode,
  }) : super(key: key);

  IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('home') || lower.contains('hub')) return Icons.radio;
    if (lower.contains('channel')) return Icons.grid_view;
    if (lower.contains('announcement')) return Icons.campaign;
    if (lower.contains('profile')) return Icons.person;
    if (lower.contains('notification')) return Icons.notifications;
    if (lower.contains('setting')) return Icons.settings;
    return Icons.radio;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isStationPage ? Icons.radio : _getIconForTitle(title),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (isStationPage) ...[
            const SizedBox(width: 6),
            const Icon(Icons.volume_up, size: 16, color: AppColors.secondary),
          ],
        ],
      ),
      centerTitle: false,
      titleSpacing: 16,
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(context),
          tooltip: 'Search',
        ),
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDarkMode ? Colors.amber : Colors.deepPurple,
          ),
          onPressed: onThemeToggle,
          tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
        ),
        Stack(
          children: [
            NotificationBell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenter(),
                  ),
                );
              },
            ),
            Selector<UserInteractionViewModel, int>(
              selector: (_, vm) => vm.unreadCount,
              builder: (context, count, child) {
                if (count > 0) {
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              children: [
                const Text('Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search shows, channels, hosts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (query) {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
