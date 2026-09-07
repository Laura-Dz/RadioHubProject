import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../core/services/shared_preferences_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../main_layout/main_layout_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.radio, size: 64, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access your favorite shows\nand personalized content',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: authViewModel.isLoading
                    ? null
                    : () async {
                        await authViewModel.loginAsGuest();
                        if (!authViewModel.hasError && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
                          );
                        }
                      },
                child: authViewModel.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue as Guest', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      context.read<SharedPreferencesService>().getLanguage()?.toUpperCase() ?? 'EN',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Change',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              if (authViewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authViewModel.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
