import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../view_models/host_view_model.dart';
import '../../../core/models/poll.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloud_function_caller.dart';
import '../../../core/services/realtime_database_service.dart';

class PollResultsCard extends StatelessWidget {
  const PollResultsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();
    final sessionId = vm.session?.id;
    if (sessionId == null) return const SizedBox.shrink();

    // 1. Stream active poll from Realtime Database (WebSocket - instant vote tally)
    return StreamBuilder<DatabaseEvent>(
      stream: RealtimeDatabaseService.database
          .ref('polls/$sessionId')
          .onValue,
      builder: (context, snap) {
        if (snap.hasData &&
            snap.data!.snapshot.value != null &&
            snap.data!.snapshot.value is Map) {
          final map = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
          final status = map['status']?.toString();
          if (status == 'active' || status == null) {
            final poll = Poll.fromMap(map, map['id']?.toString() ?? sessionId);
            return _card(context, poll, sessionId);
          }
        }

        // 2. Fallback to Firestore if RTDB does not have active poll
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('polls')
              .where('sessionId', isEqualTo: sessionId)
              .snapshots(),
          builder: (context, firestoreSnap) {
            if (!firestoreSnap.hasData) {
              return const SizedBox.shrink();
            }
            final activeDocs = firestoreSnap.data!.docs
                .where((d) => (d.data() as Map<String, dynamic>?)?['status'] == 'active')
                .toList();
            if (activeDocs.isEmpty) {
              return const SizedBox.shrink();
            }
            final poll = Poll.fromFirestore(
                activeDocs.first.data() as Map<String, dynamic>,
                activeDocs.first.id);
            return _card(context, poll, sessionId);
          },
        );
      },
    );
  }

  Widget _card(BuildContext context, Poll poll, String sessionId) {
    // Find the highest vote count to highlight the leader
    int maxVotes = 0;
    for (final o in poll.options) {
      final c = poll.countFor(o.index);
      if (c > maxVotes) maxVotes = c;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('LIVE POLL • REALTIME',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${poll.totalVotes} total votes',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(poll.question,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 16),
          ...poll.options.map((o) {
            final pct = poll.pctFor(o.index);
            final count = poll.countFor(o.index);
            final isLeader = maxVotes > 0 && count == maxVotes;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLeader) ...[
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          o.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isLeader ? FontWeight.w700 : FontWeight.w500,
                            color: isLeader ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '$count vote${count == 1 ? '' : 's'} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLeader ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: pct),
                      builder: (context, val, _) {
                        return LinearProgressIndicator(
                          value: val,
                          minHeight: 8,
                          backgroundColor: AppColors.border.withOpacity(0.4),
                          color: isLeader ? AppColors.primary : AppColors.primary.withOpacity(0.55),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                // 1. Instant close in Realtime Database (WebSocket pushes to listeners)
                try {
                  await RealtimeDatabaseService.database
                      .ref('polls/$sessionId')
                      .update({'status': 'closed'});
                } catch (e) {
                  debugPrint('RTDB closePoll error: $e');
                }

                // 2. Cloud Function & Firestore update
                try {
                  await CloudFunctionCaller.call('closePoll', {'pollId': poll.id});
                } catch (e) {
                  debugPrint('closePoll CloudFunction error ($e), falling back to Firestore...');
                  try {
                    await FirebaseFirestore.instance
                        .collection('polls')
                        .doc(poll.id)
                        .update({'status': 'closed'});
                  } catch (dbErr) {
                    debugPrint('closePoll direct firestore error: $dbErr');
                  }
                }
              },
              icon: const Icon(Icons.stop_circle_outlined, size: 16),
              label: const Text('End & close poll'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
