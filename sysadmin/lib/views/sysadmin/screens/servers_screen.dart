import 'package:flutter/material.dart';
import '../../../core/models/sysadmin/server_model.dart';

class ServersScreen extends StatelessWidget {
  final List<Server> servers;
  final Future<void> Function(String) onRestart;
  final Future<void> Function(String, Map<String, dynamic>) onUpdate;

  const ServersScreen({
    Key? key,
    required this.servers,
    required this.onRestart,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🖥️ Servers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: server.statusColor, child: Icon(Icons.dns, color: Colors.white)),
                    title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${server.typeLabel} • ${server.statusLabel} • ${server.uptimeDisplay}'),
                    trailing: server.status == ServerStatus.running
                        ? ElevatedButton.icon(
                            onPressed: () => _confirmRestart(context, server.id),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Restart'),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context, String serverId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Server?'),
        content: const Text('This will temporarily interrupt service. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restart')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await onRestart(serverId);
    }
  }
}
