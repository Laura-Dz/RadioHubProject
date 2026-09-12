import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/technician_view_model.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final liveCount = vm.liveSessions.length;
    final totalSessions = vm.sessions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Metrics & Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                _card('Live Broadcasts', '$liveCount', Icons.live_tv, AppColors.success),
                const SizedBox(width: 16),
                _card('Total Sessions', '$totalSessions', Icons.play_circle_outline, AppColors.primary),
                const SizedBox(width: 16),
                _card('Active Programs', '${vm.programs.length}', Icons.tv, AppColors.info),
                const SizedBox(width: 16),
                _card('Active Hosts', '${vm.hosts.length}', Icons.people_outline, AppColors.gold),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Sessions Monitor',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: vm.liveSessions.isEmpty
                          ? const Center(
                              child: Text('No session is currently live.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            )
                          : ListView.builder(
                              itemCount: vm.liveSessions.length,
                              itemBuilder: (ctx, i) {
                                final s = vm.liveSessions[i];
                                return ListTile(
                                  leading: const Icon(Icons.radio, color: AppColors.success),
                                  title: Text(s.programName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('Host: ${s.hostName} · Code: ${s.sessionCode ?? "-"}'),
                                  trailing: Text('${s.listenerCount} listeners',
                                      style: const TextStyle(
                                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
