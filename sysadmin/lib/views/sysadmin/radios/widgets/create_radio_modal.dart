import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../view_models/sysadmin_view_model.dart';

class CreateRadioModal extends StatefulWidget {
  const CreateRadioModal({Key? key}) : super(key: key);

  @override
  State<CreateRadioModal> createState() => _CreateRadioModalState();
}

class _CreateRadioModalState extends State<CreateRadioModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _broadcastLinkController = TextEditingController(text: 'http://stream.radiohub.net:8000/live');
  final _contractCopyController = TextEditingController(text: 'Radio Station Commercial Agreement - Valid 2026');
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController(text: 'admin123');
  final _sysAdminPasswordController = TextEditingController(text: 'laura123');
  final _otpController = TextEditingController(text: '123456');

  String _category = AppConstants.radioCategories.first;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _broadcastLinkController.dispose();
    _contractCopyController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _sysAdminPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.radio_rounded, color: AppColors.primaryLight, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Create New Radio Station',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Provision station infrastructure and create a dedicated RadioAdmin account.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // SECTION 1: Radio Details
                const Text(
                  '1. Radio Station Profile',
                  style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Station Name', 'e.g. Skyline Beats FM'),
                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        dropdownColor: AppColors.surface,
                        value: _category,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Category', ''),
                        items: AppConstants.radioCategories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _broadcastLinkController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Broadcast Stream URL', 'http://host:port/stream'),
                  validator: (v) => v == null || v.isEmpty ? 'Broadcast URL is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contractCopyController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Contract Details / PDF Reference', 'Contract terms reference...'),
                ),

                const SizedBox(height: 20),

                // SECTION 2: RadioAdmin Account Setup
                const Text(
                  '2. RadioAdmin Account Credentials',
                  style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adminNameController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Admin Full Name', 'e.g. Jane Doe'),
                        validator: (v) => v == null || v.isEmpty ? 'Admin name is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _adminEmailController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Admin Email', 'admin@station.com'),
                        validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adminPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Temporary Admin Password', '••••••••'),
                  validator: (v) => v == null || v.length < 6 ? 'Password min 6 chars' : null,
                ),

                const SizedBox(height: 20),

                // SECTION 3: SysAdmin Verification Gate
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_person_rounded, color: AppColors.warning, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '3. SysAdmin Authorization Gate',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sysAdminPasswordController,
                              obscureText: true,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: _buildInputDecoration('SysAdmin Password', 'Enter master password'),
                              validator: (v) => v == null || v.isEmpty ? 'SysAdmin password required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
                              decoration: _buildInputDecoration('6-Digit OTP', '123456').copyWith(counterText: ''),
                              validator: (v) => v == null || v.length != 6 ? '6-digit code required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],

                const SizedBox(height: 24),

                // Footer actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Create Radio Station'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleCreate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final viewModel = context.read<SysAdminViewModel>();
      await viewModel.createRadioWithAdmin({
        'name': _nameController.text.trim(),
        'broadcastLink': _broadcastLinkController.text.trim(),
        'contractCopy': _contractCopyController.text.trim(),
        'category': _category,
        'adminName': _adminNameController.text.trim(),
        'adminEmail': _adminEmailController.text.trim(),
        'adminPassword': _adminPasswordController.text,
        'sysAdminPassword': _sysAdminPasswordController.text,
        'otpCode': _otpController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Radio "${_nameController.text}" provisioned successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }
}

