import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/comment.dart';
import '../../../view_models/host_view_model.dart';

class CommentCard extends StatefulWidget {
  final Comment comment;
  final bool isReplying;
  const CommentCard({
    Key? key,
    required this.comment,
    required this.isReplying,
  }) : super(key: key);

  @override
  State<CommentCard> createState() => _State();
}

class _State extends State<CommentCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: c.isReplied ? null : () => _onTap(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isReplying
                  ? AppColors.primary.withOpacity(0.06)
                  : (_hover ? AppColors.hover : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isReplying
                    ? AppColors.primary.withOpacity(0.5)
                    : (_hover ? AppColors.primary.withOpacity(0.2) : AppColors.border),
                width: widget.isReplying ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          c.userName.isNotEmpty
                              ? c.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.userName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text(_timeAgo(c.createdAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (c.isReplying)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mic,
                                size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Replying On Air',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      )
                    else if (c.isReplied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle,
                                size: 13, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Replied',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(c.text,
                    style: const TextStyle(fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 12),
                // Audio reply state action bar
                if (c.isReplying || widget.isReplying)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _markReplied(context),
                        icon: const Icon(Icons.check_circle_outline, size: 15),
                        label: const Text('Mark as Answered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => context.read<HostViewModel>().cancelReplying(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  )
                else if (!c.isReplied)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _startReplying(context),
                      icon: const Icon(Icons.mic, size: 14),
                      label: const Text('Answer On Air'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startReplying(BuildContext context) async {
    final vm = context.read<HostViewModel>();
    await vm.startReplying(widget.comment);
  }

  Future<void> _markReplied(BuildContext context) async {
    final vm = context.read<HostViewModel>();
    await vm.markCommentReplied(widget.comment);
  }

  Future<void> _onTap(BuildContext context) async {
    final vm = context.read<HostViewModel>();
    if (widget.comment.isReplying || widget.isReplying) {
      await vm.markCommentReplied(widget.comment);
    } else if (!widget.comment.isReplied) {
      await vm.startReplying(widget.comment);
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}
