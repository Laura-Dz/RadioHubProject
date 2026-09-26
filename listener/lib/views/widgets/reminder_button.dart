import 'package:flutter/material.dart';

class ReminderButton extends StatefulWidget {
  final String showId;
  final String programName;
  final DateTime showStartTime;
  final bool hasReminder;
  final Function(DateTime, int) onSetReminder;
  final VoidCallback onRemoveReminder;
  final bool compact;

  const ReminderButton({
    Key? key,
    required this.showId,
    required this.programName,
    required this.showStartTime,
    required this.hasReminder,
    required this.onSetReminder,
    required this.onRemoveReminder,
    this.compact = false,
  }) : super(key: key);

  @override
  State<ReminderButton> createState() => _ReminderButtonState();
}

class _ReminderButtonState extends State<ReminderButton> {
  int _selectedMinutes = 15;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        icon: Icon(
          widget.hasReminder ? Icons.alarm_on : Icons.alarm_add,
          color: widget.hasReminder ? Colors.orange : Colors.grey.shade600,
          size: 16,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        onPressed: () {
          if (widget.hasReminder) {
            _showRemoveConfirmation(context);
          } else {
            _showReminderOptions(context);
          }
        },
        tooltip: widget.hasReminder ? 'Remove reminder' : 'Set reminder',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              widget.hasReminder ? Icons.alarm_on : Icons.alarm_add,
              color: widget.hasReminder ? Colors.orange : Colors.grey,
              size: 20,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              if (widget.hasReminder) {
                _showRemoveConfirmation(context);
              } else {
                _showReminderOptions(context);
              }
            },
            tooltip: widget.hasReminder ? 'Remove reminder' : 'Set reminder',
          ),
          if (widget.hasReminder)
            Text(
              'Reminder set',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade700,
              ),
            ),
        ],
      ),
    );
  }


  void _showReminderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏰ Set Reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll be notified before "${widget.programName}" starts',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notify me',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _reminderOptionChip(5),
                _reminderOptionChip(10),
                _reminderOptionChip(15),
                _reminderOptionChip(30),
                _reminderOptionChip(60),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSetReminder(widget.showStartTime, _selectedMinutes);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder set for ${widget.programName}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Set Reminder ($_selectedMinutes min before)'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _reminderOptionChip(int minutes) {
    final isSelected = _selectedMinutes == minutes;
    return FilterChip(
      label: Text('$minutes min'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedMinutes = minutes;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey.shade700,
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Reminder?'),
        content: Text('Remove reminder for "${widget.programName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onRemoveReminder();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder removed'),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
