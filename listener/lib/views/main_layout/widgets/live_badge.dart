import 'package:flutter/material.dart';
import '../../../core/models/session_model.dart';
import '../../../core/theme/app_colors.dart';

Widget buildSessionBadge(Session session) {
  return buildBadgeForTag(session.displayTag);
}

Widget buildBadgeForTag(String displayTag) {
  switch (displayTag.toUpperCase()) {
    case 'REDIFFUSION':
      return _badge(
        label: 'REDIFFUSION',
        color: const Color(0xFFD4A017), // gold
        icon: Icons.replay,
        pulse: false,
      );
    case 'LIVE':
      return _badge(
        label: 'LIVE',
        color: const Color(0xFF22C55E), // green
        icon: Icons.circle,
        pulse: true,
      );
    case 'UPCOMING':
      return _badge(
        label: 'UPCOMING',
        color: const Color(0xFF3B82F6), // blue
        icon: Icons.schedule,
        pulse: false,
      );
    case 'ENDED':
      return _badge(
        label: 'ENDED',
        color: const Color(0xFF9CA3AF), // grey
        icon: Icons.check_circle_outline,
        pulse: false,
      );
    case 'CANCELLED':
      return _badge(
        label: 'CANCELLED',
        color: const Color(0xFFEF4444), // red
        icon: Icons.cancel_outlined,
        pulse: false,
      );
    default:
      return const SizedBox.shrink();
  }
}

Widget _badge({
  required String label,
  required Color color,
  required IconData icon,
  required bool pulse,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pulse)
          _PulsingDot(color: color)
        else
          Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  final bool isSmall;
  final bool isTrending;
  final String? label;
  final String? tag;
  final Session? session;

  const LiveBadge({
    Key? key,
    this.isSmall = false,
    this.isTrending = false,
    this.label,
    this.tag,
    this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return buildSessionBadge(session!);
    }

    if (tag != null) {
      return buildBadgeForTag(tag!);
    }

    if (isTrending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label ?? '🔥',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return buildBadgeForTag(label ?? 'LIVE');
  }
}
