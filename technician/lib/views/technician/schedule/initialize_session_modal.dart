import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/constants/app_colors.dart';

class InitializeSessionModal extends StatefulWidget {
  final TimetableSlot slot;
  final DateTime date;
  const InitializeSessionModal({Key? key, required this.slot, required this.date})
      : super(key: key);

  @override
  State<InitializeSessionModal> createState() => _InitializeSessionModalState();
}

class _InitializeSessionModalState extends State<InitializeSessionModal> {
  Host? _host;
  List<String> _coHostIds = [];
  final List<Map<String, String>> _guests = [];
  final _guestName = TextEditingController();
  final _guestRole = TextEditingController();
  final _thematic = TextEditingController();
  bool _submitting = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_host == null) {
      // Pre-select the first default host of the slot
      final vm = context.read<TechnicianViewModel>();
      if (widget.slot.hostIds.isNotEmpty) {
        final match = vm.hosts.where((h) => h.id == widget.slot.hostIds.first);
        if (match.isNotEmpty) _host = match.first;
      }
    }
  }

  @override
  void dispose() {
    _guestName.dispose();
    _guestRole.dispose();
    _thematic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final program = vm.programs.where((p) => p.id == widget.slot.programId);
    final pool = program.isNotEmpty
        ? vm.hosts.where((h) => program.first.hostIds.contains(h.id)).toList()
        : <Host>[];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Initialize session',
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
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Host of the day *',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Host>(
                        value: _host,
                        isExpanded: true,
                        items: pool
                            .map((h) => DropdownMenuItem(
                                value: h, child: Text(h.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _host = v),
                        decoration: _dec('Select host'),
                      ),
                      const SizedBox(height: 16),

                      if (pool.length > 1) ...[
                        const Text('Co-hosts (optional)',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: pool
                                .where((h) => h.id != _host?.id)
                                .map((h) {
                              final sel = _coHostIds.contains(h.id);
                              return CheckboxListTile(
                                value: sel,
                                onChanged: (_) => setState(() {
                                  if (sel) {
                                    _coHostIds.remove(h.id);
                                  } else {
                                    _coHostIds.add(h.id);
                                  }
                                }),
                                title: Text(h.name,
                                    style: const TextStyle(fontSize: 13.5)),
                                activeColor: AppColors.primary,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text('Thematic',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _thematic,
                        decoration: _dec('e.g., Finding love after 40'),
                      ),
                      const SizedBox(height: 16),

                      const Text('Guests (optional)',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _guestName,
                              decoration: _dec('Guest full name'),
                              onSubmitted: (_) => _addGuest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _guestRole,
                              decoration: _dec('Role (e.g. Expert)'),
                              onSubmitted: (_) => _addGuest(),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This creates the session in a scheduled state. The host access code will be generated when you start it.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
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
                    onPressed: (_submitting || _host == null) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.schedule, size: 16),
                    label: const Text('Initialize session'),
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

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final vm = context.read<TechnicianViewModel>();
      final coHostNames = <String>[];
      for (final id in _coHostIds) {
        final h = vm.hosts.where((x) => x.id == id);
        if (h.isNotEmpty) coHostNames.add(h.first.name);
      }

      final allGuests = List<Map<String, String>>.from(_guests);
      if (_guestName.text.trim().isNotEmpty) {
        allGuests.add({
          'name': _guestName.text.trim(),
          'role': _guestRole.text.trim(),
        });
      }

      await vm.initializeSessionForSlot(
        slot: widget.slot,
        date: widget.date,
        hostId: _host!.id,
        hostName: _host!.name,
        coHostIds: _coHostIds,
        coHostNames: coHostNames,
        guests: allGuests,
        guestName: allGuests.isNotEmpty ? allGuests.first['name'] : null,
        guestRole: allGuests.isNotEmpty ? allGuests.first['role'] : null,
        thematic:
            _thematic.text.trim().isEmpty ? null : _thematic.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session initialized. Start it from the slot when ready.'),
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
