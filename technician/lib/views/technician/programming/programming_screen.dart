import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../timetable/timetable_screen.dart';
import '../schedule/schedule_screen.dart';

class ProgrammingScreen extends StatefulWidget {
  const ProgrammingScreen({Key? key}) : super(key: key);

  @override
  State<ProgrammingScreen> createState() => _ProgrammingScreenState();
}

class _ProgrammingScreenState extends State<ProgrammingScreen> {
  int _tab = 0; // 0 = Schedule, 1 = Timetable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Toggle header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_view_week_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text('Programming',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 24),
                _segmented(),
                const Spacer(),
                // Hint that this is a blueprint/schedule pair
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.info),
                      SizedBox(width: 6),
                      Text(
                        'Timetable defines the pattern · Schedule holds the dated sessions',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Body
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                ScheduleScreen(),
                TimetableScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segItem(0, Icons.calendar_today_outlined, 'Schedule'),
          const SizedBox(width: 3),
          _segItem(1, Icons.calendar_view_week_outlined, 'Timetable'),
        ],
      ),
    );
  }

  Widget _segItem(int index, IconData icon, String label) {
    final sel = _tab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      sel ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
