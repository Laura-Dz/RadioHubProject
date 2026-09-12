import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/technician/session_model.dart';
import '../../core/models/technician/metrics_model.dart';
import '../../view_models/technician_view_model.dart';

class TechnicianLiveStudio extends StatefulWidget {
  final Session session;

  const TechnicianLiveStudio({super.key, required this.session});

  @override
  State<TechnicianLiveStudio> createState() => _TechnicianLiveStudioState();
}

class _TechnicianLiveStudioState extends State<TechnicianLiveStudio> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Studio: ${widget.session.programName}'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricsPanel(session: widget.session, viewModel: viewModel),
          const SizedBox(height: 16),
          _CallRoutingPanel(session: widget.session, viewModel: viewModel),
          const SizedBox(height: 16),
          _UpcomingSchedulePanel(viewModel: viewModel),
          const SizedBox(height: 16),
          _ActionsPanel(session: widget.session, viewModel: viewModel),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  final Session session;
  final TechnicianViewModel viewModel;

  const _MetricsPanel({required this.session, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveMetrics>(
      stream: viewModel.streamLiveMetrics(session.id),
      builder: (context, snapshot) {
        final metrics = snapshot.data ??
            const LiveMetrics(sessionId: '');
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Live Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetricTile('Listeners', metrics.currentListeners.toString(), Icons.headset),
                    const SizedBox(width: 12),
                    _buildMetricTile('Peak', metrics.peakListeners.toString(), Icons.trending_up),
                    const SizedBox(width: 12),
                    _buildMetricTile('Comments', metrics.totalComments.toString(), Icons.comment),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetricTile('Calls', metrics.totalCalls.toString(), Icons.call),
                    const SizedBox(width: 12),
                    _buildMetricTile('Waiting', metrics.waitingCalls.toString(), Icons.hourglass_empty),
                    const SizedBox(width: 12),
                    _buildMetricTile('Accepted', metrics.acceptedCalls.toString(), Icons.check_circle),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green.shade700),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
            Text(label, style: TextStyle(color: Colors.green.shade700)),
          ],
        ),
      ),
    );
  }
}

class _CallRoutingPanel extends StatelessWidget {
  final Session session;
  final TechnicianViewModel viewModel;

  const _CallRoutingPanel({required this.session, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final waiting = viewModel.waitingCalls;
    final hosts = viewModel.hosts.where((h) {
      final matchHost = session.hostId == h.id;
      final matchCoHost = session.coHostId == h.id;
      return matchHost || matchCoHost;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📞 Call Routing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (waiting.isEmpty)
              const Text('No waiting calls', style: TextStyle(color: Colors.grey))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Waiting: ${waiting.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: hosts.map((host) {
                      return ElevatedButton.icon(
                        onPressed: () => viewModel.routeCallToHost(session.id, host.id),
                        icon: const Icon(Icons.send, size: 16),
                        label: Text('Route to ${host.name}'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSchedulePanel extends StatelessWidget {
  final TechnicianViewModel viewModel;

  const _UpcomingSchedulePanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final today = viewModel.todaySchedule;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📅 Upcoming Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (today.isEmpty)
              const Text('No sessions scheduled for today', style: TextStyle(color: Colors.grey))
            else
              Column(
                children: today.map((s) {
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: s.statusColor,
                      child: Icon(Icons.event, color: Colors.white, size: 16),
                    ),
                    title: Text(s.programName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s.timeRange} • ${s.statusLabel}'),
                    trailing: s.status == SessionStatus.scheduled
                        ? TextButton.icon(
                            onPressed: () => viewModel.startSession(s.id),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                          )
                        : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  final Session session;
  final TechnicianViewModel viewModel;

  const _ActionsPanel({required this.session, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => viewModel.endSession(session.id),
            icon: const Icon(Icons.stop),
            label: const Text('End Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRediffusionDialog(context, session),
            icon: const Icon(Icons.replay),
            label: const Text('Schedule Rediffusion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showRediffusionDialog(BuildContext context, Session session) {
    final dateController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Rediffusion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
            ),
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final date = DateTime.tryParse(dateController.text) ?? DateTime.now();
              final startParts = startController.text.split(':');
              final endParts = endController.text.split(':');
              final startTime = DateTime(date.year, date.month, date.day,
                  int.parse(startParts[0]), int.parse(startParts[1]));
              final endTime = DateTime(date.year, date.month, date.day,
                  int.parse(endParts[0]), int.parse(endParts[1]));

              viewModel.scheduleRediffusion(
                sessionId: session.id,
                date: date,
                startTime: startTime,
                endTime: endTime,
              );
              Navigator.pop(context);
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}
