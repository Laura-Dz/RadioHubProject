import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/technician_view_model.dart';
import 'widgets/technician_sidebar.dart';
import 'dashboard/dashboard_screen.dart';
import 'sessions/sessions_screen.dart';
import 'programming/programming_screen.dart';
import 'hosts/hosts_screen.dart';
import 'programs/programs_screen.dart';
import 'media/media_screen.dart';
import 'metrics/metrics_screen.dart';
import 'notifications/notifications_screen.dart';

import 'widgets/session_reminder_host.dart';

class TechnicianDashboard extends StatefulWidget {
  final String radioId;
  final String radioName;
  const TechnicianDashboard({
    Key? key,
    required this.radioId,
    required this.radioName,
  }) : super(key: key);

  @override
  State<TechnicianDashboard> createState() => _State();
}

class _State extends State<TechnicianDashboard> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),          // 0
      SessionsScreen(),           // 1
      ProgrammingScreen(),        // 2 (merged Schedule + Timetable)
      HostsScreen(),              // 3
      ProgramsScreen(),           // 4
      MediaScreen(),              // 5
      MetricsScreen(),            // 6
      NotificationsScreen(),      // 7
      Center(child: Text('Settings')), // 8
    ];

    return Scaffold(
      body: SessionReminderHost(
        onOpenSessions: () => setState(() => _idx = 1),
        child: Row(
          children: [
            TechnicianSidebar(
              selectedIndex: _idx,
              onItemSelected: (i) => setState(() => _idx = i),
              radioName: widget.radioName,
              technicianName:
                  context.watch<TechnicianViewModel>().technicianName,
            ),
            Expanded(child: pages[_idx]),
          ],
        ),
      ),
    );
  }
}
