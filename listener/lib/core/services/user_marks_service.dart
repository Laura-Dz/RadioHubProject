import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_mark.dart';

class UserMarksService {
  final _db = FirebaseFirestore.instance;

  Stream<Set<String>> streamMarksOfType(String uid, MarkType type) {
    return _db
        .collection('user_marks')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: type.name)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['targetId'].toString()).toSet());
  }

  Stream<List<UserMark>> streamAllMarks(String uid) {
    return _db
        .collection('user_marks')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              return UserMark(
                id: d.id,
                userId: (data['userId'] ?? '').toString(),
                type: MarkType.values.firstWhere(
                  (e) => e.name == data['type'],
                  orElse: () => MarkType.favouriteProgram,
                ),
                targetId: (data['targetId'] ?? '').toString(),
                radioId: (data['radioId'] ?? '').toString(),
                radioName: data['radioName']?.toString(),
                targetName: data['targetName']?.toString(),
                reminderAt: (data['reminderAt'] as Timestamp?)?.toDate().toLocal(),
                createdAt: (data['createdAt'] as Timestamp?)?.toDate().toLocal() ??
                    DateTime.now(),
              );
            }).toList());
  }

  Future<void> toggle({
    required String uid,
    required MarkType type,
    required String targetId,
    required String radioId,
    String? radioName,
    String? targetName,
    DateTime? reminderAt,
  }) async {
    final id = UserMark.buildId(uid, type, targetId);
    final ref = _db.collection('user_marks').doc(id);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': uid,
        'type': type.name,
        'targetId': targetId,
        'radioId': radioId,
        'radioName': radioName,
        'targetName': targetName,
        'reminderAt':
            reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
