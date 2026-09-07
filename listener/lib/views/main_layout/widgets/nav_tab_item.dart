import 'package:flutter/material.dart';
import '../../../core/enums/navigation_tabs.dart';
import '../../../core/theme/app_colors.dart';

class NavTabItem extends StatelessWidget {
  final NavigationTabs tab;
  final bool isSelected;
  final VoidCallback onTap;

  const NavTabItem({
    Key? key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(tab, isSelected),
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.5),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NavigationTabs tab, bool isSelected) {
    switch (tab) {
      case NavigationTabs.home:
        return isSelected ? Icons.home : Icons.home_outlined;
      case NavigationTabs.channels:
        return isSelected ? Icons.radio_button_checked : Icons.radio_button_off;
      case NavigationTabs.schedule:
        return isSelected ? Icons.calendar_today : Icons.calendar_today_outlined;
      case NavigationTabs.timetable:
        return isSelected ? Icons.event : Icons.event_outlined;
      case NavigationTabs.profile:
        return isSelected ? Icons.person : Icons.person_outline;
      case NavigationTabs.settings:
        return isSelected ? Icons.settings : Icons.settings_outlined;
    }
  }
}
