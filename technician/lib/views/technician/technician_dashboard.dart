import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/technician_section.dart';
import '../../view_models/technician_view_model.dart';
import '../../core/services/data_seeder.dart';
import 'widgets/technician_sidebar.dart';
import 'sections/sessions_section.dart';
import 'sections/hosts_section.dart';
import 'sections/programs_section.dart';
import 'sections/schedule_section.dart';
import 'sections/media_section.dart';
import 'sections/metrics_section.dart';
import 'sections/settings_section.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({Key? key}) : super(key: key);

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  TechnicianSection _selected = TechnicianSection.schedule;
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          TechnicianSidebar(
            selected: _selected,
            onSectionSelected: (section) => setState(() => _selected = section),
          ),
          Expanded(
            child: _buildContent(viewModel),
          ),
        ],
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: _isSeeding
                  ? null
                  : () async {
                      setState(() => _isSeeding = true);
                      try {
                        await DataSeeder().seedAllData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Seeding completed!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Seeding failed: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isSeeding = false);
                        }
                      }
                    },
              backgroundColor: Colors.purple,
              child: _isSeeding
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildContent(TechnicianViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_selected) {
      case TechnicianSection.sessions:
        return const SessionsSection();
      case TechnicianSection.hosts:
        return const HostsSection();
      case TechnicianSection.programs:
        return const ProgramsSection();
      case TechnicianSection.schedule:
        return const ScheduleSection();
      case TechnicianSection.media:
        return const MediaSection();
      case TechnicianSection.metrics:
        return const MetricsSection();
      case TechnicianSection.settings:
        return const SettingsSection();
    }
  }
}
