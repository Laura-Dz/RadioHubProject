import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/technician/program_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/utils/app_avatar.dart';
import '../../../core/utils/app_program_image.dart';
import '../../../view_models/technician_view_model.dart';

class ProgramsSection extends StatelessWidget {
  const ProgramsSection({Key? key}) : super(key: key);

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
              const Text('📺 Programs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateProgramDialog(context, viewModel),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Program'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: viewModel.programs.isEmpty
                ? const Center(child: Text('No programs yet. Click "Create Program" to add one.'))
                : ListView.builder(
                    itemCount: viewModel.programs.length,
                    itemBuilder: (context, index) {
                      final p = viewModel.programs[index];
                      final matchedHosts = p.hostIds
                          .map((id) => viewModel.hosts.cast<Host?>().firstWhere((h) => h?.id == id, orElse: () => null))
                          .whereType<Host>()
                          .toList();
                      return Card(
                        child: ListTile(
                          leading: AppProgramImage(
                            imageUrl: p.imageUrl,
                            name: p.name,
                            width: 44,
                            height: 44,
                            borderRadius: 8,
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.category}\n${p.description}'),
                              if (matchedHosts.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    for (final h in matchedHosts.take(3))
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: AppAvatar(photoUrl: h.photoUrl, name: h.name, radius: 10),
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      matchedHosts.map((h) => h.name).join(', '),
                                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => viewModel.deleteProgram(p.id),
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

  Future<void> _showCreateProgramDialog(BuildContext context, TechnicianViewModel vm) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = TextEditingController(text: 'general');
    final durationController = TextEditingController(text: '60');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📺 Create Program'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (minutes)')),
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
                'description': descController.text,
                'category': categoryController.text,
                'duration': durationController.text,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      await vm.createProgram(Program(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        description: result['description'] ?? '',
        category: result['category'] ?? 'general',
        hosts: const [],
        defaultDuration: Duration(minutes: int.tryParse(result['duration'] ?? '60') ?? 60),
        createdAt: DateTime.now(),
      ));
    }
  }
}
