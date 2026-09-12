import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles escrow logic for announcements.
/// The 4% transfer fee is ALWAYS retained by the system, on both validation and rejection.
class EscrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double TRANSFER_FEE_RATE = 0.04;

  /// Called when listener pays. Funds go into escrow.
  Future<String> holdInEscrow({
    required String announcementId,
    required String listenerId,
    required String radioId,
    required double baseAmount,
    required String paymentMethod,
  }) async {
    final transferFee = baseAmount * TRANSFER_FEE_RATE;
    final finalPrice = baseAmount + transferFee;

    final escrowRef = _firestore.collection('escrow_accounts').doc();
    await escrowRef.set({
      'announcementId': announcementId,
      'listenerId': listenerId,
      'radioId': radioId,
      'baseAmount': baseAmount,
      'transferFee': transferFee,
      'finalPrice': finalPrice,
      'paymentMethod': paymentMethod,
      'status': 'held',
      'heldAt': FieldValue.serverTimestamp(),
    });

    // Create transaction record
    await _firestore.collection('transactions').doc().set({
      'radioId': radioId,
      'type': 'announcement',
      'status': 'inEscrow',
      'baseAmount': baseAmount,
      'transferFee': transferFee,
      'totalAmount': finalPrice,
      'escrowReference': escrowRef.id,
      'announcementId': announcementId,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
      'escrowHeldAt': FieldValue.serverTimestamp(),
    });

    return escrowRef.id;
  }

  /// Release base amount to radio. System keeps the 4% fee.
  Future<void> releaseToRadio({
    required String escrowId,
    required String radioId,
  }) async {
    try {
      final escrowDoc = await _firestore.collection('escrow_accounts').doc(escrowId).get();
      double baseAmount = 0.0;
      if (escrowDoc.exists) {
        baseAmount = (escrowDoc.data()?['baseAmount'] ?? 0.0).toDouble();
        await _firestore.collection('escrow_accounts').doc(escrowId).update({
          'status': 'released',
          'releasedAt': FieldValue.serverTimestamp(),
          'releasedTo': radioId,
          'releasedAmount': baseAmount,
        });
      }

      // Credit radio balance
      await _firestore.collection('radios').doc(radioId).set({
        'balance': FieldValue.increment(baseAmount),
      }, SetOptions(merge: true));

      // Update related transaction
      final txSnap = await _firestore
          .collection('transactions')
          .where('escrowReference', isEqualTo: escrowId)
          .limit(1)
          .get();
      if (txSnap.docs.isNotEmpty) {
        await txSnap.docs.first.reference.update({
          'status': 'released',
          'releasedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Fallback log
      print('releaseToRadio error: $e');
    }
  }

  /// Refund base amount to listener. System KEEPS the 4% fee.
  Future<void> refundToListener({
    required String escrowId,
    required String listenerId,
    required String reason,
  }) async {
    try {
      final escrowDoc = await _firestore.collection('escrow_accounts').doc(escrowId).get();
      double baseAmount = 0.0;
      double transferFee = 0.0;
      String radioId = '';

      if (escrowDoc.exists) {
        final data = escrowDoc.data()!;
        baseAmount = (data['baseAmount'] ?? 0.0).toDouble();
        transferFee = (data['transferFee'] ?? 0.0).toDouble();
        radioId = data['radioId'] ?? '';

        await _firestore.collection('escrow_accounts').doc(escrowId).update({
          'status': 'refunded',
          'refundedAt': FieldValue.serverTimestamp(),
          'refundedTo': listenerId,
          'refundedAmount': baseAmount, // ONLY base amount
          'retainedBySystem': transferFee, // Fee is retained
          'refundReason': reason,
        });
      }

      // Credit listener wallet with base amount ONLY
      await _firestore.collection('wallets').doc(listenerId).set({
        'balance': FieldValue.increment(baseAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create refund transaction record
      await _firestore.collection('transactions').doc().set({
        'radioId': radioId,
        'type': 'refund',
        'status': 'refunded',
        'baseAmount': baseAmount,
        'transferFee': 0.0, // Not refunded
        'totalAmount': baseAmount, // Only base refunded
        'retainedFee': transferFee, // System keeps this
        'initiatorId': listenerId,
        'refundReason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'refundedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('refundToListener error: $e');
    }
  }
}

