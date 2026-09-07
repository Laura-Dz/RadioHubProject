import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../view_models/technician_view_model.dart';
import '../widgets/weekly_schedule.dart';

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();
    final weekStart = viewModel.selectedWeek
        .subtract(Duration(days: viewModel.selectedWeek.weekday - 1));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 22),
              const SizedBox(width: 8),
              const Text('Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                'Week of ${_formatDate(weekStart)} - ${_formatDate(weekStart.add(const Duration(days: 6)))}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: viewModel.goToPreviousWeek,
              ),
              ElevatedButton(
                onPressed: viewModel.goToToday,
                child: const Text('Today'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: viewModel.goToNextWeek,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _LegendDot(color: Colors.blue, label: 'Scheduled'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.green, label: 'Live'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.orange, label: 'Paused'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.red, label: 'Ended'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.purple, label: 'Rediffusion'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: WeeklySchedule(
              schedule: viewModel.weeklySchedule,
              selectedWeek: viewModel.selectedWeek,
              onSlotTap: (date, hour) => _createSession(context, viewModel, date, hour),
              onSessionTap: (session) => _showSessionActions(context, viewModel, session),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createSession(BuildContext context, TechnicianViewModel vm, DateTime date, int hour) async {
    final session = await showDialog<Session>(
      context: context,
      builder: (ctx) => _CreateSessionDialog(date: date, hour: hour, viewModel: vm),
    );
    if (session != null) {
      await vm.createSession(session);
    }
  }

  Future<void> _showSessionActions(BuildContext context, TechnicianViewModel vm, Session session) async {
    await showDialog(
      context: context,
      builder: (ctx) => _SessionActionsDialog(session: session, viewModel: vm),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _CreateSessionDialog extends StatefulWidget {
  final DateTime date;
  final int hour;
  final TechnicianViewModel viewModel;
  const _CreateSessionDialog({required this.date, required this.hour, required this.viewModel});

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  String? _programId;
  String? _hostId;
  final _thematic = TextEditingController();
  final _description = TextEditingController();
  bool _isInteractive = false;

  @override
  void dispose() {
    _thematic.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('✨ Create Session – ${widget.hour.toString().padLeft(2, '0')}:00'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _programId,
                items: widget.viewModel.programs
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _programId = v),
                decoration: const InputDecoration(labelText: 'Program', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _hostId,
                items: widget.viewModel.hosts
                    .map((h) => DropdownMenuItem(value: h.id, child: Text(h.name)))
                    .toList(),
                onChanged: (v) => setState(() => _hostId = v),
                decoration: const InputDecoration(labelText: 'Host', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _thematic,
                decoration: const InputDecoration(labelText: 'Thematic', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              CheckboxListTile(
                value: _isInteractive,
                onChanged: (v) => setState(() => _isInteractive = v ?? false),
                title: const Text('Interactive (call-ins allowed)'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_programId == null) return;
            final program = widget.viewModel.programs.firstWhere((p) => p.id == _programId);
            final host = _hostId != null
                ? widget.viewModel.hosts.firstWhere((h) => h.id == _hostId)
                : null;
            final session = Session(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              programId: _programId!,
              programName: program.name,
              date: widget.date,
              startTime: DateTime(widget.date.year, widget.date.month, widget.date.day, widget.hour),
              endTime: DateTime(widget.date.year, widget.date.month, widget.date.day, widget.hour + 1),
              hostId: host?.id,
              hostName: host?.name,
              thematic: _thematic.text,
              description: _description.text,
              isInteractive: _isInteractive,
              status: SessionStatus.scheduled,
              createdAt: DateTime.now(),
            );
            Navigator.pop(context, session);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SessionActionsDialog extends StatelessWidget {
  final Session session;
  final TechnicianViewModel viewModel;
  const _SessionActionsDialog({required this.session, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(session.programName),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Status: ${session.statusLabel}'),
          Text('Time: ${session.timeRange}'),
          if (session.hostName != null) Text('Host: ${session.hostName}'),
          if (session.thematic != null) Text('Thematic: ${session.thematic}'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (session.status == SessionStatus.scheduled)
          ElevatedButton(
            onPressed: () async {
              await viewModel.startSession(session.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('🚀 Start Live'),
          ),
        if (session.status == SessionStatus.live)
          ElevatedButton(
            onPressed: () async {
              await viewModel.endSession(session.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('⏹ End'),
          ),
      ],
    );
  }
}
