import 'package:flutter/material.dart';
import 'package:listener/core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStationPage) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                title,
                key: ValueKey<String>(title),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            if (isStationPage)
              Icon(Icons.volume_up, size: 16, color: AppColors.primary),
          ] else ...[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ],
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
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
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
