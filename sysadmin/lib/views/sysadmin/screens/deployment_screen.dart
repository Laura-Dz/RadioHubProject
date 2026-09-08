import 'package:flutter/material.dart';
import '../../../core/models/sysadmin/deployment_model.dart';

class DeploymentScreen extends StatelessWidget {
  final List<Deployment> deployments;
  final Future<void> Function(Deployment) onTrigger;

  const DeploymentScreen({
    Key? key,
    required this.deployments,
    required this.onTrigger,
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
              const Text('🚀 Deployments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _triggerDeployment(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('New Deployment'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: deployments.length,
              itemBuilder: (context, index) {
                final deploy = deployments[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.rocket_launch, color: deploy.statusColor),
                    title: Text('v${deploy.version}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${deploy.statusLabel} • ${deploy.branch} • ${deploy.durationDisplay}'),
                    trailing: Text('${deploy.progress}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerDeployment(BuildContext context) async {
    final versionController = TextEditingController();
    final branchController = TextEditingController();
    final commitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trigger Deployment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: versionController, decoration: const InputDecoration(labelText: 'Version')),
            TextField(controller: branchController, decoration: const InputDecoration(labelText: 'Branch')),
            TextField(controller: commitController, decoration: const InputDecoration(labelText: 'Commit Hash')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final deployment = Deployment(
                id: 'deploy_${DateTime.now().millisecondsSinceEpoch}',
                version: versionController.text.trim(),
                branch: branchController.text.trim(),
                commitHash: commitController.text.trim(),
                deployedBy: 'admin',
                status: DeploymentStatus.pending,
                startedAt: DateTime.now(),
                createdAt: DateTime.now(),
              );
              await onTrigger(deployment);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Deploy'),
          ),
        ],
      ),
    );
  }
}
