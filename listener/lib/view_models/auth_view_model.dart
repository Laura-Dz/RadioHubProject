import '../core/models/user_model.dart';
import '../core/services/firestore_service.dart';
import '../core/services/shared_preferences_service.dart';
import 'base_view_model.dart';

class AuthViewModel extends BaseViewModel {
  final FirestoreService _firestoreService;
  final SharedPreferencesService _prefsService;

  UserModel? _currentUser;

  AuthViewModel({
    required FirestoreService firestoreService,
    required SharedPreferencesService prefsService,
  })  : _firestoreService = firestoreService,
        _prefsService = prefsService;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;

  Future<void> loadUser() async {
    await execute(() async {
      final user = await _firestoreService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        await _prefsService.setUserId(user.id);
      }
    });
  }

  Future<void> login(String email, String password) async {
    await execute(() async {
      final user = await _firestoreService.loginWithEmail(email, password);
      _currentUser = user;
      await _prefsService.setUserId(user.id);
    });
  }

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

  Future<void> loginAsGuest() async {
    await execute(() async {
      final user = await _firestoreService.signInAnonymously();
      _currentUser = user;
      await _prefsService.setUserId(user.id);
    });
  }

  Future<void> logout() async {
    await execute(() async {
      await _firestoreService.signOut();
      await _prefsService.clearAll();
      _currentUser = null;
    });
  }

  bool hasSubscription() {
    return _currentUser?.subscription != null &&
        _currentUser?.subscription != 'free';
  }

  Future<List<String>> getFollowedChannels() async {
    if (_currentUser == null) return [];
    return [];
  }
}
