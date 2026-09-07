import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../view_models/technician_view_model.dart';

class HostsSection extends StatelessWidget {
  const HostsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎙️ Hosts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateHostDialog(context, viewModel),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Host'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: viewModel.hosts.isEmpty
                ? const Center(child: Text('No hosts yet. Click "Create Host" to add one.'))
                : ListView.builder(
                    itemCount: viewModel.hosts.length,
                    itemBuilder: (context, index) {
                      final h = viewModel.hosts[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              h.name.isNotEmpty ? h.name.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${h.email}\n${h.programIds.length} program(s)'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => viewModel.deleteHost(h.id),
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

  Future<void> _showCreateHostDialog(BuildContext context, TechnicianViewModel vm) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final bioController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('👤 Create Host'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'name': nameController.text,
                'email': emailController.text,
                'phone': phoneController.text,
                'bio': bioController.text,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      await vm.createHost(Host(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        email: result['email'] ?? '',
        phone: result['phone'],
        bio: result['bio'],
        createdAt: DateTime.now(),
      ));
    }
  }
}
