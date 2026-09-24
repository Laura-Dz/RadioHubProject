import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/radio_admin/session_model.dart';

class ScheduleViewScreen extends StatefulWidget {
  const ScheduleViewScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleViewScreen> createState() => _ScheduleViewScreenState();
}

class _ScheduleViewScreenState extends State<ScheduleViewScreen> {
  DateTime _weekStart = _monday(DateTime.now());
  final ScrollController _scrollController = ScrollController();

  static DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    final weekEnd = _weekStart.add(const Duration(days: 7));
    final sessionsInWeek = vm.sessions.where((s) {
      final sDate = s.date;
      return !sDate.isBefore(_weekStart) && sDate.isBefore(weekEnd);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text(
                  'Read-only (Technician Managed)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Week Navigator Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _weekStart = _monday(DateTime.now())),
                  child: const Text('Today'),
                ),
                IconButton(
                  tooltip: 'Next week',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _weekStart = _weekStart.add(const Duration(days: 7)),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Week of ${DateFormat('d MMM yyyy').format(_weekStart)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sessionsInWeek.length} sessions this week',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Legend Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                const Text(
                  'Legend:',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF3B82F6), 'Scheduled'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF22C55E), 'Live session'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFFD4A017), 'Rediffusion'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF9CA3AF), 'Ended / Passed'),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'On air now',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // 7-day Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _headerRow(days),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: days
                                  .map((d) => _dayColumn(vm, d, sessionsInWeek))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ],
    );
  }

  Widget _headerRow(List<DateTime> days) {
    final now = DateTime.now();
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: days.map((d) {
          final isToday = _sameDay(d, now);
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withOpacity(0.06)
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: d == days.last ? Colors.transparent : AppColors.divider,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(d),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dayColumn(
    RadioAdminViewModel vm,
    DateTime day,
    List<Session> sessionsInWeek,
  ) {
    final daySessions = sessionsInWeek
        .where((s) => _sameDay(s.date, day))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final isLastDay = _sameDay(day, _weekStart.add(const Duration(days: 6)));

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: isLastDay ? Colors.transparent : AppColors.divider,
            ),
          ),
        ),
        child: daySessions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 8),
                  child: Text(
                    '—\nNo sessions',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: daySessions.map((s) => _SessionCard(session: s)).toList(),
                ),
              ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final Session session;
  const _SessionCard({required this.session});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final isLive = s.status == SessionStatus.live;
    final isEnded = s.status == SessionStatus.ended;
    final isRediffusion = s.status == SessionStatus.rediffusion;

    Color color;
    if (isLive) {
      color = const Color(0xFF22C55E);
    } else if (isRediffusion) {
      color = const Color(0xFFD4A017);
    } else if (isEnded) {
      color = const Color(0xFF9CA3AF);
    } else {
      color = const Color(0xFF3B82F6);
    }

    final timeFormat = DateFormat('HH:mm');
    final timeStr = '${timeFormat.format(s.startTime)} - ${timeFormat.format(s.endTime)}';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => _showSessionDetails(context, s),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover ? color.withOpacity(0.15) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hover ? color : color.withOpacity(0.35),
              width: isLive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  if (isLive)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                s.programName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (s.hostName != null && s.hostName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 10, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        s.hostName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLive
                      ? 'LIVE'
                      : isRediffusion
                          ? 'REDIFF'
                          : isEnded
                              ? 'ENDED'
                              : 'SCHEDULED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, Session s) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.radio, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.programName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.calendar_today, 'Date', dateFormat.format(s.date)),
              _detailRow(
                Icons.access_time,
                'Time',
                '${timeFormat.format(s.startTime)} - ${timeFormat.format(s.endTime)}',
              ),
              _detailRow(
                Icons.info_outline,
                'Status',
                s.status.name.toUpperCase(),
              ),
              if (s.hostName != null && s.hostName!.isNotEmpty)
                _detailRow(Icons.mic, 'Host', s.hostName!),
              if (s.coHostName != null && s.coHostName!.isNotEmpty)
                _detailRow(Icons.people_outline, 'Co-Host', s.coHostName!),
              if (s.thematic != null && s.thematic!.isNotEmpty)
                _detailRow(Icons.topic_outlined, 'Thematic', s.thematic!),
              if (s.description != null && s.description!.isNotEmpty)
                _detailRow(Icons.notes, 'Description', s.description!),
              if (s.listenerCount > 0)
                _detailRow(
                  Icons.headphones,
                  'Listeners',
                  '${s.listenerCount} listeners',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
