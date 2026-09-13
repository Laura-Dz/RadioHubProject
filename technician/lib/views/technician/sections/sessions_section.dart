import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../view_models/technician_view_model.dart';

class SessionsSection extends StatelessWidget {
  const SessionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Sessions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                title: 'Live',
                count: viewModel.liveSessions.length,
                color: Colors.green,
                icon: Icons.podcasts,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'Past',
                count: viewModel.pastSessions.length,
                color: Colors.red,
                icon: Icons.history,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'All',
                count: viewModel.sessions.length,
                color: Colors.blue,
                icon: Icons.list,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.sessions.length,
              itemBuilder: (context, index) {
                final s = viewModel.sessions[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: s.statusColor,
                      child: const Icon(Icons.event, color: Colors.white),
                    ),
                    title: Text(s.programName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.timeRange} • ${s.statusLabel}${s.hostName != null ? " • ${s.hostName}" : ""}'),
                    trailing: _buildActions(viewModel, s),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(TechnicianViewModel vm, Session s) {
    if (s.status == SessionStatus.scheduled) {
      return ElevatedButton.icon(
        onPressed: () => vm.startSession(s.id),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Start'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      );
    } else if (s.status == SessionStatus.onAir) {
      return ElevatedButton.icon(
        onPressed: () => vm.endSession(s.id),
        icon: const Icon(Icons.stop, size: 16),
        label: const Text('End'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  const _StatCard({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
