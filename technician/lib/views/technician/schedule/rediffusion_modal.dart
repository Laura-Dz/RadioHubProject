import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/constants/app_colors.dart';

class RediffusionModal extends StatefulWidget {
  final TimetableSlot slot;
  final DateTime date;
  const RediffusionModal({Key? key, required this.slot, required this.date})
      : super(key: key);

  @override
  State<RediffusionModal> createState() => _RediffusionModalState();
}

class _RediffusionModalState extends State<RediffusionModal> {
  bool _loading = true;
  List<Session> _past = [];
  Session? _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final vm = context.read<TechnicianViewModel>();
      final list = await vm.pastSessionsForProgram(widget.slot.programId);
      if (!mounted) return;
      setState(() {
        _past = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.replay,
                        color: AppColors.gold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set as rediffusion',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(
                          '${widget.slot.programName} · ${DateFormat('EEE d MMM, HH:mm').format(widget.slot.dateFor(widget.date))}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only the metadata from the selected session will be used. Calls will be disabled because no host will be live.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Pick a past session of this program',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    : _past.isEmpty
                        ? const Center(
                            child: Text(
                              'No past sessions available for this program.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _past.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _sessionRow(_past[i]),
                          ),
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
                    onPressed: (_submitting || _selected == null) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: const Text('Confirm rediffusion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  Widget _sessionRow(Session s) {
    final sel = _selected?.id == s.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => setState(() => _selected = s),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? AppColors.gold : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                sel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: sel ? AppColors.gold : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('EEE d MMM yyyy, HH:mm')
                              .format(s.scheduledStart),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (s.recordingUrl != null && s.recordingUrl!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.audiotrack,
                                    size: 11, color: AppColors.success),
                                SizedBox(width: 3),
                                Text(
                                  'Audio ready',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.hostName}${s.guestName != null ? ' + ${s.guestName}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (s.thematic != null && s.thematic!.isNotEmpty)
                      Text(
                        s.thematic!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final vm = context.read<TechnicianViewModel>();
      await vm.rediffuseSlot(
        slot: widget.slot,
        date: widget.date,
        source: _selected!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Rediffusion scheduled'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
