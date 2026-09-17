import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/program.dart';
import '../../../core/services/radio_schedule_service.dart';
import '../../../core/constants/app_colors.dart';
import 'program_card.dart';
import 'program_detail_sheet.dart';
import '../schedule/schedule_view.dart';
import '../timetable/timetable_view.dart';

class ShowsSection extends StatelessWidget {
  const ShowsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final radio = vm.radio;
    if (radio == null) return const SizedBox.shrink();

    final service = RadioScheduleService();

    return StreamBuilder<List<Program>>(
      stream: service.streamPrograms(radio.id),
      builder: (context, snap) {
        final programs = snap.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.mic_none_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'About our shows',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (programs.isNotEmpty)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleView(
                              radioId: radio.id,
                              radioName: radio.name,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'See all',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios,
                                  size: 10, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Programs Carousel
            if (programs.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColors.textMuted),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No programs listed for this radio station yet.',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: programs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final p = programs[i];
                    return ProgramCard(
                      program: p,
                      isFavourite: vm.isProgramFavourite(p.id),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ProgramDetailSheet(program: p),
                      ),
                      onToggleFavourite: () =>
                          vm.toggleFavouriteProgram(p.id, p.name),
                    );
                  },
                ),
              ),

            const SizedBox(height: 14),

            // Schedule + Timetable buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleView(
                            radioId: radio.id,
                            radioName: radio.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today_outlined, size: 15),
                      label: const Text('View schedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimetableView(
                            radioId: radio.id,
                            radioName: radio.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_view_week_outlined, size: 15),
                      label: const Text('View timetable'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
