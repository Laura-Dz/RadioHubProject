import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/constants/app_colors.dart';
import 'edit_slot_modal.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar row
            Row(
              children: [
                const Text(
                  'Weekly Blueprint',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => const EditSlotModal(),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add slot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withOpacity(0.25)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.info),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The timetable is the radio\'s recurring weekly blueprint. Sessions are generated from it in the Schedule tab.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weekly grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _header(),
                    Expanded(
                      child: Row(
                        children:
                            List.generate(7, (i) => _dayColumn(context, vm, i + 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color:
                          i == 6 ? Colors.transparent : AppColors.divider,
                    ),
                  ),
                ),
                child: Text(
                  TimetableSlot.dayNames[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            );
          }),
        ),
      );

  Widget _dayColumn(BuildContext context, TechnicianViewModel vm, int weekday) {
    final slots = vm.slotsForDay(weekday);
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: weekday == 7 ? Colors.transparent : AppColors.divider,
            ),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ...slots.map((s) => _slotCard(context, vm, s)),
            _addCell(context, weekday),
          ],
        ),
      ),
    );
  }

  Widget _slotCard(BuildContext context, TechnicianViewModel vm,
          TimetableSlot slot) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => EditSlotModal(slot: slot),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.timeRange,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(slot.programName,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (slot.hostNames.isNotEmpty)
                  Text(slot.hostNames.join(', '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                else if (slot.defaultHostName != null && slot.defaultHostName!.isNotEmpty)
                  Text(slot.defaultHostName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );

  Widget _addCell(BuildContext context, int weekday) => InkWell(
        onTap: () => showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => EditSlotModal(initialWeekday: weekday),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 16, color: AppColors.textMuted),
          ),
        ),
      );
}
