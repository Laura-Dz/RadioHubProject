import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'cloud_function_caller.dart';
import '../models/announcement_request.dart';
import '../config/app_config.dart';

class AnnouncementTariffEntry {
  final String category;
  final double ratePerUnit; // price for one 15-second unit
  final bool isActive;

  AnnouncementTariffEntry({
    required this.category,
    required this.ratePerUnit,
    this.isActive = true,
  });
}

class AnnouncementService {
  final _db = FirebaseFirestore.instance;
  final String baseUrl;

  AnnouncementService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.backendUrl;

  /// Fetches the announcement categories + tariffs for a radio.
  Future<List<AnnouncementTariffEntry>> getTariffs(String radioId) async {
    try {
      final snap = await _db
          .collection('announcement_tariffs')
          .where('radioId', isEqualTo: radioId)
          .get();

      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) {
          final data = d.data();
          final catName = (data['customCategoryName'] != null &&
                  data['customCategoryName'].toString().trim().isNotEmpty)
              ? data['customCategoryName'].toString().trim()
              : (data['category'] ?? '').toString().trim();
          return AnnouncementTariffEntry(
            category: catName,
            ratePerUnit: (data['ratePer15SecUnit'] ?? data['ratePerUnit'] ?? 0.0).toDouble(),
            isActive: data['isActive'] != false,
          );
        }).where((t) => t.category.isNotEmpty && t.isActive).toList()
          ..sort((a, b) => a.category.compareTo(b.category));

        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      // Fallback
    }

    // Default standard tariffs if not yet configured in DB
    return [
      AnnouncementTariffEntry(category: 'general', ratePerUnit: 500),
      AnnouncementTariffEntry(category: 'birthday', ratePerUnit: 600),
      AnnouncementTariffEntry(category: 'anniversary', ratePerUnit: 600),
      AnnouncementTariffEntry(category: 'congratulations', ratePerUnit: 700),
      AnnouncementTariffEntry(category: 'condolence', ratePerUnit: 500),
      AnnouncementTariffEntry(category: 'promotional', ratePerUnit: 1200),
      AnnouncementTariffEntry(category: 'event', ratePerUnit: 1000),
    ];
  }

  /// Enhances the message using AI.
  Future<String> enhanceText({
    required String category,
    required String text,
  }) async {
    try {
      final res = await CloudFunctionCaller.call('enhanceAnnouncementText', {
        'category': category,
        'text': text,
      });
      final data = Map<String, dynamic>.from(res);
      return (data['enhanced'] ?? text).toString();
    } catch (e) {
      // Return original text on network or server error
      return text;
    }
  }

  /// Submits the request. Backend computes the final price and returns the ID.
  Future<Map<String, dynamic>> submitRequest({
    required String radioId,
    required String radioName,
    required String listenerId,
    required String listenerName,
    required String category,
    required bool isCustomCategory,
    required String originalText,
    required String finalText,
    required AnnouncementPriority priority,
    required int diffusionsPerDay,
    required int days,
    DateTime? startDate,
    DateTime? endDate,
    String paymentMethod = 'MoMo',
  }) async {
    final effectiveStartDate = startDate ?? DateTime.now();
    final effectiveEndDate = endDate ?? effectiveStartDate.add(Duration(days: days));

    try {
      final res = await CloudFunctionCaller.call('submitAnnouncementRequest', {
        'radioId': radioId,
        'radioName': radioName,
        'listenerId': listenerId,
        'listenerName': listenerName,
        'category': category,
        'isCustomCategory': isCustomCategory,
        'originalText': originalText,
        'finalText': finalText,
        'priority': priority.name,
        'diffusionsPerDay': diffusionsPerDay,
        'days': days,
        'desiredStartDate': effectiveStartDate.toIso8601String(),
        'startDate': effectiveStartDate.toIso8601String(),
        'endDate': effectiveEndDate.toIso8601String(),
        'paymentMethod': paymentMethod,
      });
      return Map<String, dynamic>.from(res);
    } catch (e) {
      // Client-side fallback submission directly to Firestore if cloud function is unavailable
      final wordCount = finalText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final units = (wordCount == 0 ? 1 : (wordCount / (2.5 * 15)).ceil()).clamp(1, 99);
      const ratePerUnit = 500.0;
      final baseAmount = ratePerUnit * units * diffusionsPerDay * days * priority.multiplier;
      final transferFee = baseAmount * 0.04;
      final finalPrice = baseAmount + transferFee;

      final ref = _db.collection('announcements').doc();
      final escrowId = 'escrow_${ref.id}';

      await ref.set({
        'radioId': radioId,
        'radioName': radioName,
        'listenerId': listenerId,
        'listenerName': listenerName,
        'category': category,
        'isCustomCategory': isCustomCategory,
        'originalText': originalText,
        'finalText': finalText,
        'priority': priority.name,
        'diffusionsPerDay': diffusionsPerDay,
        'days': days,
        'diffusionPeriodDays': days,
        'diffusionCount': diffusionsPerDay * days,
        'desiredStartDate': Timestamp.fromDate(effectiveStartDate),
        'startDate': Timestamp.fromDate(effectiveStartDate),
        'endDate': Timestamp.fromDate(effectiveEndDate),
        'wordCount': wordCount,
        'units': units,
        'ratePerUnit': ratePerUnit,
        'baseAmount': baseAmount,
        'baseTariff': baseAmount,
        'transferFee': transferFee,
        'finalPrice': finalPrice,
        'currency': 'XAF',
        'paymentMethod': paymentMethod,
        'escrowTransactionId': escrowId,
        'status': 'inEscrow',
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await _db.collection('escrow_accounts').doc(escrowId).set({
          'announcementId': ref.id,
          'radioId': radioId,
          'listenerId': listenerId,
          'baseTariff': baseAmount,
          'transferFee': transferFee,
          'totalAmount': finalPrice,
          'paymentMethod': paymentMethod,
          'currency': 'XAF',
          'status': 'held',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return {
        'success': true,
        'announcementId': ref.id,
        'baseAmount': baseAmount,
        'transferFee': transferFee,
        'finalPrice': finalPrice,
        'units': units,
      };
    }
  }

  // ---------- Legacy shims for backwards compatibility ----------

  Future<Map<String, dynamic>> suggestImprovedText({
    required String text,
    required String category,
  }) async {
    final improved = await enhanceText(category: category, text: text);
    final words = improved.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return {
      'original_text': text,
      'improved_text': improved,
      'word_count': words,
      'estimated_duration_seconds': (words * 2).clamp(15, 120),
    };
  }

  Future<Map<String, dynamic>> calculatePrice({
    required int wordCount,
    required int durationSeconds,
    required int diffusionCount,
    double ratePerUnit = 500.0,
    double priorityMultiplier = 1.0,
  }) async {
    final units = (durationSeconds / 15).ceil().clamp(1, 99);
    final base = units * ratePerUnit * (diffusionCount > 0 ? diffusionCount : 1) * priorityMultiplier;
    final fee = base * 0.04;
    return {
      'base_tariff': base,
      'transfer_fee': fee,
      'final_price': base + fee,
      'currency': 'XAF',
      'fee_percentage': 4.0,
    };
  }

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
    AnnouncementPriority priority = AnnouncementPriority.standard,
    DateTime? startDate,
    DateTime? endDate,
    int diffusionPeriodDays = 1,
    int diffusionsPerDay = 1,
  }) async {
    final res = await submitRequest(
      radioId: radioId,
      radioName: radioName,
      listenerId: listenerId,
      listenerName: listenerName,
      category: category,
      isCustomCategory: false,
      originalText: originalText,
      finalText: finalText,
      priority: priority,
      diffusionsPerDay: diffusionsPerDay,
      days: diffusionPeriodDays,
      startDate: startDate,
      endDate: endDate,
      paymentMethod: paymentMethod,
    );
    return (res['announcementId'] ?? '').toString();
  }
}
