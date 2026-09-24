import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _items = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _NavItem(Icons.card_membership_outlined, Icons.card_membership, 'Subscription'),
  _NavItem(Icons.groups_outlined, Icons.groups, 'Staff'),
  _NavItem(Icons.campaign_outlined, Icons.campaign, 'Announcements'),
  _NavItem(Icons.pages_outlined, Icons.pages, 'Radio Page'),
  _NavItem(Icons.analytics_outlined, Icons.analytics, 'Metrics & Audimat'),
  _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI Insights'),
  _NavItem(Icons.radio_outlined, Icons.radio, 'Programs'),
  _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Schedule'),
  _NavItem(Icons.video_library_outlined, Icons.video_library, 'Media Library'),
  _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Transactions'),
];

class RadioAdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String radioName;

  const RadioAdminSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.radioName,
  }) : super(key: key);

  @override
  State<RadioAdminSidebar> createState() => _RadioAdminSidebarState();
}

class _RadioAdminSidebarState extends State<RadioAdminSidebar> {
  bool _expanded = true;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _expanded ? 240.0 : 72.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (_, i) => _buildNavTile(i),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildFooterItem(Icons.settings_outlined, 'Settings', 11),
          _buildFooterItem(Icons.logout, 'Logout', 12, danger: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(_expanded ? 16 : 12, 18, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.radio, color: AppColors.primary, size: 20),
          ),
          if (_expanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Radio Admin',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(
                    widget.radioName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 18, color: AppColors.textSecondary),
              tooltip: 'Collapse',
              onPressed: () => setState(() => _expanded = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ] else
            Expanded(
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Expand',
                  onPressed: () => setState(() => _expanded = true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int i) {
    final item = _items[i];
    final selected = widget.selectedIndex == i;
    final hovered = _hoveredIndex == i;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = i),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Tooltip(
        message: _expanded ? '' : item.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.onItemSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: EdgeInsets.symmetric(
              horizontal: _expanded ? 12 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.08)
                  : (hovered ? AppColors.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: _expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : (hovered ? AppColors.textPrimary : AppColors.textSecondary),
                ),
                if (_expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : (hovered ? AppColors.textPrimary : AppColors.textSecondary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label, int idx, {bool danger = false}) {
    final hovered = _hoveredIndex == idx;
    final color = danger ? AppColors.error : (hovered ? AppColors.primary : AppColors.textSecondary);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = idx),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Tooltip(
        message: _expanded ? '' : label,
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.onItemSelected(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: _expanded ? 12 : 0, vertical: 10),
            decoration: BoxDecoration(
              color: hovered ? (danger ? AppColors.error.withOpacity(0.06) : AppColors.hover) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: _expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                if (_expanded) ...[
                  const SizedBox(width: 12),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w500, color: color)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
