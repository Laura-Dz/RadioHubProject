import 'package:flutter/material.dart';
import '../../../core/models/sysadmin/backup_model.dart';

class BackupsScreen extends StatelessWidget {
  final List<Backup> backups;
  final Future<void> Function(Backup) onCreate;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onRestore;

  const BackupsScreen({
    Key? key,
    required this.backups,
    required this.onCreate,
    required this.onDelete,
    required this.onRestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💾 Backups', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _createBackup(context),
                icon: const Icon(Icons.add),
                label: const Text('New Backup'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: backup.statusColor, child: Icon(Icons.backup, color: Colors.white)),
                    title: Text(backup.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${backup.typeLabel} • ${backup.statusLabel} • ${backup.sizeDisplay}'),
                    trailing: backup.status == BackupStatus.completed
                        ? IconButton(icon: const Icon(Icons.restore, color: Colors.blue), onPressed: () => onRestore(backup.id))
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

  Future<void> _createBackup(BuildContext context) async {
    final backup = Backup(
      id: 'backup_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Manual Backup ${DateTime.now()}',
      type: BackupType.full,
      status: BackupStatus.pending,
      startTime: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await onCreate(backup);
  }
}
