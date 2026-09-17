import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';
import '../models/timetable_slot.dart';
import '../models/host.dart';
import '../models/program.dart';

class RadioScheduleService {
  final _db = FirebaseFirestore.instance;

  /// Sessions for a radio within a date range.
  Stream<List<SessionModel>> streamSessionsInRange({
    required String radioId,
    required DateTime from,
    required DateTime to,
  }) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('scheduledStart',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('scheduledStart', isLessThan: Timestamp.fromDate(to))
        .orderBy('scheduledStart')
        .snapshots()
        .map((s) => s.docs
            .map((d) => SessionModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// All active timetable slots for a radio.
  Stream<List<TimetableSlot>> streamTimetable(String radioId) {
    return _db
        .collection('timetable')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => TimetableSlot.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        if (a.weekday != b.weekday) return a.weekday.compareTo(b.weekday);
        if (a.startHour != b.startHour) return a.startHour.compareTo(b.startHour);
        return a.startMinute.compareTo(b.startMinute);
      });
      return list;
    });
  }

  /// All active hosts of a radio.
  Stream<List<Host>> streamHosts(String radioId) {
    return _db
        .collection('users')
        .where('radioId', isEqualTo: radioId)
        .where('role', isEqualTo: 'host')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => Host.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Programs a given host presents on this radio.
  Stream<List<Program>> streamProgramsByHost({
    required String radioId,
    required String hostId,
  }) {
    return _db
        .collection('programs')
        .where('radioId', isEqualTo: radioId)
        .where('hostIds', arrayContains: hostId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Program.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// All active programs for a radio.
  Stream<List<Program>> streamPrograms(String radioId) {
    return _db
        .collection('programs')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Program.fromFirestore(d.data(), d.id))
            .toList());
  }
}
