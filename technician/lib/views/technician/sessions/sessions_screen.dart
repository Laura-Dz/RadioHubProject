import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/services/network_time_service.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/live_broadcast_timer.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live sessions'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await vm.refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============ ON AIR ============
              _sectionHeader('On air', Icons.radio_button_checked,
                  vm.currentLiveSession != null
                      ? AppColors.success
                      : AppColors.textMuted),
              const SizedBox(height: 8),
              if (vm.currentLiveSession != null)
                _LiveCard(session: vm.currentLiveSession!)
              else
                const _NoLiveBanner(),
              const SizedBox(height: 24),

              // ============ UPCOMING ============
              _sectionHeader(
                'Upcoming · next 24h',
                Icons.schedule,
                AppColors.primary,
                count: vm.upcomingSessions.length,
                loading: vm.loadingUpcoming,
              ),
              const SizedBox(height: 8),
              if (vm.loadingUpcoming)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else if (vm.upcomingSessions.isEmpty)
                const _EmptyLine('No upcoming sessions.')
              else
                ...vm.upcomingSessions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _UpcomingCard(session: s),
                    )),
              const SizedBox(height: 24),

              // ============ RECENTLY ENDED ============
              _sectionHeader(
                'Recently ended',
                Icons.check_circle_outline,
                AppColors.textMuted,
                count: vm.recentEndedSessions.length,
              ),
              const SizedBox(height: 8),
              if (vm.recentEndedSessions.isEmpty)
                const _EmptyLine('No ended sessions yet.')
              else
                ...vm.recentEndedSessions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _EndedCard(session: s),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color color, {
    int? count,
    bool loading = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        if (loading) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ] else if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// LIVE CARD — with End button
// ============================================================

class _LiveCard extends StatefulWidget {
  final Session session;
  const _LiveCard({required this.session});

  @override
  State<_LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends State<_LiveCard> {
  bool _isOvertime = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final primaryColor = _isOvertime ? AppColors.error : AppColors.success;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.12),
            primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isOvertime ? AppColors.error : AppColors.success.withOpacity(0.4),
          width: _isOvertime ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pulsingDot(color: primaryColor),
              const SizedBox(width: 8),
              Text(
                _isOvertime ? 'ON AIR · OVERRUN' : 'ON AIR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              LiveBroadcastTimer(
                scheduledStart: session.scheduledStart,
                scheduledEnd: session.scheduledEnd,
                isLive: true,
                isCompact: true,
                onOvertimeChanged: (overtime) {
                  if (mounted && _isOvertime != overtime) {
                    setState(() => _isOvertime = overtime);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(session.programName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${session.hostName}'
            '${session.coHostNames.isNotEmpty ? " + ${session.coHostNames.join(", ")}" : ""}'
            '${session.guestName != null ? " · Guest: ${session.guestName}" : ""}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          if (session.thematic != null) ...[
            const SizedBox(height: 6),
            Text('Thematic: ${session.thematic}',
                style: const TextStyle(
                    fontSize: 12.5, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          // Prominent studio live timer
          LiveBroadcastTimer(
            scheduledStart: session.scheduledStart,
            scheduledEnd: session.scheduledEnd,
            isLive: true,
            isCompact: false,
          ),
          if (session.sessionCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key, size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Host code: ${session.sessionCode}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionDetailScreen(session: session),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _endSession(context, session),
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('End session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pulsingDot({Color color = AppColors.success}) {
    return _PulsingDot(color: color);
  }

  static Future<void> _endSession(BuildContext context, Session s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End session?'),
        content: Text(
          'This will conclude "${s.programName}" and invalidate the host access code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            label: const Text('End'),
            icon: const Icon(Icons.stop, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<TechnicianViewModel>().endSession(s.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Session ended'),
            backgroundColor: AppColors.info),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error),
      );
    }
  }
}

// ============================================================
// UPCOMING CARD — Start button gated by time window
// ============================================================

class _UpcomingCard extends StatefulWidget {
  final Session session;
  const _UpcomingCard({required this.session});
  @override
  State<_UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends State<_UpcomingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final vm = context.watch<TechnicianViewModel>();
    final ready = s.canBeStarted;
    final anotherLive = vm.currentLiveSession != null;

    final canStart = ready && !anotherLive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hover ? AppColors.hover : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ready
                ? AppColors.success.withOpacity(0.4)
                : AppColors.border,
            width: ready ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Left icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: ready
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ready ? Icons.play_circle_outline : Icons.schedule,
                color: ready ? AppColors.success : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.programName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${s.hostName}'
                    '${s.coHostNames.isNotEmpty ? " + ${s.coHostNames.join(", ")}" : ""}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('EEE d MMM').format(s.scheduledStart)} · '
                        '${DateFormat('HH:mm').format(s.scheduledStart)}–'
                        '${DateFormat('HH:mm').format(s.scheduledEnd)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ready
                              ? AppColors.success.withOpacity(0.15)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ready ? 'Ready to start' : s.countdownLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: ready
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: start button
            const SizedBox(width: 12),
            Tooltip(
              message: ready
                  ? (anotherLive
                      ? 'End the currently live session first'
                      : 'Start this session')
                  : 'Available within 5 min of start time',
              child: ElevatedButton.icon(
                onPressed: canStart ? () => _start(context, s) : null,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, Session s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start session?'),
        content: Text(
          '"${s.programName}" will go live and a host access code will be generated.',
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
    if (confirm != true || !context.mounted) return;

    try {
      final code =
          await context.read<TechnicianViewModel>().startSession(s.id);
      if (!context.mounted) return;
      _showCodeDialog(context, code);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _showCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session started'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this code with the host:',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
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
  }
}

// ============================================================
// ENDED CARD
// ============================================================

class _EndedCard extends StatelessWidget {
  final Session session;
  const _EndedCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final s = session;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.programName,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('EEE d MMM · HH:mm').format(s.scheduledStart)}'
                  '${s.actualEnd != null && s.actualStart != null ? " · ${_duration(s)}" : ""}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View details',
            icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SessionDetailScreen(session: s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _duration(Session s) {
    final start = s.actualStart!;
    final end = s.actualEnd!;
    final d = end.difference(start);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

// ============================================================
// SMALL PARTS
// ============================================================

class _NoLiveBanner extends StatelessWidget {
  const _NoLiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              color: AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.radio_button_off,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'No session is currently on air. Start one from the upcoming list when its time arrives.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(text,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({Key? key, this.color = AppColors.success}) : super(key: key);

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}