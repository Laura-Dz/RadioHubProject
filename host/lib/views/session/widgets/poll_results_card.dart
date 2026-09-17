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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_outlined,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('POLL LIVE',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.6)),
              const Spacer(),
              Text('${poll.totalVotes} votes',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(poll.question,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          ...poll.options.map((o) {
            final pct = poll.pctFor(o.index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.text,
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
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
              icon: const Icon(Icons.stop, size: 14),
              label: const Text('Close poll'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
