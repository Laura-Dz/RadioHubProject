import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/services/network_time_service.dart';
import '../../../core/constants/app_colors.dart';

class SpecialEventModal extends StatefulWidget {
  const SpecialEventModal({Key? key}) : super(key: key);

  @override
  State<SpecialEventModal> createState() => _State();
}

class _State extends State<SpecialEventModal> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');

  SessionType _type = SessionType.special;
  DateTime _date = NetworkTimeService().now();
  late TimeOfDay _start = TimeOfDay(
    hour: NetworkTimeService().now().hour,
    minute: (NetworkTimeService().now().minute ~/ 5) * 5,
  );
  int _durationMinutes = 30;
  Host? _host;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDateTime =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
  DateTime get _endDateTime =>
      _startDateTime.add(Duration(minutes: _durationMinutes));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    // Check overlap
    final overlapping = vm.sessions.where((s) {
      if (s.status == SessionStatus.cancelled) return false;
      return _startDateTime.isBefore(s.scheduledEnd) &&
          s.scheduledStart.isBefore(_endDateTime);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Special event / Flash',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type
                        const Text('Type',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _typeChip(SessionType.special, 'Special event')),
                            const SizedBox(width: 8),
                            Expanded(child: _typeChip(SessionType.flash, 'Flash news')),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _title,
                          decoration: _dec().copyWith(labelText: 'Title'),
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          maxLines: 3,
                          decoration: _dec().copyWith(labelText: 'Description (optional)'),
                        ),
                        const SizedBox(height: 16),

                        // Date + time
                        const Text('When',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _dateField()),
                            const SizedBox(width: 10),
                            Expanded(child: _timeField()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _durationCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec().copyWith(labelText: 'Duration (minutes)'),
                                onChanged: (v) {
                                  final n = int.tryParse(v);
                                  if (n != null && n > 0) {
                                    setState(() => _durationMinutes = n);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ends at',
                                        style: TextStyle(
                                            fontSize: 11, color: AppColors.textMuted)),
                                    Text(
                                      '${_endDateTime.hour.toString().padLeft(2, '0')}:${_endDateTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Optional host
                        const Text('Host (optional)',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Host?>(
                          value: _host,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<Host?>(
                                value: null, child: Text('No host')),
                            ...vm.hosts.map((h) => DropdownMenuItem<Host?>(
                                value: h, child: Text(h.name))),
                          ],
                          onChanged: (v) => setState(() => _host = v),
                          decoration: _dec(''),
                        ),

                        // Overlap warning
                        if (overlapping.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 16, color: AppColors.warning),
                                    SizedBox(width: 8),
                                    Text('Time overlap detected',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warning)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...overlapping.take(3).map((s) => Text(
                                      '• ${s.programName} (${s.scheduledStart.hour.toString().padLeft(2, '0')}:${s.scheduledStart.minute.toString().padLeft(2, '0')}–${s.scheduledEnd.hour.toString().padLeft(2, '0')}:${s.scheduledEnd.minute.toString().padLeft(2, '0')})',
                                      style: const TextStyle(fontSize: 12),
                                    )),
                                const SizedBox(height: 4),
                                const Text(
                                  'The special event will preempt the regular session(s) above.',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 16),
                      label: const Text('Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
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
      ),
    );
  }

  Widget _typeChip(SessionType t, String label) {
    final sel = _type == t;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => setState(() => _type = t),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? AppColors.error.withOpacity(0.08) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? AppColors.error : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                t == SessionType.special
                    ? Icons.celebration_outlined
                    : Icons.bolt,
                color: sel ? AppColors.error : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.error : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField() => InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: NetworkTimeService().now().subtract(const Duration(days: 1)),
            lastDate: NetworkTimeService().now().add(const Duration(days: 365)),
          );
          if (d != null) setState(() => _date = d);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Date',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                '${_date.day}/${_date.month}/${_date.year}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  Widget _timeField() => InkWell(
        onTap: () async {
          final t = await showTimePicker(context: context, initialTime: _start);
          if (t != null) setState(() => _start = t);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Start time',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  InputDecoration _dec([String? hint]) => InputDecoration(
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
            borderSide: const BorderSide(color: AppColors.error, width: 1.4)),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final vm = context.read<TechnicianViewModel>();
      await vm.createSpecialEvent(
        title: _title.text.trim(),
        type: _type,
        start: _startDateTime,
        end: _endDateTime,
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        hostId: _host?.id,
        hostName: _host?.name,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == SessionType.flash
              ? 'Flash news scheduled'
              : 'Special event scheduled'),
          backgroundColor: AppColors.success,
        ),
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
