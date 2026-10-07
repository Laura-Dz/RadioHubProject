import 'package:flutter/material.dart';
import '../../../../core/models/radio_admin/staff_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';

class StaffCard extends StatelessWidget {
  final StaffMember staff;
  final VoidCallback onEdit;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback? onResetPassword;

  const StaffCard({
    Key? key,
    required this.staff,
    required this.onEdit,
    required this.onSuspend,
    required this.onReactivate,
    this.onResetPassword,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = staff;
    final isSusp = s.isSuspended;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSusp ? AppColors.error.withOpacity(0.3) : AppColors.border),
      ),
      child: Row(
        children: [
          AppAvatar(
            photoUrl: s.photoUrl,
            name: s.name,
            radius: 22,
            backgroundColor: isSusp ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            textColor: isSusp ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(s.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.role == StaffRole.host ? AppColors.primary.withOpacity(0.1) : AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.role == StaffRole.host ? 'Host' : 'Technician',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: s.role == StaffRole.host ? AppColors.primary : AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isSusp)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Suspended',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Active',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${s.email} · ${s.phone.isNotEmpty ? s.phone : "No phone"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (isSusp && s.suspendReason != null) ...[
                  const SizedBox(height: 4),
                  Text('Reason: ${s.suspendReason}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.error, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          if (s.hasAuthAccount && onResetPassword != null)
            Tooltip(
              message: 'Reset technician password',
              child: IconButton(
                icon: const Icon(Icons.lock_reset, size: 18, color: AppColors.primary),
                onPressed: onResetPassword,
              ),
            ),
          Tooltip(
            message: 'Edit staff member',
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              onPressed: onEdit,
            ),
          ),
          if (isSusp)
            Tooltip(
              message: 'Reactivate staff member',
              child: IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                onPressed: onReactivate,
              ),
            )
          else
            Tooltip(
              message: 'Suspend staff member',
              child: IconButton(
                icon: const Icon(Icons.block_outlined, size: 18, color: AppColors.error),
                onPressed: onSuspend,
              ),
            ),
        ],
      ),
    );
  }
}
