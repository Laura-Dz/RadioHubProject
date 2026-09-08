import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/director_view_model.dart';
import 'director_sidebar.dart';
import 'screens/metrics_screen.dart';
import 'screens/technicians_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/homepage_config_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/requests_screen.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({Key? key}) : super(key: key);

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DirectorViewModel>();

    return Scaffold(
      body: Row(
        children: [
          DirectorSidebar(
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

  Widget _buildContent(DirectorViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (viewModel.selectedTab) {
      case 0:
        return MetricsScreen(metrics: viewModel.metrics);
      case 1:
        return TechniciansScreen(
          technicians: viewModel.technicians,
          onAdd: viewModel.addTechnician,
          onUpdate: viewModel.updateTechnician,
          onDelete: viewModel.deleteTechnician,
          onSuspend: viewModel.suspendTechnician,
          onActivate: viewModel.activateTechnician,
        );
      case 2:
        return SubscriptionsScreen(
          subscriptions: viewModel.subscriptions,
          onCreate: viewModel.createSubscription,
          onUpdate: viewModel.updateSubscription,
        );
      case 3:
        return HomepageConfigScreen(
          config: viewModel.homepageConfig,
          onSave: viewModel.saveHomepageConfig,
          onUpdateSection: viewModel.updateHomepageConfigSection,
        );
      case 4:
        return const ScheduleScreen();
      case 5:
        return RequestsScreen(
          requests: viewModel.getFilteredRequests(),
          onApprove: viewModel.approveRequest,
          onReject: viewModel.rejectRequest,
          onInProgress: viewModel.markRequestInProgress,
          onComplete: viewModel.completeRequest,
          onFilterStatus: viewModel.setRequestFilter,
          onFilterType: viewModel.setRequestTypeFilter,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
