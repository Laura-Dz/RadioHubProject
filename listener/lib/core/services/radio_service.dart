import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/radio_model.dart';
import '../models/announcement_request_model.dart';

class RadioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RadioModel?> getRadioById(String radioId) async {
    try {
      final doc = await _firestore.collection('radios').doc(radioId).get();
      if (!doc.exists) return null;
      return RadioModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting radio: $e');
      return null;
    }
  }

  Future<void> toggleFollowRadio(String radioId, bool follow) async {
    try {
      await _firestore.collection('radios').doc(radioId).update({
        'isFollowed': follow,
        'followerCount': FieldValue.increment(follow ? 1 : -1),
      });
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  Future<AnnouncementPricing?> getPricing(String radioId) async {
    try {
      final snapshot = await _firestore
          .collection('announcement_pricing')
          .where('radioId', isEqualTo: radioId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return AnnouncementPricing.fromFirestore(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
    } catch (e) {
      print('Error getting pricing: $e');
      return null;
    }
  }

  Future<void> submitAnnouncementRequest(AnnouncementRequest request) async {
    try {
      await _firestore.collection('announcement_requests').doc(request.id).set({
        'radioId': request.radioId,
        'userId': request.userId,
        'userName': request.userName,
        'message': request.message,
        'category': request.category.toString().split('.').last,
        'durationSeconds': request.durationSeconds,
        'price': request.price,
        'status': request.status.toString().split('.').last,
        'scheduledTime': request.scheduledTime,
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': request.processedAt,
        'rejectionReason': request.rejectionReason,
      });
    } catch (e) {
      print('Error submitting announcement: $e');
      rethrow;
    }
  }

  Stream<RadioModel?> streamRadio(String radioId) {
    return _firestore
        .collection('radios')
        .doc(radioId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return RadioModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        });
  }
}
