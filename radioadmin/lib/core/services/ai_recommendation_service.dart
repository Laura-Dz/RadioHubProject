import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/radio_admin/recommendation_model.dart';

class AiRecommendationService {
  final String baseUrl;
  AiRecommendationService({this.baseUrl = 'http://localhost:8000'});

  Future<RadioInsights> getRadioInsights({
    required String radioId,
    String timeRange = 'last_30_days',
    List<String> categories = const ['audimat', 'shows', 'revenue', 'scheduling'],
    String? authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/recommendations/radio-insights'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'radioId': radioId,
          'timeRange': timeRange,
          'includeCategories': categories,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return RadioInsights.fromJson(jsonDecode(response.body));
      }
      debugPrint('AI API error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('AI recommendation service fallback: $e');
    }
    return RadioInsights.mock(radioId);
  }
}
