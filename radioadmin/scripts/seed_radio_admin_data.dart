import 'package:cloud_firestore/cloud_firestore.dart';

class SeedRadioAdminData {
  final _db = FirebaseFirestore.instance;

  Future<void> seedAll(String radioId, String radioName) async {
    print('🔥 Seeding Radio Admin data for $radioName ($radioId)...');
    await _seedSubscription(radioId);
    await _seedTariffs(radioId);
    await _seedStaff(radioId);
    await _seedAnnouncements(radioId, radioName);
    await _seedTransactions(radioId, radioName);
    print('✅ Radio Admin seeding completed!');
  }

  Future<void> _seedSubscription(String radioId) async {
    final now = DateTime.now();
    await _db.collection('subscriptions').add({
      'radioId': radioId,
      'amount': 30000.0,
      'periodDays': 30,
      'status': 'active',
      'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 23))),
      'paidAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      'paymentMethod': 'MoMo',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _seedTariffs(String radioId) async {
    const categories = ['general', 'birthday', 'anniversary', 'congratulations',
      'condolence', 'promotional', 'event', 'dedication', 'other'];
    for (var i = 0; i < categories.length; i++) {
      await _db.collection('announcement_tariffs').add({
        'radioId': radioId,
        'category': categories[i],
        'ratePerSecond': 50.0 + i * 10,
        'ratePerWord': 5.0 + i * 0.5,
        'diffusionMultiplier': 1.0 + i * 0.1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedStaff(String radioId) async {
    final staff = [
      {'name': 'Sarah Johnson', 'email': 'sarah@radio.com', 'phone': '+237600000001', 'role': 'host'},
      {'name': 'Mike Chen', 'email': 'mike@radio.com', 'phone': '+237600000002', 'role': 'host'},
      {'name': 'David Brown', 'email': 'david@radio.com', 'phone': '+237600000003', 'role': 'technician'},
      {'name': 'Chris Green', 'email': 'chris@radio.com', 'phone': '+237600000004', 'role': 'technician'},
    ];
    for (final s in staff) {
      await _db.collection('users').add({
        'displayName': s['name'],
        'email': s['email'],
        'phone': s['phone'],
        'radioId': radioId,
        'role': s['role'],
        'status': 'active',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedAnnouncements(String radioId, String radioName) async {
    final samples = [
      {
        'listenerName': 'John Smith',
        'listenerEmail': 'john@example.com',
        'category': 'birthday',
        'finalText': 'Happy birthday to our beloved John! Wishing you health and happiness.',
        'baseTariff': 15000.0,
        'transferFee': 600.0,
        'finalPrice': 15600.0,
        'status': 'pendingValidation',
      },
      {
        'listenerName': 'Family Mbah',
        'listenerEmail': 'mbah@example.com',
        'category': 'condolence',
        'finalText': 'It is with deep sorrow that we announce the passing of our father. Rest in peace.',
        'baseTariff': 25000.0,
        'transferFee': 1000.0,
        'finalPrice': 26000.0,
        'status': 'pendingValidation',
      },
      {
        'listenerName': 'Grace Nkeng',
        'listenerEmail': 'grace@example.com',
        'category': 'promotional',
        'finalText': 'Visit our new store at Mvog Mbi. Opening this Saturday at 9 AM!',
        'baseTariff': 18000.0,
        'transferFee': 720.0,
        'finalPrice': 18720.0,
        'status': 'scheduled',
      },
    ];
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final escrowRef = _db.collection('escrow_accounts').doc();
      await escrowRef.set({
        'announcementId': 'ann_sample_$i',
        'listenerId': 'listener_$i',
        'radioId': radioId,
        'baseAmount': s['baseTariff'],
        'transferFee': s['transferFee'],
        'finalPrice': s['finalPrice'],
        'paymentMethod': 'MoMo',
        'status': s['status'] == 'scheduled' ? 'released' : 'held',
        'heldAt': FieldValue.serverTimestamp(),
        if (s['status'] == 'scheduled') 'releasedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('announcements').doc('ann_sample_$i').set({
        'radioId': radioId,
        'radioName': radioName,
        'listenerId': 'listener_$i',
        'listenerName': s['listenerName'],
        'listenerEmail': s['listenerEmail'],
        'originalText': s['finalText'],
        'finalText': s['finalText'],
        'category': s['category'],
        'wordCount': (s['finalText'] as String).split(' ').length,
        'estimatedDurationSeconds': 30 + i * 5,
        'diffusionCount': 1 + i,
        'diffusionPeriodDays': 1,
        'baseTariff': s['baseTariff'],
        'transferFee': s['transferFee'],
        'finalPrice': s['finalPrice'],
        'currency': 'XAF',
        'paymentMethod': 'MoMo',
        'escrowTransactionId': escrowRef.id,
        'status': s['status'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedTransactions(String radioId, String radioName) async {
    await _db.collection('transactions').add({
      'radioId': radioId,
      'radioName': radioName,
      'type': 'subscription',
      'status': 'released',
      'baseAmount': 30000.0,
      'transferFee': 0.0,
      'totalAmount': 30000.0,
      'currency': 'XAF',
      'paymentMethod': 'MoMo',
      'createdAt': FieldValue.serverTimestamp(),
      'releasedAt': FieldValue.serverTimestamp(),
    });
  }
}

