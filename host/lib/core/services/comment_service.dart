import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import 'cloud_function_caller.dart';

class CommentService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Comment>> streamComments(String sessionId) {
    return _db
        .collection('comments')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Comment.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> setReplying(String commentId, bool replying) async {
    try {
      await CloudFunctionCaller.call('setCommentReplying', {
        'commentId': commentId,
        'replying': replying,
      });
    } catch (e) {
      debugPrint('setReplying cloud function fallback: $e');
      // Direct Firestore update fallback
      try {
        await _db.collection('comments').doc(commentId).update({
          'status': replying ? 'replying' : 'pending',
          'replyingSince': replying ? FieldValue.serverTimestamp() : null,
          'replyingAt': replying ? FieldValue.serverTimestamp() : null,
        });
      } catch (dbErr) {
        debugPrint('Direct firestore comment update error: $dbErr');
      }
    }
  }

  Future<void> reply(String commentId, String reply) async {
    try {
      final res = await CloudFunctionCaller.call('replyToComment', {
        'commentId': commentId,
        'reply': reply,
      });
      if (res['success'] != true) {
        throw Exception('Reply rejected: ${res['reason'] ?? 'unknown'}');
      }
    } catch (e) {
      debugPrint('replyToComment cloud function fallback: $e');
      // Direct Firestore update fallback
      try {
        await _db.collection('comments').doc(commentId).update({
          'hostReply': reply,
          'hostReplyAt': FieldValue.serverTimestamp(),
          'replyingSince': null,
          'replyText': reply,
          'status': 'replied',
          'repliedAt': FieldValue.serverTimestamp(),
        });
      } catch (dbErr) {
        debugPrint('Direct firestore comment reply error: $dbErr');
        rethrow;
      }
    }
  }

  Future<void> markReplied(String commentId) async {
    try {
      await _db.collection('comments').doc(commentId).update({
        'status': 'replied',
        'isReplied': true,
        'isReplying': false,
        'replyingSince': null,
        'repliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Direct firestore markReplied error: $e');
    }
  }
}
