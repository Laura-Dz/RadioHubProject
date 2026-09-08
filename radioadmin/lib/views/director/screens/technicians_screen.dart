import 'package:flutter/material.dart';
import '../../../core/models/director/technician_model.dart';

class TechniciansScreen extends StatelessWidget {
  final List<Technician> technicians;
  final Future<void> Function(Technician) onAdd;
  final Future<void> Function(String, Map<String, dynamic>) onUpdate;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onSuspend;
  final Future<void> Function(String) onActivate;

  const TechniciansScreen({
    Key? key,
    required this.technicians,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onSuspend,
    required this.onActivate,
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
              const Text('👨‍🔧 Technicians', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Technician'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: technicians.length,
              itemBuilder: (context, index) {
                final tech = technicians[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: tech.statusColor, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(tech.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${tech.email} • ${tech.statusLabel}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tech.status == TechnicianStatus.active)
                          IconButton(icon: const Icon(Icons.pause, color: Colors.orange), onPressed: () => onSuspend(tech.id))
                        else if (tech.status == TechnicianStatus.suspended)
                          IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), onPressed: () => onActivate(tech.id))
                        else
                          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => onActivate(tech.id)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onDelete(tech.id)),
                      ],
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

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Technician'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final technician = Technician(
                id: 'tech_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
                createdAt: DateTime.now(),
              );
              await onAdd(technician);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
