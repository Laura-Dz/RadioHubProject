import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../core/services/shared_preferences_service.dart';
import 'language_selection/language_selection_screen.dart';
import 'auth/auth_choice_screen.dart';
import 'main_layout/main_layout_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    final prefsService = context.read<SharedPreferencesService>();
    final authViewModel = context.read<AuthViewModel>();

    await Future.delayed(const Duration(seconds: 2));

    if (prefsService.isFirstLaunch()) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );
      }
      return;
    }

    await authViewModel.loadUser();

    if (mounted) {
      if (authViewModel.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radio, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Radio Stream',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Live Radio & Podcasts',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
