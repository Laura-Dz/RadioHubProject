import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/call_model.dart';
import '../models/show_metrics_model.dart';

class HostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Comment>> streamComments(String programId) {
    return _firestore
        .collection('comments')
        .where('programId', isEqualTo: programId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  Stream<List<Call>> streamCalls(String programId) {
    return _firestore
        .collection('calls')
        .where('programId', isEqualTo: programId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Call.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  Stream<ShowMetrics> streamMetrics(String programId) {
    return _firestore
        .collection('show_metrics')
        .doc(programId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return ShowMetrics.empty();
      return ShowMetrics.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  Future<void> replyToComment(String commentId, String replyText) async {
    await _firestore.collection('comments').doc(commentId).update({
      'hostReply': replyText,
      'isReplied': true,
      'repliedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }
}
