import 'package:flutter/material.dart';
import '../../../core/models/comment_model.dart';

class CommentFeed extends StatelessWidget {
  final List<Comment> comments;
  final Function(Comment) onCommentLongPress;

  const CommentFeed({
    Key? key,
    required this.comments,
    required this.onCommentLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '💬 Comments Feed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${comments.length} comments',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    reverse: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _commentTile(comment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _commentTile(Comment comment) {
    return GestureDetector(
      onLongPress: () => onCommentLongPress(comment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: comment.isReplied ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: comment.isReplied ? Colors.green.shade300 : Colors.grey.shade200,
            width: comment.isReplied ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    comment.listenerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  comment.listenerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(comment.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (comment.isReplied)
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
              ],
            ),
            const SizedBox(height: 4),
            Text(comment.text, style: const TextStyle(fontSize: 14)),
            if (comment.hostReply != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        comment.hostReply!,
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!comment.isReplied)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Hold to reply →',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
