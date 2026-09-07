import 'package:flutter/material.dart';
import '../../../core/services/schedule_service.dart';

class CommentsSection extends StatefulWidget {
  final String radioId;
  final String? programId;

  const CommentsSection({Key? key, required this.radioId, this.programId}) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  final ScheduleService _scheduleService = ScheduleService();

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
          const Text('💬 Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<List<Comment>>(
            stream: _scheduleService.streamComments(widget.programId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error loading comments');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final comments = snapshot.data!;
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
                    subtitle: Text(comment.text),
                    trailing: Text(
                      _formatTime(comment.createdAt),
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
                    hintText: 'Write a comment...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) => _sendComment(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendComment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendComment() async {
    if (_controller.text.isEmpty || widget.programId == null) return;
    try {
      await _scheduleService.addComment(
        widget.programId!,
        'dummy_user',
        'You',
        _controller.text,
      );
      _controller.clear();
    } catch (e) {
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
