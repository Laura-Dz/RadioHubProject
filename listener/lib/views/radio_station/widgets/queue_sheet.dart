import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/session_model.dart';
import '../../../core/constants/app_colors.dart';

class QueueSheet extends StatelessWidget {
  final SessionModel? liveSession;
  final List<SessionModel> upcomingSessions;

  const QueueSheet({
    Key? key,
    required this.liveSession,
    required this.upcomingSessions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.queue_music,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Next 24 hours',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: (liveSession == null && upcomingSessions.isEmpty)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No sessions in the next 24 hours',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (liveSession != null) ...[
                        _sectionLabel('On air now'),
                        _sessionRow(context, liveSession!, isLive: true),
                        const SizedBox(height: 16),
                      ],
                      if (upcomingSessions.isNotEmpty) ...[
                        _sectionLabel('Next'),
                        ...upcomingSessions.map(
                            (s) => _sessionRow(context, s, isLive: false)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.6)),
      );

  Widget _sessionRow(BuildContext context, SessionModel s,
      {required bool isLive}) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLive
              ? AppColors.error.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive
                ? AppColors.error.withOpacity(0.4)
                : AppColors.border,
            width: isLive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(s.scheduledStart),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isLive ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(s.scheduledEnd),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(s.programName,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (s.isRediffusion) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('REDIFF',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    (s.hostName != null && s.hostName!.isNotEmpty)
                        ? s.hostName!
                        : 'No host',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (s.thematic != null && s.thematic!.isNotEmpty)
                    Text(
                      s.thematic!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
