import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/poll.dart';
import '../../../core/constants/app_colors.dart';

class PollVoteSheet extends StatelessWidget {
  const PollVoteSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final poll = vm.activePoll;

    if (poll == null) {
      return const SizedBox.shrink();
    }

    final height = MediaQuery.of(context).size.height * 0.65;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.poll_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Live poll',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.question,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  if (vm.hasVoted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${poll.totalVotes} ${poll.totalVotes == 1 ? "person" : "people"} answered',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...poll.options.map((o) => _option(
                        context,
                        vm,
                        poll,
                        o,
                      )),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${poll.totalVotes} ${poll.totalVotes == 1 ? "person" : "people"} answered',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      if (poll.closesAt != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(_remaining(poll),
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(
      BuildContext context, RadioStationViewModel vm, Poll poll, PollOption o) {
    final hasVoted = vm.hasVoted;
    final isMyChoice = vm.myVoteIndex == o.index;
    final pct = poll.pctFor(o.index);
    final count = poll.countFor(o.index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: hasVoted
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: hasVoted ? null : () => vm.voteOnPoll(o.index),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMyChoice
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMyChoice ? AppColors.primary : AppColors.border,
                width: isMyChoice ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isMyChoice) ...[
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(o.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isMyChoice
                                ? FontWeight.w700
                                : FontWeight.w500,
                          )),
                    ),
                    if (hasVoted)
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                  ],
                ),
                if (hasVoted) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: isMyChoice
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$count ${count == 1 ? "person" : "people"} answered (${(pct * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isMyChoice ? FontWeight.w600 : FontWeight.w400,
                          color: isMyChoice ? AppColors.primary : AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _remaining(Poll p) {
    if (p.closesAt == null) return '';
    final d = p.closesAt!.difference(DateTime.now());
    if (d.isNegative) return 'closing';
    if (d.inMinutes < 1) return '${d.inSeconds}s left';
    return '${d.inMinutes}m left';
  }
}
