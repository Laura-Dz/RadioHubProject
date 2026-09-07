import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/host_view_model.dart';
import 'widgets/metrics_card.dart';
import 'widgets/call_queue.dart';
import 'widgets/comment_feed.dart';
import 'widgets/reply_bar.dart';

class HostLiveStudio extends StatelessWidget {
  const HostLiveStudio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HostViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🎙️ Host Dashboard – Morning Drive'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 10),
                SizedBox(width: 4),
                Text(
                  'ON AIR',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⏱️ ${viewModel.metrics.duration}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: Row(
        children: [
          // LEFT COLUMN
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Metrics Card (Top)
                  MetricsCard(
                    metrics: viewModel.metrics,
                    onAnalyticsTap: viewModel.navigateToAnalytics,
                  ),
                  const SizedBox(height: 16),
                  // Call Queue (Bottom)
                  Expanded(
                    child: CallQueue(
                      calls: viewModel.calls,
                      onAccept: viewModel.acceptCall,
                      onDecline: viewModel.declineCall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Separator
          Container(width: 1, color: Colors.grey.shade300),
          // RIGHT COLUMN
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Comments Feed
                Expanded(
                  child: CommentFeed(
                    comments: viewModel.comments,
                    onCommentLongPress: viewModel.startReplyMode,
                  ),
                ),
                // Reply Bar (shown when in reply mode)
                if (viewModel.isReplyMode)
                  ReplyBar(
                    commentAuthor: viewModel.selectedComment?.listenerName ?? 'Listener',
                    onSubmit: viewModel.submitReply,
                    onCancel: viewModel.exitReplyMode,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
