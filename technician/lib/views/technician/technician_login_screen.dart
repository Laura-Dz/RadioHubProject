import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../view_models/technician_view_model.dart';
import 'technician_dashboard.dart';

class TechnicianLoginScreen extends StatefulWidget {
  const TechnicianLoginScreen({Key? key}) : super(key: key);
  @override
  State<TechnicianLoginScreen> createState() => _State();
}

class _State extends State<TechnicianLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.settings_input_antenna,
                          color: AppColors.primary, size: 30),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Technician',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Sign in to manage sessions',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Email', Icons.mail_outline),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _dec('Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.error))),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign in',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Station Technicians:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('• christian@example.com (Radio Love)\n• john@radiolove.cm (Radio Love)',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    final rawEmail = _email.text.trim();
    final cleanEmail = rawEmail.toLowerCase();
    final password = _password.text;

    try {
      UserCredential? cred;
      try {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        debugPrint('Sign in attempt failed: [${authErr.code}] ${authErr.message}');

        // If credentials failed or user not found, check if technician is registered in Firestore
        if (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') {
          // Look up user by lowercase or original email
          var snap = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: cleanEmail)
              .limit(1)
              .get();

          if (snap.docs.isEmpty) {
            snap = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: rawEmail)
                .limit(1)
                .get();
          }

          if (snap.docs.isEmpty) {
            throw Exception('No account found for $rawEmail in the database. Please ask your Radio Administrator to add you.');
          }

          final dbRole = (snap.docs.first.data()['role'] ?? '').toString().toLowerCase();
          if (dbRole != 'technician') {
            throw Exception('This email is registered as "$dbRole", not a technician.');
          }

          // The user exists in Firestore as a technician! Attempt to create/activate their Firebase Auth user
          try {
            cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: cleanEmail,
              password: password,
            );
            debugPrint('Auto-activated Firebase Auth user for $cleanEmail');
          } on FirebaseAuthException catch (createErr) {
            if (createErr.code == 'email-already-in-use') {
              // The Auth user already exists, so the password was wrong
              throw Exception('Incorrect password for $cleanEmail.');
            } else {
              throw Exception(createErr.message ?? 'Authentication error: ${createErr.code}');
            }
          }
        } else {
          rethrow;
        }
      }

      final uid = cred.user!.uid;

      // 1. Look up user doc in Firestore by Auth UID
      var userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();

      // 2. Fallback: look up by email
      if (!userDoc.exists || userDoc.data() == null) {
        var emailSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (emailSnap.docs.isEmpty) {
          emailSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: rawEmail)
              .limit(1)
              .get();
        }

        if (emailSnap.docs.isNotEmpty) {
          userDoc = emailSnap.docs.first;
          // Link this auth UID to the Firestore record (non-fatal if restricted)
          try {
            await userDoc.reference.set({'authUid': uid, 'uid': uid}, SetOptions(merge: true));
          } catch (e) {
            debugPrint('Non-fatal: could not link authUid to doc: $e');
          }
        }
      }

      final data = userDoc.data();
      if (data == null) {
        await FirebaseAuth.instance.signOut();
        throw Exception('User record not found in Firestore database. Contact your Radio Administrator.');
      }

      final role = (data['role'] ?? '').toString().toLowerCase();
      if (role != 'technician') {
        // Also check custom claims as fallback
        final tokenResult = await cred.user!.getIdTokenResult();
        final claimRole = tokenResult.claims?['role'];
        if (claimRole != 'technician') {
          await FirebaseAuth.instance.signOut();
          throw Exception('This account is registered as "$role", not a technician.');
        }
      }

      final radioId = data['radioId'] as String?;
      final radioName = (data['radioName'] ?? 'Radio Station') as String;
      final name = (data['displayName'] ?? data['name'] ?? 'Technician') as String;
      final photoUrl = data['photoUrl'] as String?;

      if (radioId == null || radioId.isEmpty) {
        await FirebaseAuth.instance.signOut();
        throw Exception('No radio station assigned to your technician account. Contact your administrator.');
      }

      if (!mounted) return;
      context.read<TechnicianViewModel>().initialize(
            radioId: radioId,
            radioName: radioName,
            technicianName: name,
            technicianPhotoUrl: photoUrl,
          );

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TechnicianDashboard(radioId: radioId, radioName: radioName),
      ));
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: [${e.code}] ${e.message}');
      setState(() => _error = _msg(e.code, e.message));
    } catch (e) {
      debugPrint('Login exception: $e');
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _msg(String code, [String? fallback]) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' || 'invalid-credential' => 'Incorrect credentials. Please verify your email and password.',
        'too-many-requests' => 'Too many failed sign-in attempts. Please try again later.',
        'user-disabled' => 'This account has been disabled. Contact your administrator.',
        'invalid-email' => 'The email address format is invalid.',
        _ => fallback ?? 'Sign in failed ($code).',
      };
}