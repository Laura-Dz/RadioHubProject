import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/host_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_avatar.dart';
import 'widgets/host_form_dialog.dart';

class HostsTab extends StatelessWidget {
  final String radioId;

  const HostsTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hosts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your radio hosts',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ActionButton(
                label: 'New Host',
                icon: Icons.person_add,
                onPressed: () => _showHostDialog(context, viewModel),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.hosts.isEmpty
                    ? EmptyState(
                        title: 'No hosts yet',
                        subtitle: 'Add your first host to get started',
                        icon: Icons.person,
                        actionLabel: 'Add Host',
                        onAction: () => _showHostDialog(context, viewModel),
                      )
                    : _buildHostsTable(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildHostsTable(RadioAdminViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: RadioAdminColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: RadioAdminColors.divider),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: _buildHeaderCell('Host'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Email'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Programs'),
                ),
                Expanded(
                  flex: 1,
                  child: _buildHeaderCell('Status'),
                ),
                const SizedBox(width: 120),
              ],
            ),
          ),
          // Data rows
          Expanded(
            child: ListView.separated(
              itemCount: viewModel.hosts.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: RadioAdminColors.divider),
              itemBuilder: (context, index) {
                final host = viewModel.hosts[index];
                return _buildHostRow(context, host, viewModel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: RadioAdminColors.textSecondary,
      ),
    );
  }

  Widget _buildHostRow(BuildContext context, Host host, RadioAdminViewModel viewModel) {
    final programNames = host.programIds.isNotEmpty
        ? host.programIds
            .map((id) => viewModel.programs.firstWhere(
                  (p) => p.id == id,
                  orElse: () => Program(
                    id: '',
                    radioId: '',
                    name: 'Unknown',
                    description: '',
                    category: ProgramCategory.music,
                    duration: Duration.zero,
                    createdAt: DateTime.now(),
                  ),
                ).name)
            .join(', ')
        : 'No programs';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                AppAvatar(
                  photoUrl: host.photoUrl,
                  name: host.name,
                  radius: 20,
                  backgroundColor: RadioAdminColors.primary.withOpacity(0.1),
                  textColor: RadioAdminColors.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      host.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: RadioAdminColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      host.email,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RadioAdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              host.email,
              style: const TextStyle(
                fontSize: 13,
                color: RadioAdminColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              programNames,
              style: const TextStyle(
                fontSize: 13,
                color: RadioAdminColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: host.isActive
                    ? RadioAdminColors.success.withOpacity(0.1)
                    : RadioAdminColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                host.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: host.isActive ? RadioAdminColors.success : RadioAdminColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: RadioAdminColors.textSecondary,
                  onPressed: () => _showHostDialog(context, viewModel, host: host),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: RadioAdminColors.error,
                  onPressed: () => _confirmDeleteHost(context, viewModel, host),
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHostDialog(BuildContext context, RadioAdminViewModel viewModel, {Host? host}) {
    showDialog(
      context: context,
      builder: (context) => HostFormDialog(
        viewModel: viewModel,
        host: host,
      ),
    );
  }

  void _confirmDeleteHost(BuildContext context, RadioAdminViewModel viewModel, Host host) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Host'),
        content: Text('Are you sure you want to delete "${host.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteHost(host.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: RadioAdminColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

Widget _buildHeaderCell(String label) {
  return Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: RadioAdminColors.textSecondary,
    ),
  );
}