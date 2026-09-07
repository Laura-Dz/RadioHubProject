import 'package:flutter/material.dart';
import '../../../core/models/technician/session_model.dart';

class WeeklySchedule extends StatelessWidget {
  final Map<DateTime, List<Session>> schedule;
  final DateTime selectedWeek;
  final Function(DateTime, int) onSlotTap;
  final Function(Session) onSessionTap;

  const WeeklySchedule({
    Key? key,
    required this.schedule,
    required this.selectedWeek,
    required this.onSlotTap,
    required this.onSessionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final days = _getWeekDays(selectedWeek);
    final timeSlots = _getTimeSlots();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          _buildHeader(days),
          Expanded(
            child: ListView.builder(
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final hour = timeSlots[index];
                return _buildTimeRow(days, hour);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<DateTime> days) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 60,
            child: Text(
              'Time',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          ...days.map((day) {
            final isToday = _isToday(day);
            return Expanded(
              child: Column(
                children: [
                  Text(
                    _getDayName(day.weekday),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isToday ? Colors.blue : Colors.black87,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.blue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: isToday ? Colors.white : Colors.black87,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeRow(List<DateTime> days, int hour) {
    final timeLabel = '${hour.toString().padLeft(2, '0')}:00';
    final isNow = hour == DateTime.now().hour;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isNow ? Colors.blue.shade50 : Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isNow ? Colors.blue : Colors.grey.shade600,
                  fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          ...days.map((day) {
            final sessions = schedule[day]?.where((s) => s.startTime.hour == hour).toList() ?? [];
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: sessions.isEmpty ? Colors.grey.shade50 : _getSessionColor(sessions.first),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: sessions.isNotEmpty ? Colors.transparent : Colors.grey.shade200,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    if (sessions.isEmpty) {
                      onSlotTap(day, hour);
                    } else {
                      onSessionTap(sessions.first);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: sessions.isEmpty
                        ? const Center(
                            child: Icon(Icons.add, size: 16, color: Colors.grey),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sessions.first.programName,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (sessions.first.hostName != null)
                                Text(
                                  sessions.first.hostName!,
                                  style: const TextStyle(
                                    fontSize: 7,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getSessionColor(Session session) {
    return session.statusColor;
  }

  List<DateTime> _getWeekDays(DateTime weekStart) {
    final start = weekStart.subtract(Duration(days: weekStart.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  List<int> _getTimeSlots() {
    return List.generate(16, (i) => i + 6);
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }
}
