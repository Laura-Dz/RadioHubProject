import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/firestore_service.dart';
import '../core/services/shared_preferences_service.dart';
import '../core/utils/validators.dart';
import 'base_view_model.dart';

class RegisterViewModel extends BaseViewModel {
  final FirestoreService _firestoreService;
  final SharedPreferencesService _prefsService;

  RegisterViewModel({
    required FirestoreService firestoreService,
    required SharedPreferencesService prefsService,
  })  : _firestoreService = firestoreService,
        _prefsService = prefsService;

  Future<void> register(String email, String password, String displayName) async {
    await execute(() async {
      final user = await _firestoreService.registerWithEmail(
        email,
        password,
        displayName,
      );
      _currentUser = user;
      await _prefsService.setUserId(user.id);
    });
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
}
