import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_models/sysadmin_view_model.dart';
import 'widgets/sysadmin_sidebar.dart';
import 'dashboard/dashboard_screen.dart';
import 'users/users_screen.dart';
import 'radios/radios_screen.dart';
import 'radio_detail/radio_detail_screen.dart';
import 'shows/shows_statistics_screen.dart';
import 'transactions/transactions_screen.dart';
import 'plans/subscription_plans_screen.dart';
import 'settings/settings_screen.dart';

class SysAdminDashboard extends StatelessWidget {
  const SysAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Navigation Sidebar
          SysAdminSidebar(
            selectedIndex: viewModel.selectedTab,
            onItemSelected: viewModel.setSelectedTab,
          ),

          // Main View Content
          Expanded(
            child: _buildMainView(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(SysAdminViewModel viewModel) {
    // If a specific radio was selected, drill down into RadioDetailScreen
    if (viewModel.selectedRadioForDetail != null) {
      return RadioDetailScreen(radio: viewModel.selectedRadioForDetail!);
    }

    switch (viewModel.selectedTab) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const UsersScreen();
      case 2:
        return const RadiosScreen();
      case 3:
        return const ShowsStatisticsScreen();
      case 4:
        return const TransactionsScreen();
      case 5:
        return const SubscriptionPlansScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
