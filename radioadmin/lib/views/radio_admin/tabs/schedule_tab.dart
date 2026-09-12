import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/session_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/models/radio_admin/host_model.dart';
import '../../../core/widgets/common_widgets.dart';
import 'widgets/session_form_dialog.dart';

class ScheduleTab extends StatelessWidget {
  final String radioId;

  const ScheduleTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Schedule',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {},
                    tooltip: 'Previous week',
                  ),
                  IconButton(
                    icon: const Icon(Icons.today),
                    onPressed: () {},
                    tooltip: 'Today',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                    tooltip: 'Next week',
                  ),
                  ActionButton(
                    label: 'New Session',
                    icon: Icons.add,
                    onPressed: () => _showSessionDialog(context, viewModel),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildScheduleGrid(context, viewModel, weekStart),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid(BuildContext context, RadioAdminViewModel viewModel, DateTime weekStart) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final hours = List.generate(19, (i) => 6 + i);

    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEndDate = weekStartDate.add(const Duration(days: 7));

    final sessionsInWeek = viewModel.sessions.where((s) {
      return s.date.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
          s.date.isBefore(weekEndDate);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        children: [
          _buildDayHeaders(days),
          Expanded(
            child: ListView.builder(
              itemCount: hours.length,
              itemBuilder: (context, hourIndex) {
                final hour = hours[hourIndex];
                return _buildHourRow(context, viewModel, days, sessionsInWeek, hour);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders(List<DateTime> days) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: RadioAdminColors.background,
        border: Border(bottom: BorderSide(color: RadioAdminColors.divider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 60),
          ...days.map((day) => Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 12,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildHourRow(BuildContext context, RadioAdminViewModel viewModel, List<DateTime> days, List<Session> sessionsInWeek, int hour) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: RadioAdminColors.divider.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(DateTime(2024, 1, 1, hour)),
                style: TextStyle(
                  fontSize: 11,
                  color: RadioAdminColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          ...days.map((day) => _buildDaySlot(context, viewModel, day, sessionsInWeek, hour)).toList(),
        ],
      ),
    );
  }

  Widget _buildDaySlot(BuildContext context, RadioAdminViewModel viewModel, DateTime day, List<Session> sessionsInWeek, int hour) {
    final date = DateTime(day.year, day.month, day.day);
    final sessionAtSlot = sessionsInWeek.firstWhere(
      (s) =>
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day &&
          s.startTime.hour == hour,
      orElse: () => Session(
        id: '',
        radioId: '',
        programId: '',
        programName: '',
        programCategory: ProgramCategory.music,
        date: date,
        startTime: DateTime(date.year, date.month, date.day, hour),
        endTime: DateTime(date.year, date.month, date.day, hour + 1),
        status: SessionStatus.scheduled,
        createdAt: DateTime.now(),
      ),
    );

    if (sessionAtSlot.id.isEmpty) {
      return Expanded(
        child: InkWell(
          onTap: () => _showSessionDialog(context, viewModel, date: date, hour: hour),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: RadioAdminColors.divider.withOpacity(0.3), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: sessionAtSlot.status == SessionStatus.live
              ? RadioAdminColors.error.withOpacity(0.1)
              : sessionAtSlot.program.category.iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: sessionAtSlot.status == SessionStatus.live
                ? RadioAdminColors.error
                : sessionAtSlot.program.category.iconColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sessionAtSlot.programName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: sessionAtSlot.status == SessionStatus.live
                    ? RadioAdminColors.error
                    : sessionAtSlot.program.category.iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sessionAtSlot.hostName ?? 'TBA',
              style: TextStyle(
                fontSize: 9,
                color: RadioAdminColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDialog(BuildContext context, RadioAdminViewModel viewModel, {DateTime? date, int? hour}) {
    showDialog(
      context: context,
      builder: (context) => SessionFormDialog(
        viewModel: viewModel,
        initialDate: date,
        initialHour: hour,
      ),
    );
  }
}