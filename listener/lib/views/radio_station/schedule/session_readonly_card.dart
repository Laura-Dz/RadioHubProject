import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/session_model.dart';
import '../../../core/constants/app_colors.dart';

class SessionReadonlyCard extends StatelessWidget {
  final SessionModel session;
  final bool compact;

  const SessionReadonlyCard({
    Key? key,
    required this.session,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visual = _visual();

    if (compact) return _compactCard(visual);
    return _fullCard(visual);
  }

  _Visual _visual() {
    switch (session.contentTag) {
      case 'live':
        return const _Visual(Color(0xFF22C55E), 'LIVE', Icons.circle);
      case 'rediffusion':
        return const _Visual(Color(0xFFD4A017), 'REDIFF', Icons.replay);
      case 'intermediary':
        return const _Visual(Color(0xFF8B5CF6), 'INTERM', Icons.queue_music);
      case 'special':
        return const _Visual(Color(0xFFEF4444), 'SPECIAL',
            Icons.celebration_outlined);
      case 'flash':
        return const _Visual(Color(0xFFEF4444), 'FLASH', Icons.bolt);
      case 'passed':
        return const _Visual(Color(0xFF9CA3AF), 'PASSED',
            Icons.check_circle_outline);
      default:
        return const _Visual(Color(0xFF3B82F6), 'PLAN', Icons.schedule);
    }
  }

  Widget _compactCard(_Visual v) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: v.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: v.color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${session.scheduledStart.hour.toString().padLeft(2, '0')}:${session.scheduledStart.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: v.color),
              ),
              const Spacer(),
              Icon(v.icon, size: 10, color: v.color),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            session.programName,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (session.hostName != null && session.hostName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              session.hostName!,
              style: const TextStyle(
                  fontSize: 9.5, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _fullCard(_Visual v) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: v.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: v.color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: v.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(v.icon, color: v.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: v.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(v.label,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: v.color,
                              letterSpacing: 0.3)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('HH:mm').format(session.scheduledStart)} – '
                      '${DateFormat('HH:mm').format(session.scheduledEnd)}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(session.programName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (session.hostName != null && session.hostName!.isNotEmpty)
                  Text(session.hostName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                if (session.thematic != null &&
                    session.thematic!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(session.thematic!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Visual {
  final Color color;
  final String label;
  final IconData icon;
  const _Visual(this.color, this.label, this.icon);
}
