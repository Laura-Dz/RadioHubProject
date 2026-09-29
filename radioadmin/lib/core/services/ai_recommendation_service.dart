import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/radio_admin/recommendation_model.dart';

class AiRecommendationService {
  final String? _baseUrl;
  AiRecommendationService({String? baseUrl}) : _baseUrl = baseUrl;

  String get baseUrl => _baseUrl ?? AppConfig.backendUrl;

  Future<RadioInsights> getRadioInsights({
    required String radioId,
    String? timeRange,
    DateTime? startDate,
    DateTime? endDate,
    List<String> categories = const ['audimat', 'shows', 'revenue', 'scheduling', 'comparisons', 'diagnostics'],
    String? authToken,
  }) async {
    try {
      final bodyMap = <String, dynamic>{
        'radioId': radioId,
        'includeCategories': categories,
        'includeAiSummary': true,
      };
      if (startDate != null && endDate != null) {
        bodyMap['startDate'] = startDate.toIso8601String();
        bodyMap['endDate'] = endDate.toIso8601String();
      } else {
        bodyMap['timeRange'] = timeRange ?? 'last_30_days';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/recommendations/radio-insights'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 403) {
        return RadioInsights.fromJson(jsonDecode(response.body));
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        throw Exception(decoded['error']);
      }
      debugPrint('AI API error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('AI recommendation service fallback: $e');
      rethrow;
    }
    return RadioInsights.empty();
  }
}
