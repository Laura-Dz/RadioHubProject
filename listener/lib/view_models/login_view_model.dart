import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/firestore_service.dart';
import '../core/services/shared_preferences_service.dart';
import '../core/utils/validators.dart';
import 'base_view_model.dart';

class LoginViewModel extends BaseViewModel {
  final FirestoreService _firestoreService;
  final SharedPreferencesService _prefsService;

  LoginViewModel({
    required FirestoreService firestoreService,
    required SharedPreferencesService prefsService,
  })  : _firestoreService = firestoreService,
        _prefsService = prefsService;

  Future<void> login(String email, String password) async {
    await execute(() async {
      final user = await _firestoreService.loginWithEmail(email, password);
      _currentUser = user;
      await _prefsService.setUserId(user.id);
    });
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
}
