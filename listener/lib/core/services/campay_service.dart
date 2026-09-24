import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum CampayTransactionStatus { pending, successful, failed }

class CampayCollectResult {
  final bool success;
  final String? reference;
  final String? ussdCode;
  final String? operator;
  final String? message;

  CampayCollectResult({
    required this.success,
    this.reference,
    this.ussdCode,
    this.operator,
    this.message,
  });
}

class CampayTransactionResult {
  final CampayTransactionStatus status;
  final String reference;
  final double amount;
  final String currency;
  final String? operator;

  CampayTransactionResult({
    required this.status,
    required this.reference,
    required this.amount,
    required this.currency,
    this.operator,
  });
}

class CampayService {
  // Demo / Production endpoint
  static const String _baseUrl = 'https://demo.campay.net/api';
  
  // Can be configured via environment or Firestore settings
  String? _username;
  String? _password;
  String? _cachedToken;
  DateTime? _tokenExpiry;

  CampayService({String? username, String? password})
      : _username = username,
        _password = password;

  /// Retrieves an authentication token from CamPay
  Future<String?> _getToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    if (_username == null || _password == null) {
      // Demo mock token
      _cachedToken = 'mock_campay_token_${DateTime.now().millisecondsSinceEpoch}';
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      return _cachedToken;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _username, 'password': _password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedToken = data['token'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return _cachedToken;
      }
    } catch (e) {
      debugPrint('CampayService._getToken error: $e');
    }
    return null;
  }

  /// Formats Cameroon phone number to international format (2376XXXXXXXX)
  String _formatPhone(String raw) {
    String p = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (p.startsWith('237') && p.length == 12) return p;
    if (p.length == 9) return '237$p';
    return p;
  }

  /// Initiates a payment request (collection) via CamPay
  Future<CampayCollectResult> collect({
    required double amount,
    required String phone,
    required String description,
    required String externalReference,
  }) async {
    final formattedPhone = _formatPhone(phone);
    final token = await _getToken();

    if (token == null || token.startsWith('mock_')) {
      // Demo simulated response
      final isMtn = formattedPhone.startsWith('23767') ||
          formattedPhone.startsWith('23768') ||
          formattedPhone.startsWith('237650') ||
          formattedPhone.startsWith('237651') ||
          formattedPhone.startsWith('237652') ||
          formattedPhone.startsWith('237653') ||
          formattedPhone.startsWith('237654');

      final op = isMtn ? 'MTN' : 'ORANGE';
      final ussd = isMtn ? '*126#' : '#150*50#';
      final ref = 'CP_${DateTime.now().millisecondsSinceEpoch}';

      return CampayCollectResult(
        success: true,
        reference: ref,
        ussdCode: ussd,
        operator: op,
        message: 'USSD prompt initiated. Confirm on your phone ($ussd).',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/collect/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'amount': amount.toInt().toString(),
          'currency': 'XAF',
          'from': formattedPhone,
          'description': description,
          'external_reference': externalReference,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CampayCollectResult(
          success: true,
          reference: data['reference'],
          ussdCode: data['ussd_code'] ?? '*126#',
          operator: data['operator'],
        );
      } else {
        final data = jsonDecode(response.body);
        return CampayCollectResult(
          success: false,
          message: data['message'] ?? 'Payment collection failed (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('CampayService.collect error: $e');
      return CampayCollectResult(
        success: false,
        message: 'Network error communicating with payment gateway.',
      );
    }
  }

  /// Checks the status of an ongoing CamPay transaction
  Future<CampayTransactionResult> checkTransactionStatus(String reference) async {
    final token = await _getToken();

    if (token == null || token.startsWith('mock_')) {
      // Mock simulation: successful after 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      return CampayTransactionResult(
        status: CampayTransactionStatus.successful,
        reference: reference,
        amount: 0,
        currency: 'XAF',
        operator: 'MOBILE_MONEY',
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/$reference/'),
        headers: {
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statusStr = (data['status'] ?? '').toString().toUpperCase();

        CampayTransactionStatus status;
        if (statusStr == 'SUCCESSFUL') {
          status = CampayTransactionStatus.successful;
        } else if (statusStr == 'FAILED') {
          status = CampayTransactionStatus.failed;
        } else {
          status = CampayTransactionStatus.pending;
        }

        return CampayTransactionResult(
          status: status,
          reference: reference,
          amount: ((data['amount'] ?? 0) as num).toDouble(),
          currency: (data['currency'] ?? 'XAF').toString(),
          operator: data['operator']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('CampayService.checkTransactionStatus error: $e');
    }

    return CampayTransactionResult(
      status: CampayTransactionStatus.pending,
      reference: reference,
      amount: 0,
      currency: 'XAF',
    );
  }

  /// Polls transaction until SUCCESSFUL or FAILED or maxAttempts reached
  Future<CampayTransactionStatus> pollTransactionStatus({
    required String reference,
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 20,
    void Function(int attempt, CampayTransactionStatus status)? onTick,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await checkTransactionStatus(reference);
      if (onTick != null) onTick(attempt, result.status);

      if (result.status == CampayTransactionStatus.successful) {
        return CampayTransactionStatus.successful;
      }
      if (result.status == CampayTransactionStatus.failed) {
        return CampayTransactionStatus.failed;
      }

      await Future.delayed(interval);
    }
    return CampayTransactionStatus.pending;
  }
}
