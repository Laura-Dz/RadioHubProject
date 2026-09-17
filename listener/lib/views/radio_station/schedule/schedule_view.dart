import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/session_model.dart';
import '../../../core/services/radio_schedule_service.dart';
import '../../../core/constants/app_colors.dart';
import 'session_readonly_card.dart';

class ScheduleView extends StatefulWidget {
  final String radioId;
  final String radioName;

  const ScheduleView({
    Key? key,
    required this.radioId,
    required this.radioName,
  }) : super(key: key);

  @override
  State<ScheduleView> createState() => _State();
}

class _State extends State<ScheduleView> {
  final _service = RadioScheduleService();

  late DateTime _weekStart;
  List<SessionModel> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _weekStart = _monday(DateTime.now());
    _load();
  }

  void _load() {
    // The stream is rebuilt every time the week changes
    setState(() => _loading = true);
  }

  static DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.radioName,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Week header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous week',
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.subtract(const Duration(days: 7));
                    });
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _weekStart = _monday(DateTime.now()));
                  },
                  child: const Text('Today'),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next week',
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.add(const Duration(days: 7));
                    });
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Week of ${DateFormat('d MMM').format(_weekStart)}',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Legend
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _legend(AppColors.error, 'Live'),
                  const SizedBox(width: 12),
                  _legend(const Color(0xFFD4A017), 'Rediffusion'),
                  const SizedBox(width: 12),
                  _legend(const Color(0xFF8B5CF6), 'Intermediary'),
                  const SizedBox(width: 12),
                  _legend(const Color(0xFFEF4444), 'Special / Flash'),
                  const SizedBox(width: 12),
                  _legend(const Color(0xFF9CA3AF), 'Passed'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Week view
          Expanded(child: _weekView()),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: c.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.withOpacity(0.6)),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ],
    );
  }

  Widget _weekView() {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final rangeStart = _weekStart;
    final rangeEnd = _weekStart.add(const Duration(days: 7));

    return StreamBuilder<List<SessionModel>>(
      key: ValueKey(rangeStart.toIso8601String()),
      stream: _service.streamSessionsInRange(
        radioId: widget.radioId,
        from: rangeStart,
        to: rangeEnd,
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final sessions = snap.data!;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _dayHeaderRow(days),
                Expanded(
                  child: Row(
                    children: days.map((d) => _dayColumn(d, sessions)).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dayHeaderRow(List<DateTime> days) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: days.map((d) {
          final isToday = _sameDay(d, DateTime.now());
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withOpacity(0.05)
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: d == days.last
                        ? Colors.transparent
                        : AppColors.divider,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(DateFormat('EEE').format(d),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      )),
                  const SizedBox(height: 2),
                  Text('${d.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            isToday ? AppColors.primary : AppColors.textPrimary,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dayColumn(DateTime day, List<SessionModel> all) {
    final sessions = all.where((s) => _sameDay(s.scheduledStart, day)).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: _sameDay(day, _weekStart.add(const Duration(days: 6)))
                  ? Colors.transparent
                  : AppColors.divider,
            ),
          ),
        ),
        child: sessions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('—',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(6),
                children: sessions
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SessionReadonlyCard(session: s, compact: true),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
