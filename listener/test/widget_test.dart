// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listener/core/services/shared_preferences_service.dart';
import 'package:listener/core/services/localization_service.dart';
import 'package:listener/core/services/firestore_service.dart';
import 'package:listener/core/services/storage_service.dart';
import 'package:listener/core/services/metadata_service.dart';
import 'package:listener/core/services/realtime_database_service.dart';
import 'package:listener/core/services/user_interaction_service.dart';
import 'package:listener/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsService = SharedPreferencesService(prefs);
    final localizationService = LocalizationService();
    final firestoreService = FirestoreService();
    final storageService = StorageService();
    final metadataService = MetadataService();
    final realtimeDbService = RealtimeDatabaseService();
    final userInteractionService = UserInteractionService();

    await tester.pumpWidget(MyApp(
      prefsService: prefsService,
      localizationService: localizationService,
      firestoreService: firestoreService,
      storageService: storageService,
      metadataService: metadataService,
      realtimeDbService: realtimeDbService,
      userInteractionService: userInteractionService,
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
