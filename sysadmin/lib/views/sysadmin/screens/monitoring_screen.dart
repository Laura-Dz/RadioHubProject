import 'package:flutter/material.dart';
import '../../../core/models/sysadmin/server_model.dart';
import '../../../core/models/sysadmin/backup_model.dart';

class MonitoringScreen extends StatelessWidget {
  final List<Server> servers;
  final int totalServers;
  final int runningServers;
  final int failedServers;
  final double averageCpu;
  final double averageMemory;
  final List<Backup> backups;
  final int criticalEvents;
  final int warningEvents;
  final int successfulDeployments;
  final int failedDeployments;

  const MonitoringScreen({
    Key? key,
    required this.servers,
    required this.totalServers,
    required this.runningServers,
    required this.failedServers,
    required this.averageCpu,
    required this.averageMemory,
    required this.backups,
    required this.criticalEvents,
    required this.warningEvents,
    required this.successfulDeployments,
    required this.failedDeployments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Monitoring', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildCard('Total Servers', totalServers.toString(), Colors.blue, Icons.dns),
                _buildCard('Running', runningServers.toString(), Colors.green, Icons.check_circle),
                _buildCard('Failed', failedServers.toString(), Colors.red, Icons.error),
                _buildCard('Avg CPU', '${averageCpu.toStringAsFixed(1)}%', Colors.orange, Icons.memory),
                _buildCard('Avg Memory', '${averageMemory.toStringAsFixed(1)}%', Colors.purple, Icons.storage),
                _buildCard('Critical Events', criticalEvents.toString(), Colors.red, Icons.warning),
                _buildCard('Successful Deploys', successfulDeployments.toString(), Colors.green, Icons.rocket_launch),
                _buildCard('Failed Deploys', failedDeployments.toString(), Colors.red, Icons.cancel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
