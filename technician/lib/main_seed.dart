import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/data_seeder.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    final seeder = DataSeeder();
    await seeder.seedAllData();
    print('\n✅ Seeding completed!');
  } catch (e, stack) {
    print('\n❌ Seeding failed: $e');
    print(stack);
    exit(1);
  }
  exit(0);
}
