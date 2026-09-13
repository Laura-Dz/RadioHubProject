import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/program_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/constants/app_colors.dart';

class EditSlotModal extends StatefulWidget {
  final TimetableSlot? slot;
  final int? initialWeekday;
  const EditSlotModal({Key? key, this.slot, this.initialWeekday}) : super(key: key);

  @override
  State<EditSlotModal> createState() => _EditSlotModalState();
}

class _EditSlotModalState extends State<EditSlotModal> {
  Program? _program;
  List<String> _hostIds = [];
  int _weekday = 1;
  int _startHour = 8;
  int _startMinute = 0;
  int _durationMinutes = 60;
  final _durCtrl = TextEditingController(text: '60');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.slot != null) {
      final s = widget.slot!;
      _weekday = s.weekday;
      _startHour = s.startHour;
      _startMinute = s.startMinute;
      _durationMinutes = (s.endHour * 60 + s.endMinute) - (s.startHour * 60 + s.startMinute);
      if (_durationMinutes <= 0) _durationMinutes = 60;
      _durCtrl.text = _durationMinutes.toString();
      _hostIds = List<String>.from(s.hostIds);
    } else if (widget.initialWeekday != null) {
      _weekday = widget.initialWeekday!;
    }
  }

  @override
  void dispose() {
    _durCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<TechnicianViewModel>();
    if (_program == null && widget.slot != null) {
      final match = vm.programs.where((p) => p.id == widget.slot!.programId);
      if (match.isNotEmpty) {
        _program = match.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final isEdit = widget.slot != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit slot' : 'Add timetable slot',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'A recurring weekly slot. Sessions will be generated from it.',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Program
              const Text('Program *',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Program>(
                value: _program,
                isExpanded: true,
                items: vm.programs
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _program = v;
                  if (v != null && widget.slot == null) {
                    _hostIds = List<String>.from(v.hostIds);
                  }
                }),
                decoration: _dec('Select program'),
              ),
              const SizedBox(height: 14),

              // Weekday
              const Text('Weekday',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final wd = i + 1;
                  final sel = _weekday == wd;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ChoiceChip(
                      label: Text(TimetableSlot.dayShort[i]),
                      selected: sel,
                      onSelected: (_) => setState(() => _weekday = wd),
                      selectedColor: AppColors.primary.withOpacity(0.12),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                          color: sel ? AppColors.primary : AppColors.border),
                      labelStyle: TextStyle(
                        color:
                            sel ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Time and duration
              const Text('Time & duration',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _timeAndDuration(),
              const SizedBox(height: 14),

              // Hosts for slot (scoped to program pool)
              const Text('Hosts for this slot',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _hostPicker(vm),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEdit)
                    TextButton.icon(
                      onPressed:
                          _submitting ? null : () => _delete(context),
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.error),
                      label: const Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : () => _submit(context),
                    icon: _submitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: Text(isEdit ? 'Save changes' : 'Add slot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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

  Widget _hostPicker(TechnicianViewModel vm) {
    final program = _program;
    if (program == null) {
      return const Text('Select a program first to choose hosts',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted));
    }
    final pool = vm.hosts.where((h) => program.hostIds.contains(h.id)).toList();
    if (pool.isEmpty) {
      return const Text(
          'This program has no hosts assigned. Edit the program to add hosts.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted));
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: pool.map((h) {
          final sel = _hostIds.contains(h.id);
          return CheckboxListTile(
            value: sel,
            onChanged: (_) => setState(() {
              if (sel) {
                _hostIds.remove(h.id);
              } else {
                _hostIds.add(h.id);
              }
            }),
            title: Text(h.name, style: const TextStyle(fontSize: 13.5)),
            subtitle: Text(h.email, style: const TextStyle(fontSize: 11.5)),
            activeColor: AppColors.primary,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _timeAndDuration() {
    final endTotalMin = _startHour * 60 + _startMinute + _durationMinutes;
    final endH = (endTotalMin ~/ 60) % 24;
    final endM = endTotalMin % 60;

    return Row(
      children: [
        Expanded(
          child: _startTimeField(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _durationField(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('End (auto)',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(
                  '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _startTimeField() => InkWell(
        onTap: () async {
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: _startHour, minute: _startMinute),
          );
          if (t != null) {
            setState(() {
              _startHour = t.hour;
              _startMinute = t.minute;
            });
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Start',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                '${_startHour.toString().padLeft(2, '0')}:${_startMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  Widget _durationField() => TextField(
        controller: _durCtrl,
        keyboardType: TextInputType.number,
        decoration: _dec('').copyWith(
          labelText: 'Duration (min)',
          isDense: true,
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n > 0) setState(() => _durationMinutes = n);
        },
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      );

  Future<void> _submit(BuildContext context) async {
    if (_program == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a program'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Duration must be positive'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    final endTotalMin = _startHour * 60 + _startMinute + _durationMinutes;
    final endH = (endTotalMin ~/ 60) % 24;
    final endM = endTotalMin % 60;

    final vm = context.read<TechnicianViewModel>();
    final hostNames = <String>[];
    for (final id in _hostIds) {
      final h = vm.hosts.where((x) => x.id == id);
      if (h.isNotEmpty) hostNames.add(h.first.name);
    }

    final candidate = TimetableSlot(
      id: widget.slot?.id ?? '',
      radioId: vm.radioId,
      programId: _program!.id,
      programName: _program!.name,
      weekday: _weekday,
      startHour: _startHour,
      startMinute: _startMinute,
      endHour: endH,
      endMinute: endM,
      hostIds: _hostIds,
      hostNames: hostNames,
      createdAt: DateTime.now(),
    );

    if (vm.timetableOverlaps(candidate, excludeSlotId: widget.slot?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This slot overlaps an existing slot on ${TimetableSlot.dayNames[_weekday - 1]}.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.slot == null) {
        await vm.createSlot(candidate);
      } else {
        await vm.updateSlot(widget.slot!.id, {
          'programId': _program!.id,
          'programName': _program!.name,
          'weekday': _weekday,
          'startHour': _startHour,
          'startMinute': _startMinute,
          'endHour': endH,
          'endMinute': endM,
          'hostIds': _hostIds,
          'hostNames': hostNames,
        });
      }
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.slot == null ? 'Slot added' : 'Slot updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
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

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete slot?'),
        content: const Text(
            'This removes the recurring slot. Already-generated sessions are not affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<TechnicianViewModel>().deleteSlot(widget.slot!.id);
    if (!context.mounted) return;
    Navigator.pop(context);
  }
}
