import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../technician_login_screen.dart';

class TechnicianSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String radioName;
  final String technicianName;

  const TechnicianSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.radioName,
    required this.technicianName,
  }) : super(key: key);

  @override
  State<TechnicianSidebar> createState() => _State();
}

class _State extends State<TechnicianSidebar> {
  bool _expanded = true;
  int? _hovered;

  final _items = const [
    _I(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _I(Icons.play_circle_outline, Icons.play_circle, 'Live sessions'),
    _I(Icons.calendar_view_week_outlined, Icons.calendar_view_week, 'Programming'),
    _I(Icons.groups_outlined, Icons.groups, 'Hosts'),
    _I(Icons.tv_outlined, Icons.tv, 'Programs'),
    _I(Icons.video_library_outlined, Icons.video_library, 'Media'),
    _I(Icons.analytics_outlined, Icons.analytics, 'Metrics'),
    _I(Icons.notifications_outlined, Icons.notifications, 'Notifications'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = _expanded ? 240.0 : 72.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: w,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_expanded ? 16 : 12, 20, 12, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_input_antenna,
                      color: AppColors.primary, size: 20),
                ),
                if (_expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Technician',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(widget.technicianName.isEmpty ? 'Staff' : widget.technicianName,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                        Text(widget.radioName.isEmpty ? 'RadioHub' : widget.radioName,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 18),
                    tooltip: 'Collapse',
                    onPressed: () => setState(() => _expanded = false),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (!_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  tooltip: 'Expand',
                  onPressed: () => setState(() => _expanded = true),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (_, i) => _tile(i),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _footer(Icons.settings_outlined, 'Settings', () => widget.onItemSelected(8), 8),
          _footer(Icons.logout, 'Logout', () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TechnicianLoginScreen()),
                (route) => false,
              );
            }
          }, 9, danger: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile(int i) {
    final it = _items[i];
    final sel = widget.selectedIndex == i;
    final hov = _hovered == i;
    final unreadCount =
        context.select<TechnicianViewModel, int>((vm) => vm.unreadNotifications);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = i),
      onExit: (_) => setState(() => _hovered = null),
      child: Tooltip(
        message: _expanded ? '' : it.label,
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: () => widget.onItemSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.symmetric(horizontal: _expanded ? 16 : 0, vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.primary.withOpacity(0.08)
                  : (hov ? AppColors.hover : Colors.transparent),
              border: Border(
                left: BorderSide(
                  color: sel ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: _expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      sel ? it.active : it.icon,
                      size: 20,
                      color: sel
                          ? AppColors.primary
                          : (hov ? AppColors.textPrimary : AppColors.textSecondary),
                    ),
                    if (!_expanded && it.label == 'Notifications' && unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: sel
                            ? AppColors.primary
                            : (hov ? AppColors.textPrimary : AppColors.textSecondary),
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (it.label == 'Notifications' && unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$unreadCount',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(IconData ic, String lbl, VoidCallback tap, int idx, {bool danger = false}) {
    final sel = widget.selectedIndex == idx;
    return InkWell(
      onTap: tap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _expanded ? 20 : 0, vertical: 12),
        child: Row(
          mainAxisAlignment: _expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(ic, size: 18,
                color: danger ? AppColors.error : (sel ? AppColors.primary : AppColors.textSecondary)),
            if (_expanded) ...[
              const SizedBox(width: 12),
              Text(lbl,
                  style: TextStyle(
                      fontSize: 13,
                      color: danger ? AppColors.error : AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

class _I {
  final IconData icon;
  final IconData active;
  final String label;
  const _I(this.icon, this.active, this.label);
}
