import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sysadmin/server_model.dart';
import '../models/sysadmin/backup_model.dart';
import '../models/sysadmin/security_log_model.dart';
import '../models/sysadmin/deployment_model.dart';

class SysAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Server>> getServers() async {
    final snapshot = await _firestore.collection('servers').get();
    return snapshot.docs.map((doc) => Server.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> updateServer(String id, Map<String, dynamic> data) async {
    await _firestore.collection('servers').doc(id).update(data);
  }

  Future<void> restartServer(String id) async {
    await _firestore.collection('servers').doc(id).update({
      'status': 'restarting',
      'lastRestart': FieldValue.serverTimestamp(),
    });
    Future.delayed(const Duration(seconds: 10), () {
      _firestore.collection('servers').doc(id).update({'status': 'running'});
    });
  }

  Stream<List<Server>> streamServers() {
    return _firestore.collection('servers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Server.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<List<Backup>> getBackups() async {
    final snapshot = await _firestore.collection('backups').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Backup.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> createBackup(Backup backup) async {
    await _firestore.collection('backups').doc(backup.id).set(backup.toFirestore());
  }

  Future<void> deleteBackup(String id) async {
    await _firestore.collection('backups').doc(id).delete();
  }

  Future<void> restoreBackup(String id) async {
    await _firestore.collection('backups').doc(id).update({'status': 'restoring'});
    Future.delayed(const Duration(seconds: 30), () {
      _firestore.collection('backups').doc(id).update({'status': 'completed'});
    });
  }

  Stream<List<Backup>> streamBackups() {
    return _firestore.collection('backups').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Backup.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<List<SecurityLog>> getSecurityLogs({int limit = 100}) async {
    final snapshot = await _firestore
        .collection('security_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => SecurityLog.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> addSecurityLog(SecurityLog log) async {
    await _firestore.collection('security_logs').doc(log.id).set(log.toFirestore());
  }

  Stream<List<SecurityLog>> streamSecurityLogs() {
    return _firestore
        .collection('security_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SecurityLog.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<List<Deployment>> getDeployments() async {
    final snapshot = await _firestore.collection('deployments').orderBy('startedAt', descending: true).get();
    return snapshot.docs.map((doc) => Deployment.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<void> triggerDeployment(Deployment deployment) async {
    await _firestore.collection('deployments').doc(deployment.id).set(deployment.toFirestore());
    _simulateDeployment(deployment.id);
  }

  void _simulateDeployment(String deploymentId) {
    int step = 0;
    final steps = ['building', 'testing', 'deploying', 'verifying', 'completed'];
    final interval = const Duration(seconds: 5);

    void updateStatus() {
      if (step < steps.length) {
        _firestore.collection('deployments').doc(deploymentId).update({
          'status': steps[step],
          'progress': ((step + 1) / steps.length * 100).toInt(),
        });
        step++;
        Future.delayed(interval, updateStatus);
      }
    }
    Future.delayed(const Duration(seconds: 2), updateStatus);
  }

  Stream<List<Deployment>> streamDeployments() {
    return _firestore.collection('deployments').orderBy('startedAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Deployment.fromFirestore(doc.data(), doc.id)).toList());
  }
}
