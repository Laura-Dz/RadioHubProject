import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../view_models/profile_view_model.dart';
import '../../../core/constants/app_colors.dart';
import 'profile/edit_profile_modal.dart';
import 'profile/change_password_modal.dart';
import '../../announcements/my_announcements_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    if (vm.loading || vm.profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final p = vm.profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ---------------- Header card ----------------
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: SafeImage(
                          imageUrl: p.photoUrl,
                          width: 88,
                          height: 88,
                          fallback: Center(
                            child: Text(
                              p.displayName.isNotEmpty
                                  ? p.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  p.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                if (p.city.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.white.withOpacity(0.75)),
                      const SizedBox(width: 4),
                      Text(
                        p.city,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _openEdit(context, vm),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------------- Activity section ----------------
          _sectionHeader('Activity'),
          _menuCard([
            _menuItem(
              icon: Icons.campaign_outlined,
              title: 'My Announcements',
              subtitle: 'Track status, scheduled airing times & request another',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAnnouncementsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // ---------------- Account section ----------------
          _sectionHeader('Account'),
          _menuCard([
            _menuItem(
              icon: Icons.person_outline,
              title: 'Personal information',
              subtitle: 'Name, phone, bio, city',
              onTap: () => _openEdit(context, vm),
            ),
            _menuItem(
              icon: Icons.lock_outline,
              title: 'Change password',
              subtitle: 'Update your account password',
              onTap: () => _openChangePassword(context),
            ),
          ]),
          const SizedBox(height: 20),

          // ---------------- Danger zone ----------------
          _sectionHeader('Account actions'),
          _menuCard([
            _menuItem(
              icon: Icons.logout,
              title: 'Sign out',
              subtitle: 'Log out of this device',
              onTap: () => _confirmSignOut(context, vm),
            ),
            _menuItem(
              icon: Icons.delete_outline,
              title: 'Delete account',
              subtitle: 'Permanently remove your account and data',
              danger: true,
              onTap: () => _confirmDelete(context, vm),
            ),
          ]),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------- helpers ----------

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );

  Widget _menuCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (danger ? AppColors.error : AppColors.primary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 16,
                  color: danger ? AppColors.error : AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, ProfileViewModel vm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const EditProfileModal(),
    );
  }

  void _openChangePassword(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ChangePasswordModal(),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, ProfileViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await vm.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, ProfileViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your account and all associated data. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 15),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await vm.deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
