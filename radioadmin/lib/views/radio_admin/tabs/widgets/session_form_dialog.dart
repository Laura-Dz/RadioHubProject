import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/session_model.dart';
import '../../../../core/models/radio_admin/program_model.dart';
import '../../../../core/models/radio_admin/host_model.dart';
import '../../../../core/widgets/common_widgets.dart';

class SessionFormDialog extends StatefulWidget {
  final RadioAdminViewModel viewModel;
  final Session? session;
  final DateTime? initialDate;
  final int? initialHour;

  const SessionFormDialog({
    Key? key,
    required this.viewModel,
    this.session,
    this.initialDate,
    this.initialHour,
  }) : super(key: key);

  @override
  State<SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends State<SessionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _thematicController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  Program? _selectedProgram;
  Host? _selectedHost;
  Host? _selectedCoHost;
  String? _guestName;
  SessionStatus _status = SessionStatus.scheduled;

  @override
  void initState() {
    super.initState();
    _thematicController = TextEditingController(text: widget.session?.thematic ?? '');
    _descriptionController = TextEditingController(text: widget.session?.description ?? '');
    _selectedDate = widget.initialDate ?? widget.session?.date ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(widget.initialHour != null
        ? DateTime(2024, 1, 1, widget.initialHour!)
        : widget.session?.startTime ?? DateTime.now());
    _endTime = TimeOfDay.fromDateTime(widget.session?.endTime ?? DateTime.now().add(const Duration(hours: 2)));
    _selectedProgram = widget.session != null
        ? widget.viewModel.programs.firstWhere(
            (p) => p.id == widget.session!.programId,
            orElse: () => Program(
              id: '',
              radioId: '',
              name: '',
              description: '',
              category: ProgramCategory.music,
              duration: Duration.zero,
              createdAt: DateTime.now(),
            ),
          )
        : null;
    _selectedHost = widget.session != null && widget.session!.hostId != null
        ? widget.viewModel.hosts.firstWhere(
            (h) => h.id == widget.session!.hostId,
            orElse: () => Host(id: '', radioId: '', name: '', email: '', createdAt: DateTime.now()),
          )
        : null;
    _status = widget.session?.status ?? SessionStatus.scheduled;
  }

  @override
  void dispose() {
    _thematicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.session != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RadioAdminColors.warning,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(isEditing ? Icons.edit : Icons.add, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Session' : 'New Session',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Program
                      DropdownButtonFormField<Program>(
                        value: _selectedProgram,
                        decoration: _inputDecoration('Program *', 'Select program'),
                        items: widget.viewModel.programs.map((program) {
                          return DropdownMenuItem(
                            value: program,
                            child: Text(program.name),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedProgram = value),
                        validator: (value) => value == null ? 'Program is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration('Date *', 'Select date'),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (time != null) setState(() => _startTime = time);
                              },
                              child: InputDecorator(
                                decoration: _inputDecoration('Start Time *', 'Select start time'),
                                child: Text(
                                  _startTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (time != null) setState(() => _endTime = time);
                              },
                              child: InputDecorator(
                                decoration: _inputDecoration('End Time *', 'Select end time'),
                                child: Text(
                                  _endTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Host
                      DropdownButtonFormField<Host>(
                        value: _selectedHost,
                        decoration: _inputDecoration('Host', 'Select host'),
                        items: widget.viewModel.hosts.map((host) {
                          return DropdownMenuItem(
                            value: host,
                            child: Text(host.name),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedHost = value),
                      ),
                      const SizedBox(height: 16),

                      // Thematic
                      TextFormField(
                        controller: _thematicController,
                        decoration: _inputDecoration('Thematic', 'Enter session theme'),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration('Description', 'Enter description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Status
                      DropdownButtonFormField<SessionStatus>(
                        value: _status,
                        decoration: _inputDecoration('Status', 'Select status'),
                        items: SessionStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusLabel(status)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RadioAdminColors.background,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: RadioAdminColors.divider),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RadioAdminColors.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(isEditing ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: RadioAdminColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: RadioAdminColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: RadioAdminColors.warning, width: 2),
      ),
      filled: true,
      fillColor: RadioAdminColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _getStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.live:
        return 'Live';
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.ended:
        return 'Ended';
      case SessionStatus.rediffusion:
        return 'Rediffusion';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final session = Session(
      id: widget.session?.id ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      radioId: widget.viewModel.radioId,
      programId: _selectedProgram!.id,
      programName: _selectedProgram!.name,
      programCategory: _selectedProgram!.category,
      date: _selectedDate,
      startTime: startDateTime,
      endTime: endDateTime,
      hostId: _selectedHost?.id,
      hostName: _selectedHost?.name,
      coHostId: widget.session?.coHostId,
      coHostName: widget.session?.coHostName,
      guestId: widget.session?.guestId,
      guestName: widget.session?.guestName,
      thematic: _thematicController.text.trim().isEmpty ? null : _thematicController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      status: _status,
      listenerCount: widget.session?.listenerCount ?? 0,
      recordingUrl: widget.session?.recordingUrl,
      rediffusionSourceId: widget.session?.rediffusionSourceId,
      createdAt: widget.session?.createdAt ?? DateTime.now(),
      startedAt: widget.session?.startedAt,
      endedAt: widget.session?.endedAt,
    );

    if (widget.session != null) {
      widget.viewModel.updateSession(session);
    } else {
      widget.viewModel.createSession(session);
    }

    Navigator.pop(context);
  }
}