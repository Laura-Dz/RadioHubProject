import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/realtime_database_service.dart';
import '../../../core/models/live_comment_model.dart';

class CommentsSection extends StatefulWidget {
  final String radioId;
  final String? programId;

  const CommentsSection({Key? key, required this.radioId, this.programId}) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.programId == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No program to comment on.')),
      );
    }

    final realtimeDb = context.watch<RealtimeDatabaseService>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬 Live Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: realtimeDb.streamComments(widget.programId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error loading comments');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final comments = snapshot.data!
                  .map((m) => LiveComment.fromMap(m))
                  .toList();
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No comments yet. Be the first!')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(comment.userName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(comment.message),
                    trailing: Text(
                      _formatTime(comment.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Write a live comment...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) => _sendComment(realtimeDb),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _sendComment(realtimeDb),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendComment(RealtimeDatabaseService realtimeDb) async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.programId == null) return;
    try {
      await realtimeDb.addComment(
        programId: widget.programId!,
        userId: 'current_user',
        userName: 'You',
        message: text,
      );
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment')),
      );
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
