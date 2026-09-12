import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/program_model.dart';
import '../../../../core/models/radio_admin/host_model.dart';
import '../../../../core/widgets/common_widgets.dart';

class ProgramFormDialog extends StatefulWidget {
  final RadioAdminViewModel viewModel;
  final Program? program;

  const ProgramFormDialog({
    Key? key,
    required this.viewModel,
    this.program,
  }) : super(key: key);

  @override
  State<ProgramFormDialog> createState() => _ProgramFormDialogState();
}

class _ProgramFormDialogState extends State<ProgramFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationHoursController;
  late TextEditingController _durationMinutesController;
  ProgramCategory _selectedCategory = ProgramCategory.music;
  bool _isActive = true;
  List<String> _selectedHostIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _descriptionController = TextEditingController(text: widget.program?.description ?? '');
    _durationHoursController = TextEditingController(
      text: (widget.program?.duration.inHours ?? 2).toString(),
    );
    _durationMinutesController = TextEditingController(
      text: (widget.program?.duration.inMinutes.remainder(60) ?? 0).toString(),
    );
    _selectedCategory = widget.program?.category ?? ProgramCategory.music;
    _isActive = widget.program?.isActive ?? true;
    _selectedHostIds = widget.program?.hostIds ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.program != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RadioAdminColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(isEditing ? Icons.edit : Icons.add, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Program' : 'New Program',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Program Name', 'Enter program name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Program name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration('Description', 'Enter program description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<ProgramCategory>(
                        value: _selectedCategory,
                        decoration: _inputDecoration('Category', 'Select category'),
                        items: ProgramCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(category.iconData, size: 18, color: category.iconColor),
                                const SizedBox(width: 8),
                                Text(category.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationHoursController,
                              decoration: _inputDecoration('Hours', '0'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final hours = int.tryParse(value ?? '0');
                                if (hours == null || hours < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _durationMinutesController,
                              decoration: _inputDecoration('Minutes', '0'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final minutes = int.tryParse(value ?? '0');
                                if (minutes == null || minutes < 0 || minutes >= 60) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hosts selection
                      _buildHostsSelection(),
                      const SizedBox(height: 16),

                      // Active status
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Program is visible and can be scheduled'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeColor: RadioAdminColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RadioAdminColors.background,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: RadioAdminColors.divider),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RadioAdminColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(isEditing ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hosts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.viewModel.hosts.map((host) {
            final isSelected = _selectedHostIds.contains(host.id);
            return FilterChip(
              label: Text(host.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedHostIds.add(host.id);
                  } else {
                    _selectedHostIds.remove(host.id);
                  }
                });
              },
              selectedColor: RadioAdminColors.primary.withOpacity(0.2),
              checkmarkColor: RadioAdminColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: RadioAdminColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: RadioAdminColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: RadioAdminColors.primary, width: 2),
      ),
      filled: true,
      fillColor: RadioAdminColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_durationHoursController.text) ?? 0;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    final duration = Duration(hours: hours, minutes: minutes);

    final program = Program(
      id: widget.program?.id ?? 'prog_${DateTime.now().millisecondsSinceEpoch}',
      radioId: widget.viewModel.radioId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      duration: duration,
      isActive: _isActive,
      hostIds: _selectedHostIds,
      coHostIds: [],
      metadata: {},
      createdAt: widget.program?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.program != null) {
      widget.viewModel.updateProgram(program);
    } else {
      widget.viewModel.createProgram(program);
    }

    Navigator.pop(context);
  }
}