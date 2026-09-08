import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/sysadmin_view_model.dart';
import 'sysadmin_sidebar.dart';
import 'screens/monitoring_screen.dart';
import 'screens/servers_screen.dart';
import 'screens/security_screen.dart';
import 'screens/backups_screen.dart';
import 'screens/deployment_screen.dart';

class SysAdminDashboard extends StatelessWidget {
  const SysAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();

    return Scaffold(
      body: Row(
        children: [
          SysAdminSidebar(
            selectedIndex: viewModel.selectedTab,
            onItemSelected: viewModel.setSelectedTab,
          ),
          Expanded(
            child: _buildContent(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SysAdminViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (viewModel.selectedTab) {
      case 0:
        return MonitoringScreen(
          servers: viewModel.servers,
          totalServers: viewModel.totalServers,
          runningServers: viewModel.runningServers,
          failedServers: viewModel.failedServers,
          averageCpu: viewModel.averageCpuUsage,
          averageMemory: viewModel.averageMemoryUsage,
          backups: viewModel.backups,
          criticalEvents: viewModel.criticalSecurityEvents,
          warningEvents: viewModel.warningSecurityEvents,
          successfulDeployments: viewModel.successfulDeployments,
          failedDeployments: viewModel.failedDeployments,
        );
      case 1:
        return ServersScreen(
          servers: viewModel.servers,
          onRestart: viewModel.restartServer,
          onUpdate: viewModel.updateServer,
        );
      case 2:
        return SecurityScreen(
          logs: viewModel.securityLogs,
          onAddLog: viewModel.addSecurityLog,
        );
      case 3:
        return BackupsScreen(
          backups: viewModel.backups,
          onCreate: viewModel.createBackup,
          onDelete: viewModel.deleteBackup,
          onRestore: viewModel.restoreBackup,
        );
      case 4:
        return DeploymentScreen(
          deployments: viewModel.deployments,
          onTrigger: viewModel.triggerDeployment,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
