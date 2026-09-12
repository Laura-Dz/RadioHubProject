import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String baseUrl;

  AnnouncementService({this.baseUrl = 'http://localhost:8000'});

  /// AI Notor 1: Text improvement suggestion endpoint call
  Future<Map<String, dynamic>> suggestImprovedText({
    required String text,
    required String category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/announcement/suggest-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'category': category,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('AnnouncementService.suggestImprovedText fallback: $e');
    }

    // Fallback simulation if backend offline
    final improved = '[$category] $text — Diffusé sur votre radio préférée!';
    final words = improved.split(' ').length;
    return {
      'original_text': text,
      'improved_text': improved,
      'word_count': words,
      'estimated_duration_seconds': (words * 2).clamp(15, 120),
    };
  }

  /// AI Notor 2: Price calculation endpoint call
  Future<Map<String, dynamic>> calculatePrice({
    required int wordCount,
    required int durationSeconds,
    required int diffusionCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/announcement/calculate-price'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wordCount': wordCount,
          'durationSeconds': durationSeconds,
          'diffusionCount': diffusionCount,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('AnnouncementService.calculatePrice fallback: $e');
    }

    // Fallback simulation: (wordCount * 5 + duration * 50) + 4% transfer fee
    final base = (wordCount * 5.0 + durationSeconds * 50.0).clamp(1000.0, 100000.0);
    final fee = base * 0.04;
    return {
      'base_tariff': base,
      'transfer_fee': fee,
      'final_price': base + fee,
      'currency': 'XAF',
      'fee_percentage': 4.0,
    };
  }

  /// Submits the announcement request to Firestore and places funds in escrow
  Future<String> submitAnnouncementRequest({
    required String radioId,
    required String radioName,
    required String listenerId,
    required String listenerName,
    required String listenerEmail,
    required String category,
    required String originalText,
    required String finalText,
    required int wordCount,
    required int durationSeconds,
    required int diffusionCount,
    required double baseTariff,
    required double transferFee,
    required double finalPrice,
    required String paymentMethod,
  }) async {
    final annRef = _firestore.collection('announcements').doc();
    final escrowRef = _firestore.collection('escrow_accounts').doc();

    // 1. Create Escrow account record
    await escrowRef.set({
      'announcementId': annRef.id,
      'radioId': radioId,
      'listenerId': listenerId,
      'baseAmount': baseTariff,
      'transferFee': transferFee,
      'finalPrice': finalPrice,
      'paymentMethod': paymentMethod,
      'currency': 'XAF',
      'status': 'held',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create Announcement request in Firestore
    await annRef.set({
      'radioId': radioId,
      'radioName': radioName,
      'listenerId': listenerId,
      'listenerName': listenerName,
      'listenerEmail': listenerEmail,
      'category': category,
      'originalText': originalText,
      'finalText': finalText,
      'wordCount': wordCount,
      'estimatedDurationSeconds': durationSeconds,
      'diffusionCount': diffusionCount,
      'diffusionPeriodDays': 1,
      'baseTariff': baseTariff,
      'transferFee': transferFee,
      'finalPrice': finalPrice,
      'currency': 'XAF',
      'paymentMethod': paymentMethod,
      'escrowTransactionId': escrowRef.id,
      'status': 'pendingValidation',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Log initial transaction
    await _firestore.collection('transactions').doc().set({
      'radioId': radioId,
      'radioName': radioName,
      'type': 'announcement',
      'status': 'inEscrow',
      'baseAmount': baseTariff,
      'transferFee': transferFee,
      'totalAmount': finalPrice,
      'currency': 'XAF',
      'paymentMethod': paymentMethod,
      'initiatorId': listenerId,
      'initiatorName': listenerName,
      'initiatorEmail': listenerEmail,
      'announcementId': annRef.id,
      'escrowReference': escrowRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return annRef.id;
  }
}

