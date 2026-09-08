import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';

class MetricsSection extends StatelessWidget {
  const MetricsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();
    final live = viewModel.liveSessions;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Live Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (live.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No active live sessions.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: live.length,
                itemBuilder: (context, index) {
                  final s = live[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.podcasts, color: Colors.green, size: 32),
                      title: Text(s.programName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Host: ${s.hostName ?? "—"} • ${s.timeRange}'),
                      trailing: ElevatedButton(
                         onPressed: () => viewModel.getLiveMetrics(s.id).then((m) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('${s.programName} metrics'),
                              content: Text(m.currentListeners == 0 && m.totalComments == 0
                                  ? 'No metrics yet.'
                                  : 'Listeners: ${m.currentListeners}, Peak: ${m.peakListeners}, Comments: ${m.totalComments}'),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                            ),
                          );
                        }),
                        child: const Text('View'),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
