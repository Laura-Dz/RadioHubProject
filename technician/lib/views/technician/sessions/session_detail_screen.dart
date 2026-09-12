import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/constants/app_colors.dart';

class SessionDetailScreen extends StatelessWidget {
  final Session session;
  const SessionDetailScreen({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    // Get the freshest version from the stream
    final live = vm.sessions.firstWhere((s) => s.id == session.id,
        orElse: () => session);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(live.programName),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _statusChip(live),
                          const Spacer(),
                          if (live.isLive && live.sessionCode != null)
                            _codeChip(live.sessionCode!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(live.programName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('EEEE d MMMM').format(live.scheduledStart)} • ${DateFormat('HH:mm').format(live.scheduledStart)} – ${DateFormat('HH:mm').format(live.scheduledEnd)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Details
                _section('Session details', [
                  _row('Host', live.hostName),
                  if (live.guestName != null) _row('Guest', live.guestName!),
                  if (live.guestRole != null) _row('Guest role', live.guestRole!),
                  if (live.format != null) _row('Format', live.format!.replaceAll('_', ' ')),
                  if (live.thematic != null) _row('Thematic', live.thematic!),
                ]),
                if (live.description != null) ...[
                  const SizedBox(height: 16),
                  _section('Description', [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(live.description!,
                          style: const TextStyle(fontSize: 13.5)),
                    ),
                  ]),
                ],

                // Action buttons
                const SizedBox(height: 24),
                if (live.status == SessionStatus.scheduled &&
                    !live.isRediffusion &&
                    live.canBeStarted)
                  ElevatedButton.icon(
                    onPressed: () => _start(context, vm, live),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else if (live.status == SessionStatus.scheduled &&
                    !live.canBeStarted &&
                    !live.isRediffusion)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.info.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 18, color: AppColors.info),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Can be started 5 minutes before ${DateFormat('HH:mm').format(live.scheduledStart)}.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (live.isLive)
                  ElevatedButton.icon(
                    onPressed: () => _end(context, vm, live),
                    icon: const Icon(Icons.stop),
                    label: const Text('End session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(Session s) {
    final (color, label) = switch (s.status) {
      SessionStatus.live => (AppColors.success, 'Live'),
      SessionStatus.scheduled => (AppColors.primary, 'Scheduled'),
      SessionStatus.ended => (AppColors.textMuted, 'Ended'),
      SessionStatus.cancelled => (AppColors.error, 'Cancelled'),
      SessionStatus.rediffusion => (AppColors.gold, 'Rediffusion'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _codeChip(String code) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Host code: $code',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _section(String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ),
            Expanded(child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Future<void> _start(BuildContext context, TechnicianViewModel vm, Session s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start session?'),
        content: const Text(
          'The session will go live and a host access code will be generated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final code = await vm.startSession(s.id);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Session started'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this code with the host:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _end(BuildContext context, TechnicianViewModel vm, Session s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('The session will close and the host code will be invalidated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('End'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await vm.endSession(s.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session ended'), backgroundColor: AppColors.info),
    );
  }
}