import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/auth_view_model.dart';
import '../../../core/theme/app_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      child: const Center(child: Icon(Icons.person, size: 40, color: AppColors.primary)),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Guest User',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'guest@radio.stream',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(user?.isGuest == true ? 'Guest Account' : 'Listener', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Following', '24')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Listen Time', '42h')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Favorites', '18')),
            ],
          ),
          const SizedBox(height: 24),
          _buildMenuItem(context, icon: Icons.history, title: 'Listening History', subtitle: 'Last 7 days', onTap: () {}),
          _buildMenuItem(context, icon: Icons.bookmark, title: 'Saved Shows', subtitle: 'Your bookmarks', onTap: () {}),
          _buildMenuItem(context, icon: Icons.download, title: 'Downloads', subtitle: 'Offline content', onTap: () {}),
          _buildMenuItem(context, icon: Icons.volume_up, title: 'Audio Quality', subtitle: 'High (320kbps)', onTap: () {}),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Logout from account',
            onTap: () async {
              await authViewModel.logout();
              if (!authViewModel.hasError && context.mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDanger ? AppColors.error : Theme.of(context).primaryColor),
        title: Text(title, style: TextStyle(color: isDanger ? AppColors.error : null)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
