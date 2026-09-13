import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit_note,
                                size: 12, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Replying',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      )
                    else if (c.isReplied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check,
                                size: 12, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Replied',
                                style: TextStyle(
                                    fontSize: 10.5,
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
                if (c.hostReply != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.reply,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('You replied',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                      letterSpacing: 0.3)),
                              const SizedBox(height: 2),
                              Text(c.hostReply!,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
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

  Future<void> _onTap(BuildContext context) async {
    final vm = context.read<HostViewModel>();
    if (widget.isReplying) {
      await vm.cancelReplying();
    } else {
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
