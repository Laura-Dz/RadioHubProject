import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/director/technician_model.dart';
import '../models/director/subscription_model.dart';
import '../models/director/homepage_config_model.dart';
import '../models/director/request_model.dart';
import '../models/director/metric_model.dart';

class DirectorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Technician>> getTechnicians() async {
    final snapshot = await _firestore.collection('technicians').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Technician.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> addTechnician(Technician technician) async {
    await _firestore.collection('technicians').doc(technician.id).set(technician.toFirestore());
  }

  Future<void> updateTechnician(String id, Map<String, dynamic> data) async {
    await _firestore.collection('technicians').doc(id).update(data);
  }

  Future<void> deleteTechnician(String id) async {
    await _firestore.collection('technicians').doc(id).update({'status': 'inactive'});
  }

  Future<void> suspendTechnician(String id) async {
    await _firestore.collection('technicians').doc(id).update({'status': 'suspended'});
  }

  Future<void> activateTechnician(String id) async {
    await _firestore.collection('technicians').doc(id).update({'status': 'active'});
  }

  Stream<List<Technician>> streamTechnicians() {
    return _firestore.collection('technicians').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Technician.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<List<Subscription>> getSubscriptions() async {
    final snapshot = await _firestore.collection('subscriptions').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Subscription.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    await _firestore.collection('subscriptions').doc(id).update(data);
  }

  Future<void> createSubscription(Subscription subscription) async {
    await _firestore.collection('subscriptions').doc(subscription.id).set(subscription.toFirestore());
  }

  Stream<List<Subscription>> streamSubscriptions() {
    return _firestore.collection('subscriptions').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Subscription.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<HomepageConfig?> getHomepageConfig(String radioId) async {
    final snapshot = await _firestore
        .collection('homepage_configs')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return HomepageConfig.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<void> saveHomepageConfig(HomepageConfig config) async {
    await _firestore.collection('homepage_configs').doc(config.id).set(config.toFirestore());
  }

  Future<void> updateHomepageConfig(String id, Map<String, dynamic> data) async {
    await _firestore.collection('homepage_configs').doc(id).update(data);
  }

  Stream<HomepageConfig?> streamHomepageConfig(String radioId) {
    return _firestore
        .collection('homepage_configs')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return HomepageConfig.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
        });
  }

  Future<List<Request>> getRequests({RequestStatus? status, RequestType? type}) async {
    Query query = _firestore.collection('requests').orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Request.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> approveRequest(String id, {String? adminResponse}) async {
    await _firestore.collection('requests').doc(id).update({
      'status': 'approved',
      'adminResponse': adminResponse,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRequest(String id, {required String adminResponse}) async {
    await _firestore.collection('requests').doc(id).update({
      'status': 'rejected',
      'adminResponse': adminResponse,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRequestInProgress(String id) async {
    await _firestore.collection('requests').doc(id).update({'status': 'inProgress'});
  }

  Future<void> completeRequest(String id) async {
    await _firestore.collection('requests').doc(id).update({
      'status': 'completed',
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Request>> streamRequests() {
    return _firestore.collection('requests').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Request.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<DirectorMetrics> getMetrics(String radioId) async {
    final doc = await _firestore.collection('director_metrics').doc(radioId).get();
    if (!doc.exists) {
      return DirectorMetrics(
        totalListeners: 0,
        activeListeners: 0,
        totalShows: 0,
        activeShows: 0,
        totalTechnicians: 0,
        activeTechnicians: 0,
        totalSubscriptions: 0,
        activeSubscriptions: 0,
        revenue: 0.0,
        revenueGrowth: 0.0,
        engagementRate: 0.0,
        listenerGrowth: 0.0,
        pendingRequests: 0,
        totalRequests: 0,
        timestamp: DateTime.now(),
      );
    }
    return DirectorMetrics.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<DirectorMetrics> streamMetrics(String radioId) {
    return _firestore.collection('director_metrics').doc(radioId).snapshots().map((doc) {
      if (!doc.exists) {
        return DirectorMetrics(
          totalListeners: 0,
          activeListeners: 0,
          totalShows: 0,
          activeShows: 0,
          totalTechnicians: 0,
          activeTechnicians: 0,
          totalSubscriptions: 0,
          activeSubscriptions: 0,
          revenue: 0.0,
          revenueGrowth: 0.0,
          engagementRate: 0.0,
          listenerGrowth: 0.0,
          pendingRequests: 0,
          totalRequests: 0,
          timestamp: DateTime.now(),
        );
      }
      return DirectorMetrics.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }
}
