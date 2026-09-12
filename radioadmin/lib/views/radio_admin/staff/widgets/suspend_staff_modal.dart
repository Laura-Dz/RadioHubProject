import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/staff_model.dart';
import '../../../../core/constants/app_colors.dart';

class SuspendStaffModal extends StatefulWidget {
  final StaffMember staff;
  const SuspendStaffModal({Key? key, required this.staff}) : super(key: key);

  @override
  State<SuspendStaffModal> createState() => _SuspendStaffModalState();
}

class _SuspendStaffModalState extends State<SuspendStaffModal> {
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.block_outlined, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Suspend staff member',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to suspend ${widget.staff.name}? They will lose access to broadcasting and station controls.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for suspension',
                  hintText: 'e.g. Conduct violation, temporary leave...',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Suspend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await context.read<RadioAdminViewModel>().suspendStaff(
          widget.staff.id,
          _reasonCtrl.text.trim(),
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.staff.name} has been suspended'), backgroundColor: AppColors.warning),
      );
    }
  }
}
