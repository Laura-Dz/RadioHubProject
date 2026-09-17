import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/profile_view_model.dart';
import '../../../../core/constants/app_colors.dart';

class ChangePasswordModal extends StatefulWidget {
  const ChangePasswordModal({Key? key}) : super(key: key);
  @override
  State<ChangePasswordModal> createState() => _State();
}

class _State extends State<ChangePasswordModal> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Change password',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _label('Current password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _current,
                  obscureText: !_showCurrent,
                  decoration: _dec('Enter current password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _showCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18),
                      onPressed: () =>
                          setState(() => _showCurrent = !_showCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _label('New password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _next,
                  obscureText: !_showNext,
                  decoration: _dec('At least 8 characters').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _showNext
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18),
                      onPressed: () => setState(() => _showNext = !_showNext),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'At least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _label('Confirm new password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirm,
                  obscureText: !_showConfirm,
                  decoration: _dec('Re-enter new password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _next.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 16),
                      label: const Text('Update password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context
          .read<ProfileViewModel>()
          .changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
