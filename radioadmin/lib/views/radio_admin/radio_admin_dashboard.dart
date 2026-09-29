import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/radio_admin_view_model.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/radio_admin_sidebar.dart';
import 'dashboard/dashboard_screen.dart';
import 'subscription/subscription_screen.dart';
import 'staff/staff_screen.dart';
import 'announcements/announcements_screen.dart';
import 'radio_page/radio_page_editor_screen.dart';
import 'metrics/metrics_screen.dart';
import 'insights/insights_screen.dart';
import 'programs/programs_screen.dart';
import 'schedule/schedule_view_screen.dart';
import 'media/media_library_screen.dart';
import 'transactions/transactions_screen.dart';

class RadioAdminDashboard extends StatefulWidget {
  final String radioId;
  final String radioName;

  const RadioAdminDashboard({
    Key? key,
    this.radioId = 'radio_1',
    this.radioName = 'My Radio',
  }) : super(key: key);

  @override
  State<RadioAdminDashboard> createState() => _RadioAdminDashboardState();
}

class _RadioAdminDashboardState extends State<RadioAdminDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioAdminViewModel>().initialize(
        radioId: widget.radioId,
        radioName: widget.radioName,
      );
    });
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return const DashboardScreen();
      case 1: return const SubscriptionScreen();
      case 2: return const StaffScreen();
      case 3: return const AnnouncementsScreen();
      case 4: return const RadioPageEditorScreen();
      case 5: return const MetricsScreen();
      case 6:
        return InsightsScreen(
          onNavigateToSubscription: () => setState(() => _selectedIndex = 1),
        );
      case 7: return const ProgramsScreen();
      case 8: return const ScheduleViewScreen();
      case 9: return const MediaLibraryScreen();
      case 10: return const TransactionsScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          RadioAdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) {
              if (i == 11) {
                // Settings
                return;
              }
              if (i == 12) {
                // Logout
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                return;
              }
              setState(() => _selectedIndex = i);
            },
            radioName: widget.radioName,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
