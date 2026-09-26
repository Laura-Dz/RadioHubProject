import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/station_media_model.dart';

class StationMediaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<StationMediaModel>> streamStationMedia(String radioId) {
    return _firestore
        .collection('media')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((doc) => StationMediaModel.fromFirestore(doc.data(), doc.id))
              .toList();
          items.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return items;
        })
        .handleError((error) {
          debugPrint('Error streaming station media: $error');
          return <StationMediaModel>[];
        });
  }

  Future<void> incrementPlayCount(String mediaId) async {
    try {
      await _firestore.collection('media').doc(mediaId).update({
        'playCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error updating media play count: $e');
    }
  }
}
