import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/radio_admin/staff_model.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/staff_card.dart';
import 'widgets/create_staff_modal.dart';
import 'widgets/edit_staff_modal.dart';
import 'widgets/suspend_staff_modal.dart';
import 'widgets/reset_password_modal.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({Key? key}) : super(key: key);

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final query = _searchCtrl.text.toLowerCase().trim();

    final allFiltered = query.isEmpty
        ? vm.staff
        : vm.staff.where((s) => s.name.toLowerCase().contains(query) || s.email.toLowerCase().contains(query)).toList();

    final hosts = allFiltered.where((s) => s.role == StaffRole.host).toList();
    final technicians = allFiltered.where((s) => s.role == StaffRole.technician).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff & Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const CreateStaffModal(),
            ),
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Add Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Hosts (${hosts.length})'),
            Tab(text: 'Technicians (${technicians.length})'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search staff by name or email...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildStaffList(hosts, 'No hosts found'),
                  _buildStaffList(technicians, 'No technicians found'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(List<StaffMember> list, String emptyMsg) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: emptyMsg,
        subtitle: 'Add staff members to assign them to shows and broadcasts.',
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final staff = list[i];
        return StaffCard(
          staff: staff,
          onEdit: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => EditStaffModal(staff: staff),
          ),
          onSuspend: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => SuspendStaffModal(staff: staff),
          ),
          onReactivate: () => context.read<RadioAdminViewModel>().reactivateStaff(staff.id),
          onResetPassword: staff.hasAuthAccount
              ? () => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ResetPasswordModal(staff: staff),
                  )
              : null,
        );
      },
    );
  }
}
