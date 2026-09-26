import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Structured result of an OpenAI Content Moderation check.
class ModerationResult {
  final bool passed;
  final List<String> flaggedCategories;
  final String? message;

  const ModerationResult({
    required this.passed,
    this.flaggedCategories = const [],
    this.message,
  });

  factory ModerationResult.clean() => const ModerationResult(passed: true);

  factory ModerationResult.flagged(List<String> categories) {
    final readable = categories.map(_formatCategory).join(', ');
    return ModerationResult(
      passed: false,
      flaggedCategories: categories,
      message:
          'Your message cannot be broadcast because it violates content standards ($readable). Please revise it to proceed.',
    );
  }

  static String _formatCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'harassment':
      case 'harassment/threatening':
        return 'Harassment';
      case 'hate':
      case 'hate/threatening':
        return 'Hate Speech';
      case 'sexual':
      case 'sexual/minors':
        return 'Adult / Inappropriate Content';
      case 'violence':
      case 'violence/graphic':
        return 'Violence';
      case 'self-harm':
      case 'self-harm/intent':
      case 'self-harm/instructions':
        return 'Self-Harm';
      case 'illicit':
      case 'illicit/violent':
        return 'Illegal / Dangerous Activity';
      default:
        return cat.replaceAll('/', ' ').replaceAll('_', ' ');
    }
  }
}

/// Structured result of a Gemini Announcement Amelioration.
class AmeliorationResult {
  final String originalText;
  final String polishedText;
  final int originalWordCount;
  final int polishedWordCount;
  final int originalUnits;
  final int polishedUnits;
  final double originalSeconds;
  final double polishedSeconds;

  const AmeliorationResult({
    required this.originalText,
    required this.polishedText,
    required this.originalWordCount,
    required this.polishedWordCount,
    required this.originalUnits,
    required this.polishedUnits,
    required this.originalSeconds,
    required this.polishedSeconds,
  });

  int get wordCount => polishedWordCount;
  double get estimatedDurationSeconds => polishedSeconds;

  static int calculateUnits(int wordCount) {
    if (wordCount <= 0) return 1;
    // Standard broadcast pace: ~2.5 words/sec -> 37.5 words per 15s unit
    return (wordCount / (2.5 * 15)).ceil().clamp(1, 99);
  }

  static double calculateSeconds(int wordCount) {
    if (wordCount <= 0) return 0.0;
    return (wordCount / 2.5).clamp(5.0, 300.0);
  }
}

/// Service that coordinates OpenAI Content Moderation and Gemini Broadcast Amelioration.
class AnnouncementAiService {
  final http.Client _client;

  AnnouncementAiService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // 1. OPENAI CONTENT MODERATION
  // ---------------------------------------------------------------------------

  /// Checks the given text against OpenAI's multi-category safety policy.
  Future<ModerationResult> moderateText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return ModerationResult.clean();

    final apiKey = AppConfig.openaiApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint('AnnouncementAiService: No OpenAI key configured, skipping moderation.');
      return ModerationResult.clean();
    }

    try {
      final uri = Uri.parse('https://api.openai.com/v1/moderations');
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'input': clean,
              'model': 'omni-moderation-latest',
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) {
        debugPrint('OpenAI Moderation API non-200: ${response.statusCode} -> ${response.body}');
        return ModerationResult.clean();
      }

      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return ModerationResult.clean();

      final first = results.first as Map<String, dynamic>;
      final isFlagged = first['flagged'] == true;

      if (!isFlagged) {
        return ModerationResult.clean();
      }

      final categoriesMap = first['categories'] as Map<String, dynamic>? ?? {};
      final flaggedList = <String>[];
      categoriesMap.forEach((key, val) {
        if (val == true) flaggedList.add(key);
      });

      return ModerationResult.flagged(flaggedList);
    } catch (e) {
      debugPrint('OpenAI Moderation check error (safe fallback): $e');
      return ModerationResult.clean();
    }
  }

  // ---------------------------------------------------------------------------
  // 2. GEMINI ANNOUNCEMENT AMELIORATION
  // ---------------------------------------------------------------------------

  /// Transforms a raw listener draft into an articulate, warm on-air radio announcement.
  Future<AmeliorationResult?> ameliorateAnnouncement({
    required String text,
    required String category,
    String? radioName,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final apiKey = AppConfig.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint('AnnouncementAiService: No Gemini key configured.');
      return null;
    }

    final prompt = '''
You are an expert radio copywriter and broadcast host for RadioHub.
Your task is to refine and ameliorate a listener announcement submitted to be read on-air.

Context:
- Category: ${category.toUpperCase()}
- Radio Station: ${radioName ?? 'Community Radio'}
- User Draft: "$clean"

Strict Broadcast Guidelines:
1. Preserve all factual information, names, dates, phone numbers, and the core emotional intent.
2. Polish the phrasing so it sounds natural, warm, and engaging when spoken aloud by a radio presenter.
3. Match the language of the draft: if French, output refined French; if English, output refined English.
4. Keep the output concise: between 25 and 55 words (~1 to 2 standard 15-second radio reading units).
5. Output ONLY the refined announcement message. Do NOT include markdown bolding, quotes, headers, or explanations.
''';

    // Model cascade: try fast lite first, fallback to flash/latest
    final candidateModels = [
      'gemini-3.1-flash-lite',
      'gemini-3.5-flash',
      'gemini-3.7-flash',
      'gemini-flash-latest',
    ];

    String? polishedText;

    for (final model in candidateModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.65,
                  'maxOutputTokens': 180,
                },
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates.first['content']?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final raw = (parts.first['text'] ?? '').toString().trim();
              if (raw.isNotEmpty) {
                // Strip optional surrounding quotation marks
                polishedText = raw.replaceAll(RegExp(r'^["“”«»]|["“”«»]$'), '').trim();
                break;
              }
            }
          }
        } else {
          debugPrint('Gemini model $model returned ${response.statusCode}, trying next model...');
        }
      } catch (e) {
        debugPrint('Gemini model $model failed with error: $e, trying fallback...');
      }
    }

    if (polishedText == null || polishedText.isEmpty) {
      return null;
    }

    final origWords = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final polWords = polishedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return AmeliorationResult(
      originalText: clean,
      polishedText: polishedText,
      originalWordCount: origWords,
      polishedWordCount: polWords,
      originalUnits: AmeliorationResult.calculateUnits(origWords),
      polishedUnits: AmeliorationResult.calculateUnits(polWords),
      originalSeconds: AmeliorationResult.calculateSeconds(origWords),
      polishedSeconds: AmeliorationResult.calculateSeconds(polWords),
    );
  }
}
