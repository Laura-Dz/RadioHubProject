import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/models/technician/program_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/constants/app_colors.dart';

class CreateSessionModal extends StatefulWidget {
  /// Pre-filled from Schedule slot click. If null, admin picks everything.
  final Program? preselectedProgram;
  final DateTime? preselectedStart;
  final DateTime? preselectedEnd;
  final Session? rediffusionSource; // when scheduling a rediffusion

  const CreateSessionModal({
    Key? key,
    this.preselectedProgram,
    this.preselectedStart,
    this.preselectedEnd,
    this.rediffusionSource,
  }) : super(key: key);

  @override
  State<CreateSessionModal> createState() => _State();
}

class _State extends State<CreateSessionModal> {
  final _form = GlobalKey<FormState>();
  final _thematic = TextEditingController();
  final _description = TextEditingController();
  final _guestName = TextEditingController();
  final _guestRole = TextEditingController();

  Program? _program;
  Host? _host;
  final List<Host> _selectedCoHosts = [];
  final List<Map<String, String>> _guests = [];
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end = DateTime.now().add(const Duration(hours: 2));
  String _format = 'solo';
  bool _isSpecialEvent = false;
  bool _submitting = false;

  static const _formats = ['solo', 'interview', 'call_in', 'panel', 'music_mix'];

  @override
  void initState() {
    super.initState();
    _program = widget.preselectedProgram;
    if (widget.preselectedStart != null) _start = widget.preselectedStart!;
    if (widget.preselectedEnd != null) _end = widget.preselectedEnd!;
    if (widget.rediffusionSource != null) {
      _thematic.text = widget.rediffusionSource!.thematic ?? '';
      _description.text = widget.rediffusionSource!.description ?? '';
      _format = widget.rediffusionSource!.format ?? 'solo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final isRediff = widget.rediffusionSource != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
                    Icon(
                      isRediff ? Icons.replay : Icons.play_circle_outline,
                      color: isRediff ? AppColors.gold : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRediff ? 'Schedule rediffusion' : 'Create session',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isRediff)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.gold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Source: ${widget.rediffusionSource!.programName} — only metadata is loaded. Calls will be disabled for listeners.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Program *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Program>(
                          value: _program,
                          isExpanded: true,
                          decoration: _dec('Select program'),
                          items: vm.programs
                              .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                              .toList(),
                          onChanged: isRediff ? null : (v) => setState(() => _program = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        const Text('Main Host *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Host>(
                          value: _host,
                          isExpanded: true,
                          decoration: _dec('Select main host'),
                          items: vm.hosts
                              .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _host = v;
                              if (v != null) _selectedCoHosts.removeWhere((ch) => ch.id == v.id);
                            });
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Co-Hosts (optional)',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            if (_selectedCoHosts.isNotEmpty)
                              Text('${_selectedCoHosts.length} added',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (vm.hosts.where((h) => h.id != _host?.id && !_selectedCoHosts.any((ch) => ch.id == h.id)).isNotEmpty)
                          DropdownButtonFormField<Host>(
                            value: null,
                            isExpanded: true,
                            decoration: _dec('+ Add a co-host from roster'),
                            items: vm.hosts
                                .where((h) => h.id != _host?.id && !_selectedCoHosts.any((ch) => ch.id == h.id))
                                .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedCoHosts.add(v);
                                });
                              }
                            },
                          ),
                        if (_selectedCoHosts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _selectedCoHosts.map((h) => Chip(
                              avatar: const Icon(Icons.people_outline, size: 14, color: AppColors.primary),
                              label: Text(h.name),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => setState(() => _selectedCoHosts.remove(h)),
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _dateField('Start', _start, (d) => setState(() => _start = d))),
                            const SizedBox(width: 12),
                            Expanded(child: _dateField('End', _end, (d) => setState(() => _end = d))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text('Format',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _formats.map((f) => ChoiceChip(
                                label: Text(f.replaceAll('_', ' ')),
                                selected: _format == f,
                                onSelected: (_) => setState(() => _format = f),
                                selectedColor: AppColors.primary.withOpacity(0.12),
                                side: BorderSide(color: _format == f ? AppColors.primary : AppColors.border),
                              )).toList(),
                        ),
                        const SizedBox(height: 14),
                        _field(_thematic, 'Thematic',
                            hint: 'e.g., Finding love after 40'),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Guests & Roles (optional)',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            if (_guests.isNotEmpty)
                              Text('${_guests.length} guest${_guests.length > 1 ? "s" : ""}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _guestName,
                                decoration: _dec('Guest full name'),
                                onFieldSubmitted: (_) => _addGuest(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _guestRole,
                                decoration: _dec('Role (e.g. Expert)'),
                                onFieldSubmitted: (_) => _addGuest(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _addGuest,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16),
                                  SizedBox(width: 4),
                                  Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_guests.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _guests.map((g) {
                              final hasRole = (g['role'] ?? '').isNotEmpty;
                              final display = hasRole ? '${g['name']} (${g['role']})' : g['name']!;
                              return Chip(
                                avatar: const Icon(Icons.person, size: 14, color: AppColors.primary),
                                label: Text(display),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => setState(() => _guests.remove(g)),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _field(_description, 'Description', maxLines: 3),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSpecialEvent
                                ? const Color(0xFFEF4444).withOpacity(0.08)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isSpecialEvent
                                  ? const Color(0xFFEF4444).withOpacity(0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: _isSpecialEvent
                                      ? const Color(0xFFEF4444)
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mark as Special Event',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Text(
                              'Highlights this session in red on the schedule and informs listeners',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            activeColor: const Color(0xFFEF4444),
                            value: _isSpecialEvent,
                            onChanged: (val) => setState(() => _isSpecialEvent = val),
                          ),
                        ),
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
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(isRediff ? Icons.replay : Icons.check, size: 16),
                      label: Text(isRediff ? 'Schedule rediffusion' : 'Create session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRediff ? AppColors.gold : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _addGuest() {
    final name = _guestName.text.trim();
    if (name.isEmpty) return;
    final role = _guestRole.text.trim();
    setState(() {
      _guests.add({'name': name, 'role': role});
      _guestName.clear();
      _guestRole.clear();
    });
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      );

  Widget _field(TextEditingController c, String label, {int maxLines = 1, String? hint}) =>
      TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: _dec(hint ?? '').copyWith(labelText: label),
      );

  Widget _dateField(String label, DateTime value, Function(DateTime) onPick) => InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 90)),
          );
          if (d == null || !mounted) return;
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
          );
          if (t == null) return;
          onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('${value.day}/${value.month} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    try {
      final vm = context.read<TechnicianViewModel>();
      final allGuests = List<Map<String, String>>.from(_guests);
      if (_guestName.text.trim().isNotEmpty) {
        allGuests.add({
          'name': _guestName.text.trim(),
          'role': _guestRole.text.trim(),
        });
      }

      String id;
      if (widget.rediffusionSource != null) {
        id = await vm.scheduleRediffusion(
          source: widget.rediffusionSource!,
          start: _start,
          end: _end,
        );
      } else {
        id = await vm.createSession(Session(
          id: '',
          radioId: vm.radioId,
          programId: _program!.id,
          programName: _program!.name,
          hostId: _host!.id,
          hostName: _host!.name,
          coHostIds: _selectedCoHosts.map((h) => h.id).toList(),
          coHostNames: _selectedCoHosts.map((h) => h.name).toList(),
          guests: allGuests,
          guestName: allGuests.isNotEmpty ? allGuests.first['name'] : null,
          guestRole: allGuests.isNotEmpty ? allGuests.first['role'] : null,
          thematic: _thematic.text.trim().isEmpty ? null : _thematic.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          format: _format,
          scheduledStart: _start,
          scheduledEnd: _end,
          sessionType: _isSpecialEvent ? SessionType.special : SessionType.live,
          isSpecialEvent: _isSpecialEvent,
          createdAt: DateTime.now(),
        ));
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.rediffusionSource != null
              ? 'Rediffusion scheduled'
              : 'Session created'),
          backgroundColor: AppColors.success,
        ),
      );
      debugPrint('Session created: $id');
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