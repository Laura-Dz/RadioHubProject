import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/announcement_request_model.dart';
import '../../../../core/models/radio_admin/announcement_slot_model.dart';
import '../../../../core/constants/app_colors.dart';

class ValidateAnnouncementModal extends StatefulWidget {
  final AnnouncementRequest announcement;
  const ValidateAnnouncementModal({Key? key, required this.announcement}) : super(key: key);

  @override
  State<ValidateAnnouncementModal> createState() => _ValidateAnnouncementModalState();
}

class _ValidateAnnouncementModalState extends State<ValidateAnnouncementModal> {
  late DateTime _startDate;
  List<AnnouncementSlot> _slots = [];
  bool _loadingSlots = true;
  bool _submitting = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.announcement.desiredStartDate;
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final slots = await context.read<RadioAdminViewModel>().getAvailableSlots(
            fromDate: _startDate,
            days: widget.announcement.days,
          );
      if (mounted) {
        setState(() {
          _slots = _assignSlots(slots);
          _loadingSlots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  List<AnnouncementSlot> _assignSlots(List<AnnouncementSlot> available) {
    final needed = widget.announcement.diffusionsPerDay * widget.announcement.days;
    return available.take(needed).toList();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: AppColors.success),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Validate announcement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Announcement preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.listenerName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(a.categoryLabel,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.gold, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(a.finalText.isNotEmpty ? a.finalText : a.originalText,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Plan summary
              Row(
                children: [
                  Expanded(child: _stat('Diffusions/day', '${a.diffusionsPerDay}')),
                  Expanded(child: _stat('Days', '${a.days}')),
                  Expanded(child: _stat('Payout to radio', '${a.baseAmount.toStringAsFixed(0)} ${a.currency}')),
                ],
              ),
              const SizedBox(height: 16),
              // Start date
              const Text('Start date',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
              ),
              const SizedBox(height: 16),
              // Auto-assigned slots
              const Text('Scheduled placements',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: _loadingSlots
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    : _slots.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No slots available in this period. Adjust the start date.',
                                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _slots.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (_, i) {
                              final s = _slots[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      s.slotType == 'within' ? Icons.queue_music : Icons.playlist_play,
                                      size: 16,
                                      color: s.slotType == 'within' ? AppColors.primary : AppColors.gold,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${s.dateLabel} · ${s.timeLabel}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.slotType == 'within'
                                            ? 'Within ${s.showName ?? "show"}'
                                            : 'Between shows',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    Text('${s.durationSeconds}s',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              // Escrow notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'On validation, ${a.baseAmount.toStringAsFixed(0)} ${a.currency} will be credited directly to your radio station.',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                title: const Text('I confirm the pricing and scheduled placements',
                    style: TextStyle(fontSize: 12.5)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                dense: true,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_submitting || !_confirmed || _loadingSlots) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: const Text('Confirm & schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) {
      setState(() => _startDate = d);
      await _loadSlots();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await context.read<RadioAdminViewModel>().validateAnnouncementWithSlots(
            id: widget.announcement.id,
            scheduledFor: _startDate,
            slots: _slots,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement validated and scheduled'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
