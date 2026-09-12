import 'package:flutter/material.dart';
import '../../../core/enums/navigation_tabs.dart';
import '../../../core/theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final NavigationTabs currentTab;
  final Function(NavigationTabs) onTabSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.currentTab,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              tab: NavigationTabs.home,
            ),
            _buildNavItem(context,
              icon: Icons.radio_button_off,
              activeIcon: Icons.radio_button_checked,
              label: 'Channels',
              tab: NavigationTabs.channels,
            ),
            _buildNavItem(context,
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              label: 'Schedule',
              tab: NavigationTabs.schedule,
            ),
            _buildNavItem(context,
              icon: Icons.event_outlined,
              activeIcon: Icons.event,
              label: 'Timetable',
              tab: NavigationTabs.timetable,
            ),
            _buildNavItem(context,
              icon: Icons.campaign_outlined,
              activeIcon: Icons.campaign,
              label: 'Announce',
              tab: NavigationTabs.announcements,
            ),
            _buildNavItem(context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              tab: NavigationTabs.profile,
            ),

            _buildNavItem(context,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              tab: NavigationTabs.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required NavigationTabs tab,
  }) {
    final isSelected = currentTab == tab;
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabSelected(tab),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? AppColors.primary
                        : theme.bottomNavigationBarTheme.unselectedItemColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : theme.bottomNavigationBarTheme.unselectedItemColor,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
