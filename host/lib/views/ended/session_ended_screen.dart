import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SessionEndedScreen extends StatefulWidget {
  const SessionEndedScreen({Key? key}) : super(key: key);
  @override
  State<SessionEndedScreen> createState() => _State();
}

class _State extends State<SessionEndedScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-return to entry after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text('Session ended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Thank you for going on air. Returning to entry…',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
