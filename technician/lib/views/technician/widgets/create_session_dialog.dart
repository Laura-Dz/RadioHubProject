import 'package:flutter/material.dart';
import '../../../core/models/technician/session_model.dart';

class CreateSessionDialog extends StatefulWidget {
  final DateTime date;
  final int hour;
  final List<Map<String, String>> programs;
  final List<Map<String, String>> hosts;

  const CreateSessionDialog({
    Key? key,
    required this.date,
    required this.hour,
    required this.programs,
    required this.hosts,
  }) : super(key: key);

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  String? _programId;
  String? _hostId;
  final _thematicController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isInteractive = false;

  @override
  void dispose() {
    _thematicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('✨ Create Session – ${_formatDate(widget.date)} ${widget.hour.toString().padLeft(2, '0')}:00'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📋 Basic Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _programId,
                items: widget.programs
                    .map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name'] ?? '')))
                    .toList(),
                onChanged: (val) => setState(() => _programId = val),
                decoration: const InputDecoration(
                  labelText: 'Program',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _thematicController,
                decoration: const InputDecoration(
                  labelText: 'Thematic',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('👤 Host Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _hostId,
                items: widget.hosts
                    .map((h) => DropdownMenuItem(value: h['id'], child: Text(h['name'] ?? '')))
                    .toList(),
                onChanged: (val) => setState(() => _hostId = val),
                decoration: const InputDecoration(
                  labelText: 'Host',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('📝 Session Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isInteractive,
                onChanged: (v) => setState(() => _isInteractive = v ?? false),
                title: const Text('Interactive (call-ins allowed)'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_programId == null) return;
            final program = widget.programs.firstWhere((p) => p['id'] == _programId);
            final host = _hostId != null
                ? widget.hosts.firstWhere((h) => h['id'] == _hostId)
                : null;
            final session = Session(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              programId: _programId!,
              programName: program['name'] ?? 'Program',
              date: widget.date,
              startTime: DateTime(widget.date.year, widget.date.month, widget.date.day, widget.hour),
              endTime: DateTime(widget.date.year, widget.date.month, widget.date.day, widget.hour + 1),
              hostId: host?['id'],
              hostName: host?['name'],
              thematic: _thematicController.text,
              description: _descriptionController.text,
              isInteractive: _isInteractive,
              status: SessionStatus.scheduled,
              createdAt: DateTime.now(),
            );
            Navigator.pop(context, session);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
