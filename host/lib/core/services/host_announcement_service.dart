import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/host_announcement.dart';

class HostAnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream announcements scheduled for a radio and matching the current active show
  Stream<List<HostAnnouncement>> streamAnnouncementsForShow({
    required String radioId,
    required String programName,
    String? showId,
  }) {
    return _firestore
        .collection('announcements')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return HostAnnouncement.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Filter to scheduled or recently broadcasted announcements
      // that are routed to this show or high priority
      final matched = list.where((a) {
        if (a.status != 'scheduled' && a.status != 'broadcasted' && a.status != 'aired') {
          return false;
        }

        // If assignedSlots contains a slot with slotType == 'within' for this show
        final hasShowSlot = a.assignedSlots.any((slot) {
          final matchesShow = (slot.showName != null &&
                  slot.showName!.toLowerCase() == programName.toLowerCase()) ||
              (showId != null && slot.showId == showId);
          return slot.slotType == 'within' && matchesShow;
        });

        if (hasShowSlot) return true;

        // If high or priority, and no explicit slot restriction or within shows
        if (a.priority.toLowerCase() == 'high' || a.priority.toLowerCase() == 'priority') {
          // If assignedSlots is empty or any within slot
          if (a.assignedSlots.isEmpty ||
              a.assignedSlots.any((s) => s.slotType == 'within')) {
            return true;
          }
        }

        return false;
      }).toList();

      // Sort by scheduledFor ascending
      matched.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
      return matched;
    });
  }

  /// Mark the announcement as aired on live broadcast
  Future<void> markAsAired({
    required String announcementId,
    required String hostName,
    String? programName,
  }) async {
    final docRef = _firestore.collection('announcements').doc(announcementId);
    await docRef.update({
      'status': 'broadcasted',
      'isAired': true,
      'airedAt': FieldValue.serverTimestamp(),
      'airedBy': hostName,
      'airedProgram': programName,
    });

    // Also record an audit / confirmation in notifications for the listener
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
            'title': '🎉 Your Announcement Was Just Aired!',
            'body': 'Your $cat announcement was read live on-air by $hostName${programName != null ? " on $programName" : ""}!',
            'data': {
              'announcementId': announcementId,
              'airedAt': DateTime.now().toIso8601String(),
              'hostName': hostName,
            },
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {}
  }
}
