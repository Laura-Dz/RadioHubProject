import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Structured result of a content moderation check.
class ModerationCheckResult {
  final bool passed;
  final bool isEmpty;
  final bool isTooLong;
  final List<String> flaggedCategories;
  final String? rejectionReason;

  const ModerationCheckResult({
    required this.passed,
    this.isEmpty = false,
    this.isTooLong = false,
    this.flaggedCategories = const [],
    this.rejectionReason,
  });

  factory ModerationCheckResult.clean() => const ModerationCheckResult(passed: true);

  factory ModerationCheckResult.empty() => const ModerationCheckResult(
        passed: false,
        isEmpty: true,
        rejectionReason: "We can't send an empty message.",
      );

  factory ModerationCheckResult.tooLong(int maxChars) => ModerationCheckResult(
        passed: false,
        isTooLong: true,
        rejectionReason: 'Message is too long (maximum $maxChars characters).',
      );

  factory ModerationCheckResult.flagged(List<String> categories) {
    final readable = categories.map(_formatCategory).toSet().join(', ');
    return ModerationCheckResult(
      passed: false,
      flaggedCategories: categories,
      rejectionReason:
          'Your message violates community standards ($readable). Please revise it to proceed.',
    );
  }

  String get readableCategories =>
      flaggedCategories.map(_formatCategory).toSet().join(', ');

  static String _formatCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('hate')) return 'Hate Speech';
    if (c.contains('harass') || c.contains('profan')) return 'Harassment & Profanity';
    if (c.contains('violen') || c.contains('threat')) return 'Violence & Threats';
    if (c.contains('sex') || c.contains('adult')) return 'Inappropriate Content';
    if (c.contains('self-harm')) return 'Self-Harm';
    return cat;
  }
}

/// Comprehensive Content Moderation Service supporting instant local heuristics
/// (English & French) and online OpenAI Moderation API.
class ContentModerationService {
  static final http.Client _client = http.Client();

  // Local regex rules for instant, offline & sandbox-resilient filtering
  static final List<RegExp> _hateSpeechPatterns = [
    RegExp(
      r'\bhate\s+(all\s+)?(black|white|asian|jew|jews|muslim|muslims|christian|christians|african|africans|gay|gays|lgbt|women|men|anglophone|anglophones|francophone|francophones|bamileke|beti|hausa|fulani)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\bi\s+hate\s+.*(people|race|tribe|ethnic|religion)',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(nigger|nigga|kike|faggot|chink|gook|spic|coon)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(sale\s+(noir|blanc|juif|arabe)|mort\s+aux)\b',
      caseSensitive: false,
    ),
  ];

  static final List<RegExp> _harassmentProfanityPatterns = [
    RegExp(
      r'\b(fuck(\s+you|\s+off|\s+u)?|fucking|motherfucker|bitch|bastard|asshole|cunt|dickhead|whore|slut)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(va\s+te\s+faire\s+foutre|encul[eé]|fils\s+de\s+pute|connard|salope|pute|bâtard)\b',
      caseSensitive: false,
    ),
  ];

  static final List<RegExp> _violencePatterns = [
    RegExp(
      r'\b(kill\s+(you|all|them)|i(\x27ll|\s+will)\s+kill|gonna\s+kill|murder\s+you|shoot\s+you|bomb|terrorist)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(je\s+vais\s+te\s+tuer|mort\s+[àa]|égorger)\b',
      caseSensitive: false,
    ),
  ];

  /// Validates and moderates text. Returns ModerationCheckResult.
  static Future<ModerationCheckResult> check(
    String rawText, {
    int maxChars = 500,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return ModerationCheckResult.empty();
    }

    if (text.length > maxChars) {
      return ModerationCheckResult.tooLong(maxChars);
    }

    // 1. Fast Local Heuristics
    final flaggedCategories = <String>[];

    for (final pattern in _hateSpeechPatterns) {
      if (pattern.hasMatch(text)) {
        flaggedCategories.add('hate');
        break;
      }
    }

    for (final pattern in _harassmentProfanityPatterns) {
      if (pattern.hasMatch(text)) {
        flaggedCategories.add('harassment');
        break;
      }
    }

    for (final pattern in _violencePatterns) {
      if (pattern.hasMatch(text)) {
        flaggedCategories.add('violence');
        break;
      }
    }

    if (flaggedCategories.isNotEmpty) {
      return ModerationCheckResult.flagged(flaggedCategories);
    }

    // 2. Remote OpenAI Moderation API (if key is configured and reachable)
    final apiKey = AppConfig.openaiApiKey.trim();
    if (apiKey.isNotEmpty) {
      try {
        final response = await _client
            .post(
              Uri.parse('https://api.openai.com/v1/moderations'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({
                'input': text,
                'model': 'omni-moderation-latest',
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            if (first['flagged'] == true) {
              final catMap = first['categories'] as Map<String, dynamic>? ?? {};
              final remoteFlags = <String>[];
              catMap.forEach((k, v) {
                if (v == true) remoteFlags.add(k);
              });
              if (remoteFlags.isNotEmpty) {
                return ModerationCheckResult.flagged(remoteFlags);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('OpenAI Moderation fallback notice: $e');
      }
    }

    return ModerationCheckResult.clean();
  }

  /// Sends a moderation alert notification to the user's notification center in Firestore.
  static Future<void> recordModerationNotification({
    required String userId,
    required String flaggedMessage,
    required String categories,
    String contextType = 'comment',
  }) async {
    if (userId.isEmpty || userId == 'anonymous') return;
    try {
      final preview = flaggedMessage.length > 50
          ? '${flaggedMessage.substring(0, 47)}…'
          : flaggedMessage;

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'moderationAlert',
        'title': '⚠️ Message Blocked by Moderation',
        'body':
            'Your $contextType ("$preview") was blocked from broadcasting because it violated community guidelines ($categories).',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'context': contextType,
          'categories': categories,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (e) {
      debugPrint('Failed to save moderation notification: $e');
    }
  }
}
