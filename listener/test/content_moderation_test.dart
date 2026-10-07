import 'package:flutter_test/flutter_test.dart';
import 'package:listener/core/services/content_moderation_service.dart';

void main() {
  group('Content Moderation Tests', () {
    test('Empty message is rejected with empty reason', () async {
      final res = await ContentModerationService.check('');
      expect(res.passed, isFalse);
      expect(res.isEmpty, isTrue);
      expect(res.rejectionReason, contains("can't send an empty message"));

      final whitespaceRes = await ContentModerationService.check('    ');
      expect(whitespaceRes.passed, isFalse);
      expect(whitespaceRes.isEmpty, isTrue);
    });

    test('Profanity "fuck you" is flagged as harassment/profanity', () async {
      final res = await ContentModerationService.check('fuck you');
      expect(res.passed, isFalse);
      expect(res.flaggedCategories, contains('harassment'));
      expect(res.readableCategories, contains('Harassment & Profanity'));
      expect(res.rejectionReason, contains('violates community standards'));
    });

    test('Hate speech "i hate black people" is flagged as hate speech', () async {
      final res = await ContentModerationService.check('i hate black people');
      expect(res.passed, isFalse);
      expect(res.flaggedCategories, contains('hate'));
      expect(res.readableCategories, contains('Hate Speech'));
      expect(res.rejectionReason, contains('violates community standards'));
    });

    test('Clean positive message passes', () async {
      final res = await ContentModerationService.check('Hello radio host, I really love this morning broadcast!');
      expect(res.passed, isTrue);
      expect(res.flaggedCategories, isEmpty);
      expect(res.rejectionReason, isNull);
    });
  });
}
