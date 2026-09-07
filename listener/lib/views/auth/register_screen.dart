import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/register_view_model.dart';
import '../../core/utils/validators.dart';
import '../main_layout/main_layout_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), elevation: 0),
      body: Consumer<RegisterViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Get Started',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to start listening',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateName,
                    enabled: !viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateEmail,
                    enabled: !viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: Validators.validatePassword,
                    enabled: !viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    enabled: !viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: viewModel.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                              },
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (viewModel.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
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
                              viewModel.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading || !_acceptedTerms
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                await viewModel.register(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                  _nameController.text.trim(),
                                );
                                if (!viewModel.hasError && mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
