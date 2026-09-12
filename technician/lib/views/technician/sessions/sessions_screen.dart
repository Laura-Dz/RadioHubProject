import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/constants/app_colors.dart';
import 'create_session_modal.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({Key? key}) : super(key: key);
  @override
  State<SessionsScreen> createState() => _State();
}

class _State extends State<SessionsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    final filtered = vm.sessions.where((s) {
      if (_filter == 'all') return true;
      if (_filter == 'live') return s.status == SessionStatus.live;
      if (_filter == 'scheduled') return s.status == SessionStatus.scheduled;
      if (_filter == 'ended') return s.status == SessionStatus.ended;
      if (_filter == 'rediffusion') return s.isRediffusion;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sessions'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => const CreateSessionModal(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filter chips
            Row(
              children: [
                _chip('All', 'all'),
                const SizedBox(width: 8),
                _chip('Live', 'live'),
                const SizedBox(width: 8),
                _chip('Scheduled', 'scheduled'),
                const SizedBox(width: 8),
                _chip('Ended', 'ended'),
                const SizedBox(width: 8),
                _chip('Rediffusion', 'rediffusion'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? _empty()
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _SessionRow(session: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final sel = _filter == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withOpacity(0.12),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
        labelStyle: TextStyle(
          color: sel ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 72,
                color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No sessions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Create one, or generate from the timetable.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _SessionRow extends StatefulWidget {
  final Session session;
  const _SessionRow({required this.session});
  @override
  State<_SessionRow> createState() => _RowState();
}

class _RowState extends State<_SessionRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: s),
        )),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? AppColors.hover : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.isLive
                  ? AppColors.success.withOpacity(0.4)
                  : (_hover ? AppColors.primary.withOpacity(0.3) : AppColors.border),
              width: s.isLive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(s).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(s), color: _statusColor(s), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(s.programName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (s.isRediffusion) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('REDIFFUSION',
                                style: TextStyle(fontSize: 9, color: AppColors.gold,
                                    fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${s.hostName}${s.guestName != null ? ' + ${s.guestName}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEE d MMM').format(s.scheduledStart),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    Text(
                      '${DateFormat('HH:mm').format(s.scheduledStart)} – ${DateFormat('HH:mm').format(s.scheduledEnd)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _statusBadge(s),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(Session s) {
    if (s.isRediffusion) return AppColors.gold;
    switch (s.status) {
      case SessionStatus.live: return AppColors.success;
      case SessionStatus.scheduled: return AppColors.primary;
      case SessionStatus.ended: return AppColors.textMuted;
      case SessionStatus.cancelled: return AppColors.error;
      case SessionStatus.rediffusion: return AppColors.gold;
    }
  }

  IconData _statusIcon(Session s) {
    if (s.isRediffusion) return Icons.replay;
    switch (s.status) {
      case SessionStatus.live: return Icons.play_circle;
      case SessionStatus.scheduled: return Icons.schedule;
      case SessionStatus.ended: return Icons.check_circle_outline;
      case SessionStatus.cancelled: return Icons.cancel_outlined;
      case SessionStatus.rediffusion: return Icons.replay;
    }
  }

  Widget _statusBadge(Session s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.statusLabel,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}