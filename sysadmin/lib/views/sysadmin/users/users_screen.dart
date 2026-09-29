import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/sysadmin/user_overview_model.dart' as sys_user;
import '../../../view_models/sysadmin_view_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();
    final overview = viewModel.userOverview;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            floating: true,
            title: const Row(
              children: [
                Icon(Icons.people_alt_rounded, color: AppColors.primaryLight, size: 22),
                SizedBox(width: 10),
                Text(
                  'USERS OVERVIEW',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                tooltip: 'Refresh Users',
                onPressed: viewModel.refreshData,
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. ROLE COUNTERS ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCountCard(
                        title: 'All Accounts',
                        count: overview.totalListeners + overview.totalRadioAdmins,
                        icon: Icons.people_alt_rounded,
                        roleKey: 'all',
                        isSelected: viewModel.userRoleFilter == 'all',
                        color: AppColors.primaryLight,
                        onTap: () => viewModel.setUserRoleFilter('all'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRoleCountCard(
                        title: 'RadioAdmins',
                        count: overview.totalRadioAdmins,
                        icon: Icons.admin_panel_settings_rounded,
                        roleKey: 'radio_admin',
                        isSelected: viewModel.userRoleFilter == 'radio_admin',
                        color: AppColors.chartMusic,
                        onTap: () => viewModel.setUserRoleFilter(
                          viewModel.userRoleFilter == 'radio_admin' ? 'all' : 'radio_admin',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRoleCountCard(
                        title: 'Listeners',
                        count: overview.totalListeners,
                        icon: Icons.headphones_rounded,
                        roleKey: 'listener',
                        isSelected: viewModel.userRoleFilter == 'listener',
                        color: AppColors.chartTalk,
                        onTap: () => viewModel.setUserRoleFilter(
                          viewModel.userRoleFilter == 'listener' ? 'all' : 'listener',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. SEARCH & FILTER TOOLBAR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or station...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      viewModel.setUserSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => viewModel.setUserSearchQuery(val),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Role filter dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.surface,
                            value: viewModel.userRoleFilter,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Accounts')),
                              DropdownMenuItem(value: 'radio_admin', child: Text('👤 RadioAdmins')),
                              DropdownMenuItem(value: 'listener', child: Text('🎧 Listeners')),
                            ],
                            onChanged: (val) {
                              if (val != null) viewModel.setUserRoleFilter(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. ALL USERS TABLE
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ALL USERS (${viewModel.users.length})',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Showing filtered results',
                              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.cardBorder, height: 1),

                      if (viewModel.users.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No users found matching current filters.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.background.withOpacity(0.5)),
                            columns: const [
                              DataColumn(label: Text('Name', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Email', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Role', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Radio', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                            ],
                            rows: viewModel.users.map((user) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppColors.primary.withOpacity(0.2),
                                          child: Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          user.name,
                                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(user.email, style: const TextStyle(color: AppColors.textSecondary))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _getRoleColor(user.role).withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        user.roleLabel,
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(user.radioName ?? '—', style: const TextStyle(color: AppColors.textSecondary))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: user.isActive ? AppColors.success : AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          user.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: user.isActive ? AppColors.success : AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.visibility_rounded, color: AppColors.primaryLight, size: 20),
                                      tooltip: 'View Profile',
                                      onPressed: () => _showUserDetailModal(context, user),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCountCard({
    required String title,
    required int count,
    required IconData icon,
    required String roleKey,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              NumberFormat('#,###').format(count),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'listener':
        return AppColors.chartTalk;
      case 'host':
        return AppColors.chartMusic;
      case 'technician':
        return AppColors.chartSports;
      case 'radio_admin':
        return AppColors.primaryLight;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showUserDetailModal(BuildContext context, sys_user.User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                user.name.isNotEmpty ? user.name[0] : 'U',
                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('sys_user.User ID', user.id),
            _buildDetailRow('Role', user.roleLabel),
            _buildDetailRow('Assigned Radio', user.radioName ?? 'None (Platform Listener)'),
            _buildDetailRow('Account Status', user.isActive ? '🟢 Active' : '🔴 Suspended'),
            _buildDetailRow('Member Since', DateFormat('MMMM dd, yyyy').format(user.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

