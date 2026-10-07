import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'dart:io';
import 'storage_service.dart';
import '../models/radio_admin/announcement_request_model.dart';
import '../models/radio_admin/announcement_tariff_model.dart';
import '../models/radio_admin/announcement_slot_model.dart';
import '../models/radio_admin/radio_profile_model.dart';
import '../models/radio_admin/subscription_model.dart';
import '../models/radio_admin/staff_model.dart';
import '../models/radio_admin/transaction_model.dart';
import '../models/radio_admin/metrics_model.dart';
import '../models/radio_admin/recommendation_model.dart';
import '../models/radio_admin/media_model.dart';
import '../models/radio_admin/session_model.dart';
import '../models/radio_admin/program_model.dart';
import 'escrow_service.dart';
import 'ai_recommendation_service.dart';
import '../utils/firestore_parsers.dart';
import '../config/app_config.dart';

class RadioAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final StorageService _storageService = StorageService();
  final EscrowService _escrow = EscrowService();
  final AiRecommendationService _aiService = AiRecommendationService();

  // ==================== RADIO PROFILE ====================

  Future<RadioProfile?> getRadioProfile(String radioId, {String? fallbackName}) async {
    try {
      final doc = await _firestore.collection('radios').doc(radioId).get();
      if (doc.exists) return RadioProfile.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('getRadioProfile: $e');
    }
    return RadioProfile(
      id: radioId,
      name: fallbackName ?? 'Radio Station',
      description: 'Radio station broadcasting live.',
      function: 'Broadcast quality programming.',
      vision: '',
      mission: '',
      contactEmail: '',
      contactPhone: '',
      language: 'French',
      tags: const [],
    );
  }

  Stream<RadioProfile?> streamRadioProfile(String radioId, {String? fallbackName}) {
    return _firestore.collection('radios').doc(radioId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RadioProfile.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Defensively strips system fields before writing.
  Future<void> updateRadioProfile(String radioId, RadioProfile profile) async {
    final data = profile.toFirestore();
    data.remove('livestreamUrl');
    data.remove('broadcastLink');
    data.remove('streamUrl');
    data.remove('hlsUrl');
    try {
      await _firestore.collection('radios').doc(radioId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('updateRadioProfile: $e');
    }
  }

  Future<String?> uploadImage(String radioId, String type, File file) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : 'png';
      return await _storageService.uploadBytes(
        bytes: bytes,
        path: 'radios/$radioId/$type.$ext',
        contentType: (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png',
      );
    } catch (e) {
      debugPrint('uploadImage: $e');
      return null;
    }
  }

  Future<String?> uploadImageBytes({
    required String radioId,
    required String type,
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  }) async {
    try {
      final ext = fileName != null && fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'png';
      final contentType = mimeType ?? ((ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png');
      return await _storageService.uploadBytes(
        bytes: bytes,
        path: 'radios/$radioId/$type.$ext',
        contentType: contentType,
      );
    } catch (e) {
      debugPrint('uploadImageBytes error: $e');
      return null;
    }
  }

  // ==================== SUBSCRIPTION ====================

  Stream<Subscription?> streamSubscription(String radioId) {
    return _firestore
        .collection('subscriptions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      try {
        return Subscription.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
      } catch (e) {
        return null;
      }
    });
  }

  Future<void> paySubscription({
    required String radioId,
    required String radioName,
    required double amount,
    required int days,
    required String planName,
    required String paymentMethod,
    String? paymentAccount,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    final subRef = _firestore.collection('subscriptions').doc();
    await subRef.set({
      'radioId': radioId,
      'planName': planName,
      'amount': amount,
      'monthlyFee': amount,
      'days': days,
      'status': 'active',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'paymentMethod': paymentMethod,
      if (paymentAccount != null && paymentAccount.isNotEmpty)
        'paymentAccount': paymentAccount,
      'autoRenew': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('radios').doc(radioId).set({
      'isActive': true,
      'subscriptionEndDate': Timestamp.fromDate(endDate),
    }, SetOptions(merge: true));
    await _firestore.collection('transactions').doc().set({
      'radioId': radioId,
      'type': 'subscription',
      'status': 'released',
      'baseAmount': amount,
      'transferFee': 0.0,
      'totalAmount': amount,
      'currency': 'XAF',
      'subscriptionId': subRef.id,
      'paymentMethod': paymentMethod,
      if (paymentAccount != null && paymentAccount.isNotEmpty)
        'paymentAccount': paymentAccount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== STAFF (CREATE & MANAGE) ====================

  /// Live staff list for THIS radio only.
  /// Queries `users` where radioId == radioId AND role in [host, technician].
  Stream<List<StaffMember>> streamStaff(String radioId) {
    return _firestore
        .collection('users')
        .where('radioId', isEqualTo: radioId)
        .where('role', whereIn: ['host', 'technician'])
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StaffMember.fromFirestore(d.data(), d.id))
            .where((s) => s.status != StaffStatus.inactive)
            .toList());
  }

  // ============ CREATE (one callable for technician, direct write for host) ============

  Future<void> createStaff({
    required String radioId,
    required String radioName,
    required String name,
    required String email,
    required String phone,
    required StaffRole role,
    String? bio,
    String? photoUrl,
    String? password, // required for technician
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    // Pre-check duplicates (Firestore read)
    final dup = await _firestore
        .collection('users')
        .where('radioId', isEqualTo: radioId)
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      throw Exception('A staff member with this email already exists for your radio.');
    }

    if (role == StaffRole.host) {
      // Direct Firestore write — no Auth account
      final ref = _firestore.collection('users').doc();
      await ref.set({
        'uid': ref.id,
        'displayName': name.trim(),
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone.trim(),
        'bio': bio?.trim() ?? '',
        'photoUrl': photoUrl,
        'radioId': radioId,
        'radioName': radioName,
        'role': 'host',
        'status': 'active',
        'isActive': true,
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Technician — call the Cloud Function once, which creates Auth + writes users/{uid}
    if (password == null || password.length < 6) {
      throw Exception('A password of at least 6 characters is required for technicians.');
    }

    try {
      final callable = _functions.httpsCallable('createTechnicianAccount');
      final result = await callable.call({
        'radioId': radioId,
        'radioName': radioName,
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone.trim(),
        'bio': bio?.trim() ?? '',
        'photoUrl': photoUrl,
        'password': password,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['error'] ?? 'Failed to create technician');
      }
      final uid = result.data['uid'] as String?;
      if (uid != null && photoUrl != null && photoUrl.isNotEmpty) {
        try {
          await _firestore.collection('users').doc(uid).update({'photoUrl': photoUrl});
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Cloud Function createTechnicianAccount error: $e. Falling back to direct Firestore creation.');
      // Direct Firestore fallback creates user record so admin flow is never blocked
      final ref = _firestore.collection('users').doc();
      await ref.set({
        'uid': ref.id,
        'displayName': name.trim(),
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone.trim(),
        'bio': bio?.trim() ?? '',
        'photoUrl': photoUrl,
        'radioId': radioId,
        'radioName': radioName,
        'role': 'technician',
        'status': 'active',
        'isActive': true,
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateStaff(String staffId, Map<String, dynamic> updates) async {
    updates.remove('radioId');
    updates.remove('role');
    updates.remove('email');
    updates.remove('authUid');
    await _firestore.collection('users').doc(staffId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> suspendStaff(String staffId, String reason) async {
    await _firestore.collection('users').doc(staffId).update({
      'status': 'suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspendReason': reason,
      'isActive': false,
    });
  }

  Future<void> reactivateStaff(String staffId) async {
    await _firestore.collection('users').doc(staffId).update({
      'status': 'active',
      'suspendedAt': null,
      'suspendReason': null,
      'isActive': true,
    });
  }

  /// Resets a technician password by writing to `password_resets`.
  /// Cloud Function onPasswordResetRequested handles the Auth update.
  Future<void> resetTechnicianPassword({
    required String authUid,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    await _firestore.collection('password_resets').add({
      'authUid': authUid,
      'newPassword': newPassword,
      'requestedBy': _auth.currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // ==================== TARIFFS ====================

  Stream<List<AnnouncementTariff>> streamTariffs(String radioId) {
    return _firestore
        .collection('announcement_tariffs')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnnouncementTariff.fromFirestore(d.data(), d.id)).toList());
  }

  Future<List<AnnouncementTariff>> getTariffs(String radioId) async {
    try {
      final snap = await _firestore.collection('announcement_tariffs').where('radioId', isEqualTo: radioId).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => AnnouncementTariff.fromFirestore(d.data(), d.id)).toList();
      }
    } catch (e) {
      debugPrint('getTariffs: $e');
    }
    return [];
  }

  Future<void> upsertTariff(AnnouncementTariff tariff) async {
    try {
      if (tariff.id.isNotEmpty) {
        await _firestore.collection('announcement_tariffs').doc(tariff.id).set(tariff.toFirestore(), SetOptions(merge: true));
        return;
      }
      final categoryKey = (tariff.customCategoryName != null && tariff.customCategoryName!.isNotEmpty)
          ? tariff.customCategoryName!
          : tariff.category.name;

      final snap = await _firestore
          .collection('announcement_tariffs')
          .where('radioId', isEqualTo: tariff.radioId)
          .where('category', isEqualTo: categoryKey)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        await _firestore.collection('announcement_tariffs').add(tariff.toFirestore());
      } else {
        await snap.docs.first.reference.update(tariff.toFirestore());
      }
    } catch (e) {
      debugPrint('upsertTariff: $e');
    }
  }

  Future<void> deleteTariff(String tariffId) async {
    try {
      if (tariffId.isNotEmpty) {
        await _firestore.collection('announcement_tariffs').doc(tariffId).delete();
      }
    } catch (e) {
      debugPrint('deleteTariff: $e');
    }
  }

  // ==================== ANNOUNCEMENTS ====================

  Stream<List<AnnouncementRequest>> streamPendingAnnouncements(String radioId) {
    return _firestore
        .collection('announcements')
        .where('radioId', isEqualTo: radioId)
        .where('status', whereIn: ['pendingValidation', 'pendingPayment', 'pending', 'inEscrow'])
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnnouncementRequest.fromFirestore(d.data(), d.id)).toList());
  }

  Stream<List<AnnouncementRequest>> streamScheduledAnnouncements(String radioId) {
    return _firestore
        .collection('announcements')
        .where('radioId', isEqualTo: radioId)
        .where('status', whereIn: ['scheduled', 'validated', 'broadcasted'])
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnnouncementRequest.fromFirestore(d.data(), d.id)).toList());
  }

  Future<List<AnnouncementSlot>> getAvailableSlots({
    required String radioId,
    required DateTime fromDate,
    required int days,
  }) async {
    final toDate = fromDate.add(Duration(days: days));
    final slots = <AnnouncementSlot>[];
    try {
      final snap = await _firestore
          .collection('sessions')
          .where('radioId', isEqualTo: radioId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('startTime', isLessThan: Timestamp.fromDate(toDate))
          .orderBy('startTime')
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final start = FSParsers.toDate(data['startTime']) ?? DateTime.now();
        final end = FSParsers.toDate(data['endTime']) ?? start.add(const Duration(hours: 1));
        final allowsAnn = data['allowsAnnouncements'] == true;
        final showName = data['programName'] as String?;
        slots.add(AnnouncementSlot(
          date: DateTime(start.year, start.month, start.day),
          startTime: start.subtract(const Duration(minutes: 2)),
          durationSeconds: 15,
          slotType: 'between',
        ));
        if (allowsAnn) {
          final diff = end.difference(start);
          final mid = start.add(Duration(seconds: diff.inSeconds ~/ 2));
          slots.add(AnnouncementSlot(
            date: DateTime(start.year, start.month, start.day),
            startTime: mid,
            durationSeconds: 15,
            slotType: 'within',
            showId: doc.id,
            showName: showName,
          ));
        }
      }
    } catch (e) {
      debugPrint('getAvailableSlots: $e');
    }

    if (slots.isEmpty) {
      for (int d = 0; d < days; d++) {
        final day = fromDate.add(Duration(days: d));
        slots.add(AnnouncementSlot(
          date: day,
          startTime: DateTime(day.year, day.month, day.day, 8, 0),
          durationSeconds: 15,
          slotType: 'between',
        ));
        slots.add(AnnouncementSlot(
          date: day,
          startTime: DateTime(day.year, day.month, day.day, 12, 0),
          durationSeconds: 15,
          slotType: 'between',
        ));
        slots.add(AnnouncementSlot(
          date: day,
          startTime: DateTime(day.year, day.month, day.day, 19, 0),
          durationSeconds: 15,
          slotType: 'within',
          showName: 'Evening Show',
        ));
      }
    }
    return slots;
  }

  Future<void> validateAnnouncement({
    required String announcementId,
    required String adminId,
    required DateTime scheduledFor,
    required List<AnnouncementSlot> assignedSlots,
  }) async {
    try {
      final doc = await _firestore.collection('announcements').doc(announcementId).get();
      if (!doc.exists) throw Exception('Announcement not found');
      final data = doc.data()!;
      final escrowId = data['escrowTransactionId'] as String?;
      final radioId = data['radioId'] as String? ?? '';
      final baseAmount = ((data['baseAmount'] ?? data['baseTariff'] ?? data['amount'] ?? 0.0) as num).toDouble();

      await _firestore.collection('announcements').doc(announcementId).update({
        'status': 'scheduled',
        'validatedBy': adminId,
        'validatedAt': FieldValue.serverTimestamp(),
        'scheduledFor': Timestamp.fromDate(scheduledFor),
        'assignedSlots': assignedSlots.map((s) => s.toJson()).toList(),
      });

      if (escrowId != null && escrowId.isNotEmpty) {
        await _escrow.releaseToRadio(escrowId: escrowId, radioId: radioId);
      } else {
        await _firestore.collection('radios').doc(radioId).set({
          'balance': FieldValue.increment(baseAmount),
        }, SetOptions(merge: true));
      }

      // Generate broadcast handoff notifications for Host and Technician
      final cat = (data['category'] ?? 'General').toString();
      final listenerName = (data['listenerName'] ?? 'Listener').toString();

      for (final slot in assignedSlots) {
        if (slot.slotType == 'within') {
          // Routed to Host for live reading during the specific program
          await _firestore.collection('notifications').add({
            'radioId': radioId,
            'recipientRole': 'host',
            'showId': slot.showId,
            'showName': slot.showName,
            'type': 'announcement_scheduled',
            'title': '📢 Announcement Scheduled for Your Show',
            'body': '$cat announcement from $listenerName scheduled for ${slot.timeLabel} during ${slot.showName ?? "your show"}.',
            'data': {
              'announcementId': announcementId,
              'scheduledTime': slot.startTime.toIso8601String(),
              'slotType': 'within',
              'showId': slot.showId,
              'showName': slot.showName,
              'durationSeconds': slot.durationSeconds,
            },
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Routed to Technician for intermediary slot between programs
          await _firestore.collection('notifications').add({
            'radioId': radioId,
            'recipientRole': 'technician',
            'type': 'announcement_scheduled',
            'title': '📻 Intermediary Announcement Ready for Lineup',
            'body': '$cat announcement from $listenerName scheduled for ${slot.timeLabel} between programs.',
            'data': {
              'announcementId': announcementId,
              'scheduledTime': slot.startTime.toIso8601String(),
              'slotType': 'between',
              'durationSeconds': slot.durationSeconds,
            },
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('validateAnnouncement: $e');
      rethrow;
    }
  }

  Future<void> rejectAnnouncement({
    required String announcementId,
    required String adminId,
    required String reason,
  }) async {
    try {
      final doc = await _firestore.collection('announcements').doc(announcementId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final escrowId = data['escrowTransactionId'] as String?;
      final listenerId = data['listenerId'] as String? ?? '';

      await _firestore.collection('announcements').doc(announcementId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      if (escrowId != null && escrowId.isNotEmpty) {
        await _escrow.refundToListener(
          escrowId: escrowId,
          listenerId: listenerId,
          reason: reason,
        );
      }
    } catch (e) {
      debugPrint('rejectAnnouncement: $e');
      rethrow;
    }
  }

  Future<String> generateAnnouncementPDF(String announcementId) async {
    final pdfUrl = '${AppConfig.backendUrl}/api/announcement/$announcementId/print/';
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'pdfUrl': pdfUrl,
        'isPrinted': true,
      });
    } catch (e) {
      debugPrint('generatePDF: $e');
    }
    return pdfUrl;
  }

  Future<void> markAsPrinted(String announcementId, String pdfUrl) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'isPrinted': true,
        'pdfUrl': pdfUrl,
      });
    } catch (e) {
      debugPrint('markAsPrinted: $e');
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Returns only what the radio admin should see:
  ///  - their subscription payments (expenses)
  ///  - their validated announcement payouts (revenue, base only)
  ///
  /// Escrow, refunds, and transfer fees are intentionally excluded.
  Stream<List<RadioTransaction>> streamRadioAdminTransactions(String radioId) {
    return _firestore
        .collection('transactions')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => RadioTransaction.fromFirestore(d.data(), d.id))
              .where((t) =>
                  t.type == RadioTransactionType.subscription ||
                  t.type == RadioTransactionType.announcement)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<RadioTransaction>> streamTransactions(String radioId) =>
      streamRadioAdminTransactions(radioId);

  // ==================== MEDIA ====================

  Stream<List<MediaItem>> streamMedia(String radioId) {
    return _firestore
        .collection('media')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => MediaItem.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  // ==================== SESSIONS (READ-ONLY) ====================

  Stream<List<Session>> streamSessions(String radioId) {
    return _firestore
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => a.startTime.compareTo(b.startTime));
          return list;
        });
  }

  Future<String> createSession(Session s) async {
    final ref = await _firestore.collection('sessions').add(s.toFirestore());
    return ref.id;
  }

  Future<void> updateSession(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('sessions').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSession(String id) async {
    await _firestore.collection('sessions').doc(id).delete();
  }

  // ==================== PROGRAMS ====================

  Stream<List<Program>> streamPrograms(String radioId) {
    return _firestore
        .collection('programs')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Program.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
  }

  Future<String> createProgram(Program p) async {
    final ref = await _firestore.collection('programs').add(p.toFirestore());
    return ref.id;
  }

  Future<void> updateProgram(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('programs').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveProgram(String id) async {
    await _firestore.collection('programs').doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> streamCategories(String radioId) {
    return _firestore
        .collection('program_categories')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((snap) {
          final names = snap.docs
              .map((d) => (d.data()['name'] ?? '').toString())
              .where((n) => n.isNotEmpty)
              .toList();
          if (names.isEmpty) {
            return ['music', 'talk', 'news', 'sports', 'entertainment', 'general'];
          }
          names.sort();
          return names;
        });
  }

  // ==================== METRICS ====================

  Future<RadioMetrics> getMetrics(
    String radioId, {
    String period = '7d',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (radioId.isEmpty) {
      return RadioMetrics.empty();
    }
    try {
      final DateTime from;
      final DateTime to;
      final int days;
      if (startDate != null && endDate != null) {
        from = startDate;
        to = endDate;
        days = to.difference(from).inDays.clamp(1, 1826);
      } else {
        days = period == '90d' ? 90 : period == '30d' ? 30 : 7;
        from = DateTime.now().subtract(Duration(days: days));
        to = DateTime.now();
      }
      final prevFrom = from.subtract(Duration(days: days));

      // 1. Fetch listener activity logs (Play, Pause, Stop events)
      QuerySnapshot<Map<String, dynamic>> activitySnap = await _firestore
          .collection('listener_activity')
          .where('radioId', isEqualTo: radioId)
          .get();

      if (activitySnap.docs.isEmpty) {
        activitySnap = await _firestore
            .collection('radios')
            .doc(radioId)
            .collection('activity_logs')
            .get();
      }

      // 2. Fetch sessions strictly for this radio
      QuerySnapshot<Map<String, dynamic>> sessionSnap = await _firestore
          .collection('sessions')
          .where('radioId', isEqualTo: radioId)
          .get();

      if (sessionSnap.docs.isEmpty) {
        sessionSnap = await _firestore
            .collection('radios')
            .doc(radioId)
            .collection('sessions')
            .get();
      }

      final hasActivities = activitySnap.docs.isNotEmpty;
      final hasSessions = sessionSnap.docs.isNotEmpty;

      if (!hasActivities && !hasSessions) {
        debugPrint('getMetrics: No activity logs or sessions for $radioId — returning empty metrics');
        return RadioMetrics.empty();
      }

      // Helpers
      DateTime? getActivityDate(Map<String, dynamic> d) {
        return FSParsers.toDate(d['timestamp']) ??
            FSParsers.toDate(d['clientTime']) ??
            FSParsers.toDate(d['createdAt']);
      }

      DateTime? getSessionDate(Map<String, dynamic> d) {
        return FSParsers.toDate(d['actualStart']) ??
            FSParsers.toDate(d['scheduledStart']) ??
            FSParsers.toDate(d['startTime']) ??
            FSParsers.toDate(d['date']) ??
            FSParsers.toDate(d['createdAt']);
      }

      // --- Process Activity Logs for Audimat ---
      final currentActivities = <Map<String, dynamic>>[];
      final prevActivities = <Map<String, dynamic>>[];

      for (final doc in activitySnap.docs) {
        final d = doc.data();
        final dt = getActivityDate(d);
        if (dt == null) continue;
        if (dt.isAfter(from)) {
          currentActivities.add({...d, '_dt': dt});
        } else if (dt.isAfter(prevFrom) && dt.isBefore(from)) {
          prevActivities.add({...d, '_dt': dt});
        }
      }

      // --- Process Sessions ---
      final allSessions = sessionSnap.docs.map((e) => e.data()).toList();
      final currentSessions = <Map<String, dynamic>>[];
      final prevSessions = <Map<String, dynamic>>[];

      for (final s in allSessions) {
        final dt = getSessionDate(s);
        if (dt == null) {
          currentSessions.add(s);
          continue;
        }
        if (dt.isAfter(from)) {
          currentSessions.add(s);
        } else if (dt.isAfter(prevFrom) && dt.isBefore(from)) {
          prevSessions.add(s);
        }
      }

      final effectiveSessions = currentSessions.isNotEmpty ? currentSessions : allSessions;

      // Calculate Total & Peak Listeners
      int totalListeners = 0;
      int peakListeners = 0;
      double engagementRate = 0.0;
      double growthPercent = 0.0;

      // Audimat Trend Points
      final Map<DateTime, int> byDay = {};
      final now = DateTime.now();
      final numDays = days;
      for (int i = 0; i < numDays; i++) {
        final d = now.subtract(Duration(days: numDays - 1 - i));
        byDay[DateTime(d.year, d.month, d.day)] = 0;
      }

      final Map<int, int> byHour = {};

      if (hasActivities && currentActivities.isNotEmpty) {
        // Derive audimat from real listener play/pause activity logs
        final plays = currentActivities.where((a) => (a['action'] ?? 'play') == 'play').toList();
        final uniqueUsers = plays.map((a) => (a['userId'] ?? '').toString()).where((u) => u.isNotEmpty).toSet();
        totalListeners = uniqueUsers.isNotEmpty ? uniqueUsers.length : plays.length;

        final prevPlays = prevActivities.where((a) => (a['action'] ?? 'play') == 'play').toList();
        final prevUnique = prevPlays.map((a) => (a['userId'] ?? '').toString()).where((u) => u.isNotEmpty).toSet();
        final prevCount = prevUnique.isNotEmpty ? prevUnique.length : prevPlays.length;

        if (prevCount > 0) {
          growthPercent = ((totalListeners - prevCount) / prevCount) * 100;
        }

        // Plot play events on trend
        for (final a in plays) {
          final dt = a['_dt'] as DateTime;
          final day = DateTime(dt.year, dt.month, dt.day);
          byDay[day] = (byDay[day] ?? 0) + 1;
          final h = dt.hour;
          byHour[h] = (byHour[h] ?? 0) + 1;
        }

        // Peak listeners across daily buckets
        peakListeners = byDay.values.isEmpty ? 0 : byDay.values.reduce((a, b) => a > b ? a : b);

        // Average duration from pause/stop events
        final pauseEvents = currentActivities.where((a) => a['action'] == 'pause' || a['action'] == 'stop').toList();
        if (pauseEvents.isNotEmpty) {
          final totalSec = pauseEvents.fold<int>(0, (s, a) => s + FSParsers.toInt(a['durationSeconds']));
          final avgSec = totalSec / pauseEvents.length;
          // Approximate completion relative to a 30m average show
          engagementRate = (avgSec / 1800.0).clamp(0.05, 1.0);
        } else {
          engagementRate = 0.5;
        }
      } else {
        // Fallback to sessions listener counts
        for (final d in currentSessions.isNotEmpty ? currentSessions : effectiveSessions) {
          final count = FSParsers.toInt(d['listenerCount'] ?? d['listeners']);
          totalListeners += count;
          if (count > peakListeners) peakListeners = count;
        }

        final prevTotal = prevSessions.fold<int>(0, (s, d) =>
            s + FSParsers.toInt(d['listenerCount'] ?? d['listeners']));
        if (prevTotal > 0) {
          growthPercent = ((totalListeners - prevTotal) / prevTotal) * 100;
        }

        for (final d in currentSessions.isNotEmpty ? currentSessions : effectiveSessions) {
          final dt = getSessionDate(d);
          if (dt == null) continue;
          final day = DateTime(dt.year, dt.month, dt.day);
          final count = FSParsers.toInt(d['listenerCount'] ?? d['listeners']);
          byDay[day] = (byDay[day] ?? 0) + count;
          final h = dt.hour;
          byHour[h] = (byHour[h] ?? 0) + count;
        }

        final sessionCount = currentSessions.isNotEmpty ? currentSessions.length : effectiveSessions.length;
        final totalCompletion = (currentSessions.isNotEmpty ? currentSessions : effectiveSessions)
            .fold<double>(0.0, (s, d) => s + FSParsers.toDouble(d['completionRate'] ?? d['retention'] ?? 0.0));
        engagementRate = sessionCount == 0 ? 0.0 : totalCompletion / sessionCount;
      }

      // Audimat Trend Series
      final trend = byDay.entries
          .map((e) => ListenerPoint(e.key, e.value))
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      // Category share
      final Map<String, int> catMap = {};
      for (final d in effectiveSessions) {
        String cat = (d['programCategory'] ?? (d['theme'] is Map ? d['theme']['category'] : null) ?? '').toString().toLowerCase();
        if (cat.isEmpty) cat = 'general';
        catMap[cat] = (catMap[cat] ?? 0) + 1;
      }
      final catColors = [
        const Color(0xFF4A90D9), const Color(0xFFD4A017),
        const Color(0xFF22C55E), const Color(0xFFEF4444),
        const Color(0xFF9C27B0), const Color(0xFFFF5722),
      ];
      int ci = 0;
      final byCategory = catMap.entries.map((e) {
        final name = e.key.isNotEmpty
            ? e.key[0].toUpperCase() + e.key.substring(1)
            : 'General';
        return CategoryPoint(name, e.value, catColors[ci++ % catColors.length]);
      }).toList();

      // Show performance: group strictly by this radio's programs
      final Map<String, List<int>> showMap = {};
      final Map<String, List<double>> showRetention = {};
      for (final d in effectiveSessions) {
        final name = (d['programName'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final count = FSParsers.toInt(d['listenerCount'] ?? d['listeners']);
        final ret = FSParsers.toDouble(d['completionRate'] ?? d['retention'] ?? 0.0);
        showMap[name] = (showMap[name] ?? [])..add(count);
        showRetention[name] = (showRetention[name] ?? [])..add(ret);
      }
      final showPerformance = showMap.entries.map((e) {
        final avg = e.value.isEmpty
            ? 0
            : e.value.reduce((a, b) => a + b) ~/ e.value.length;
        final retList = showRetention[e.key] ?? [];
        final avgRet = retList.isEmpty ? 0.0 : retList.reduce((a, b) => a + b) / retList.length;
        return ShowPerformance(showName: e.key, avgListeners: avg, retention: avgRet);
      }).toList()
        ..sort((a, b) => b.avgListeners.compareTo(a.avgListeners));

      return RadioMetrics(
        totalListeners: totalListeners,
        peakListeners: peakListeners,
        engagementRate: engagementRate,
        growthPercent: growthPercent,
        trend: trend,
        byCategory: byCategory,
        showPerformance: showPerformance.take(8).toList(),
        audienceByHour: byHour,
      );
    } catch (e) {
      debugPrint('getMetrics error for $radioId: $e');
      return RadioMetrics.empty();
    }
  }

  // ==================== AI INSIGHTS ====================

  Future<RadioInsights> getRadioInsights({
    required String radioId,
    String? timeRange = 'last_30_days',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _aiService.getRadioInsights(
      radioId: radioId,
      timeRange: timeRange,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
