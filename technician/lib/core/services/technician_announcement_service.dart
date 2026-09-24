import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician/technician_announcement.dart';

class TechnicianAnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TechnicianAnnouncement>> streamAnnouncementsForRadio(String radioId) {
    return _firestore
        .collection('announcements')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TechnicianAnnouncement.fromFirestore(doc.data(), doc.id);
      }).toList();

      list.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
      return list;
    });
  }

  Future<void> markAsAired({
    required String announcementId,
    required String technicianName,
    String? sessionId,
  }) async {
    final docRef = _firestore.collection('announcements').doc(announcementId);
    await docRef.update({
      'status': 'broadcasted',
      'isAired': true,
      'airedAt': FieldValue.serverTimestamp(),
      'airedBy': technicianName,
      'airedRole': 'technician',
      if (sessionId != null) 'injectedToSessionId': sessionId,
    });

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final listenerId = data['listenerId'] as String?;
        final cat = data['category'] ?? 'General';
        if (listenerId != null && listenerId.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': listenerId,
            'type': 'announcement_aired',
            'title': '🎉 Your Announcement Was Broadcasted!',
            'body': 'Your $cat announcement was successfully injected and broadcasted by our technical studio team.',
            'data': {
              'announcementId': announcementId,
              'airedAt': DateTime.now().toIso8601String(),
              'airedRole': 'technician',
            },
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {}
  }
}
