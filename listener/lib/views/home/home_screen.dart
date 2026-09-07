import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio Stream'),
        actions: [
          if (!authViewModel.isGuest)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {},
            ),
          if (authViewModel.isGuest)
            TextButton(
              onPressed: () {},
              child: const Text('Sign In'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authViewModel.logout();
              if (!authViewModel.hasError && mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Welcome ${authViewModel.currentUser?.displayName ?? 'Guest'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              authViewModel.isGuest ? 'Guest Mode' : 'Listener Mode',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Live streams will appear here\n\nCheck back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
