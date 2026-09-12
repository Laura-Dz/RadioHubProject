import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/host_model.dart';
import '../../../../core/models/radio_admin/program_model.dart';
import '../../../../core/widgets/common_widgets.dart';

class HostFormDialog extends StatefulWidget {
  final RadioAdminViewModel viewModel;
  final Host? host;

  const HostFormDialog({
    Key? key,
    required this.viewModel,
    this.host,
  }) : super(key: key);

  @override
  State<HostFormDialog> createState() => _HostFormDialogState();
}

class _HostFormDialogState extends State<HostFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  bool _isActive = true;
  List<String> _selectedProgramIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.host?.name ?? '');
    _emailController = TextEditingController(text: widget.host?.email ?? '');
    _phoneController = TextEditingController(text: widget.host?.phone ?? '');
    _bioController = TextEditingController(text: widget.host?.bio ?? '');
    _isActive = widget.host?.isActive ?? true;
    _selectedProgramIds = widget.host?.programIds ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.host != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RadioAdminColors.success,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(isEditing ? Icons.edit : Icons.person_add, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Host' : 'New Host',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Full Name', 'Enter host name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email', 'Enter email address'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration('Phone', 'Enter phone number'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _bioController,
                        decoration: _inputDecoration('Bio', 'Enter host bio'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      _buildProgramsSelection(),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Host is active and can be assigned to programs'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeColor: RadioAdminColors.success,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                      backgroundColor: RadioAdminColors.success,
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

  Widget _buildProgramsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Programs',
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
          children: widget.viewModel.programs.map((program) {
            final isSelected = _selectedProgramIds.contains(program.id);
            return FilterChip(
              label: Text(program.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedProgramIds.add(program.id);
                  } else {
                    _selectedProgramIds.remove(program.id);
                  }
                });
              },
              selectedColor: RadioAdminColors.success.withOpacity(0.2),
              checkmarkColor: RadioAdminColors.success,
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
        borderSide: BorderSide(color: RadioAdminColors.success, width: 2),
      ),
      filled: true,
      fillColor: RadioAdminColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final host = Host(
      id: widget.host?.id ?? 'host_${DateTime.now().millisecondsSinceEpoch}',
      radioId: widget.viewModel.radioId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      photoUrl: widget.host?.photoUrl,
      isActive: _isActive,
      programIds: _selectedProgramIds,
      createdAt: widget.host?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.host != null) {
      widget.viewModel.updateHost(host);
    } else {
      widget.viewModel.createHost(host);
    }

    Navigator.pop(context);
  }
}