import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/host_auth_service.dart';
import '../../view_models/host_view_model.dart';
import '../ended/session_ended_screen.dart';
import 'widgets/comments_column.dart';
import 'widgets/live_broadcast_timer.dart';
import 'widgets/side_panel.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);
  @override
  State<SessionScreen> createState() => _State();
}

class _State extends State<SessionScreen> {
  bool _navigatedToEnded = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();
    final session = vm.session;

    // Auto-navigate when session ends
    if (session != null && session.isEnded && !_navigatedToEnded) {
      _navigatedToEnded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await HostAuthService().logout();
        vm.disposeStreams();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SessionEndedScreen()),
          (_) => false,
        );
      });
    }

    // Error snackbar
    if (vm.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        vm.clearError();
      });
    }

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic, color: AppColors.success, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.programName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const Text('Host Studio',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          LiveBroadcastTimerBadge(
            scheduledStart: session.scheduledStart,
            scheduledEnd: session.scheduledEnd,
            isLive: session.isOnAir,
          ),
          const SizedBox(width: 8),
          const _OnAirPill(),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: CommentsColumn()),
          const SizedBox(width: 1),
          SizedBox(
            width: 380,
            child: SidePanel(),
          ),
        ],
      ),
    );
  }
}

class _OnAirPill extends StatelessWidget {
  const _OnAirPill();

  @override
  Widget build(BuildContext context) {
    final onAir = context.watch<HostViewModel>().session?.isOnAir ?? false;
    if (!onAir) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Waiting',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniDot(),
          SizedBox(width: 6),
          Text('ON AIR',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _MiniDot extends StatefulWidget {
  const _MiniDot();
  @override
  State<_MiniDot> createState() => _MiniDotState();
}

class _MiniDotState extends State<_MiniDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
              color: AppColors.error, shape: BoxShape.circle),
        ),
      );
}
