import 'package:flutter/material.dart';
import '../../../core/models/sysadmin/security_log_model.dart';

class SecurityScreen extends StatelessWidget {
  final List<SecurityLog> logs;
  final Future<void> Function(SecurityLog) onAddLog;

  const SecurityScreen({
    Key? key,
    required this.logs,
    required this.onAddLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔐 Security Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.security, color: log.severityColor),
                    title: Text(log.eventLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${log.severityLabel} • ${log.description}'),
                    trailing: Text(
                      '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
