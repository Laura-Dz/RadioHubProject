import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician/program_model.dart';
import '../models/technician/session_model.dart';
import '../models/technician/host_model.dart';
import '../models/technician/media_model.dart';

class TechnicianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== PROGRAMS =====
  Future<List<Program>> getPrograms() async {
    final snapshot = await _firestore.collection('programs').get();
    return snapshot.docs
        .map((doc) => Program.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> createProgram(Program program) async {
    await _firestore.collection('programs').doc(program.id).set(program.toFirestore());
  }

  Future<void> updateProgram(Program program) async {
    await _firestore.collection('programs').doc(program.id).update(program.toFirestore());
  }

  Future<void> deleteProgram(String programId) async {
    await _firestore.collection('programs').doc(programId).delete();
  }

  Stream<List<Program>> streamPrograms() {
    return _firestore
        .collection('programs')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Program.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ===== HOSTS =====
  Future<List<Host>> getHosts() async {
    final snapshot = await _firestore.collection('hosts').get();
    return snapshot.docs
        .map((doc) => Host.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> createHost(Host host) async {
    await _firestore.collection('hosts').doc(host.id).set(host.toFirestore());
  }

  Future<void> updateHost(Host host) async {
    await _firestore.collection('hosts').doc(host.id).update(host.toFirestore());
  }

  Future<void> deleteHost(String hostId) async {
    await _firestore.collection('hosts').doc(hostId).delete();
  }

  Stream<List<Host>> streamHosts() {
    return _firestore.collection('hosts').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Host.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // ===== SESSIONS =====
  Future<List<Session>> getSessions() async {
    final snapshot = await _firestore.collection('sessions').get();
    return snapshot.docs
        .map((doc) => Session.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Session>> getLiveSessions() async {
    final snapshot = await _firestore
        .collection('sessions')
        .where('status', isEqualTo: 'live')
        .get();
    return snapshot.docs
        .map((doc) => Session.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Session>> getPastSessions() async {
    final snapshot = await _firestore
        .collection('sessions')
        .where('status', isEqualTo: 'ended')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Session.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> createSession(Session session) async {
    await _firestore.collection('sessions').doc(session.id).set(session.toFirestore());
  }

  Future<void> updateSession(Session session) async {
    await _firestore.collection('sessions').doc(session.id).update(session.toFirestore());
  }

  Future<void> startSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'live',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> pauseSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'paused',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> scheduleRediffusion({
    required String sessionId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final newDoc = _firestore.collection('sessions').doc();
    await newDoc.set({
      'status': 'rediffusion',
      'rediffusionSourceId': sessionId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Session>> streamSessions() {
    return _firestore.collection('sessions').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Session.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // ===== MEDIA =====
  Future<List<MediaItem>> getMediaItems({String? mediaType}) async {
    var query = _firestore.collection('media') as Query;
    if (mediaType != null && mediaType.isNotEmpty) {
      query = query.where('mediaType', isEqualTo: mediaType);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MediaItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> createMediaItem(MediaItem item) async {
    await _firestore.collection('media').doc(item.id).set(item.toFirestore());
  }

  Future<void> deleteMediaItem(String id) async {
    await _firestore.collection('media').doc(id).delete();
  }

  Stream<List<MediaItem>> streamMedia() {
    return _firestore.collection('media').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => MediaItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // ===== METRICS =====
  Future<Map<String, dynamic>> getLiveMetrics(String sessionId) async {
    final doc = await _firestore.collection('live_metrics').doc(sessionId).get();
    if (!doc.exists) return {};
    return doc.data() as Map<String, dynamic>;
  }
}
