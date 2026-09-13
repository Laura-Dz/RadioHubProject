import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/host_view_model.dart';
import 'comment_card.dart';
import 'reply_bar.dart';

class CommentsColumn extends StatelessWidget {
  const CommentsColumn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();
    final replying = vm.comments.any((c) => c.id == vm.replyingToId);

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.forum_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Live comments',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${vm.comments.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                const Text(
                  'Tap a comment to reply',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // List
          Expanded(
            child: vm.comments.isEmpty
                ? const _EmptyComments()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: vm.comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final c = vm.comments[i];
                      return CommentCard(
                        comment: c,
                        isReplying: c.id == vm.replyingToId,
                      );
                    },
                  ),
          ),

          // Reply bar
          if (replying) const ReplyBar(),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('No comments yet',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Listener comments will appear here in real time',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
