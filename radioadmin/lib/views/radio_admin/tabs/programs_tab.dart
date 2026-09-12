import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/models/radio_admin/host_model.dart';
import '../../../core/widgets/common_widgets.dart';
import 'widgets/program_form_dialog.dart';

class ProgramsTab extends StatelessWidget {
  final String radioId;

  const ProgramsTab({Key? key, required this.radioId}) : super(key: key);

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
                    'Programs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your radio programs',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ActionButton(
                label: 'New Program',
                icon: Icons.add,
                onPressed: () => _showProgramDialog(context, viewModel),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.programs.isEmpty
                    ? EmptyState(
                        title: 'No programs yet',
                        subtitle: 'Create your first program to get started',
                        icon: Icons.radio,
                        actionLabel: 'Create Program',
                        onAction: () => _showProgramDialog(context, viewModel),
                      )
                    : _buildProgramsTable(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsTable(RadioAdminViewModel viewModel) {
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
                const SizedBox(width: 40), // checkbox column
                Expanded(
                  flex: 3,
                  child: _buildHeaderCell('Program'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Category'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCell('Hosts'),
                ),
                Expanded(
                  flex: 1,
                  child: _buildHeaderCell('Duration'),
                ),
                Expanded(
                  flex: 1,
                  child: _buildHeaderCell('Status'),
                ),
                const SizedBox(width: 120), // actions
              ],
            ),
          ),
          // Data rows
          Expanded(
            child: ListView.separated(
              itemCount: viewModel.programs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: RadioAdminColors.divider),
              itemBuilder: (context, index) {
                final program = viewModel.programs[index];
                return _buildProgramRow(context, program, viewModel);
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

  Widget _buildProgramRow(BuildContext context, Program program, RadioAdminViewModel viewModel) {
    final hostNames = program.hostIds.isNotEmpty
        ? program.hostIds
            .map((id) => viewModel.hosts.firstWhere(
                  (h) => h.id == id,
                  orElse: () => Host(
                    id: '', 
                    radioId: '', 
                    name: 'Unknown', 
                    email: '',
                    createdAt: DateTime.now(),
                  ),
                ).name)
            .join(', ')
        : 'No hosts';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 40,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          // Program info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  program.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: RadioAdminColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (program.description.isNotEmpty)
                  Text(
                    program.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: RadioAdminColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: program.category.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(program.category.iconData, size: 14, color: program.category.iconColor),
                  const SizedBox(width: 6),
                  Text(
                    program.category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: program.category.iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Hosts
          Expanded(
            flex: 2,
            child: Text(
              hostNames,
              style: const TextStyle(
                fontSize: 13,
                color: RadioAdminColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Duration
          Expanded(
            flex: 1,
            child: Text(
              _formatDuration(program.duration),
              style: const TextStyle(
                fontSize: 13,
                color: RadioAdminColors.textPrimary,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: program.isActive
                    ? RadioAdminColors.success.withOpacity(0.1)
                    : RadioAdminColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                program.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: program.isActive ? RadioAdminColors.success : RadioAdminColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: RadioAdminColors.textSecondary,
                  onPressed: () => _showProgramDialog(context, viewModel, program: program),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: RadioAdminColors.error,
                  onPressed: () => _confirmDeleteProgram(context, viewModel, program),
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

  void _showProgramDialog(BuildContext context, RadioAdminViewModel viewModel, {Program? program}) {
    showDialog(
      context: context,
      builder: (context) => ProgramFormDialog(
        viewModel: viewModel,
        program: program,
      ),
    );
  }

  void _confirmDeleteProgram(BuildContext context, RadioAdminViewModel viewModel, Program program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Are you sure you want to delete "${program.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteProgram(program.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: RadioAdminColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}