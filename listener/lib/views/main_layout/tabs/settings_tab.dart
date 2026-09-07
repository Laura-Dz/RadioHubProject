import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/main_layout_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/language_model.dart';
import '../../../core/services/shared_preferences_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../view_models/language_selection_view_model.dart';
import '../../language_selection/language_selection_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainViewModel = context.watch<MainLayoutViewModel>();
    final prefsService = context.read<SharedPreferencesService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Appearance'),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light and dark theme'),
              value: mainViewModel.isDarkMode,
              onChanged: (_) => mainViewModel.toggleTheme(),
              secondary: Icon(mainViewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: mainViewModel.isDarkMode ? Colors.amber : Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Language'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('App Language'),
              subtitle: Text(LanguageModel.supportedLanguages.firstWhere((lang) => lang.code == prefsService.getLanguage(), orElse: () => LanguageModel.supportedLanguages.first).nativeName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()));
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Audio & Streaming'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.quality),
                  title: const Text('Stream Quality'),
                  subtitle: const Text('High (320kbps)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: const Text('Audio Effects'),
                  subtitle: const Text('Bass boost, Equalizer'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.data_usage),
                  title: const Text('Data Saver'),
                  subtitle: const Text('Reduce data usage'),
                  trailing: Switch(value: false, onChanged: (_) {}, activeColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive show alerts and updates'),
                  trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Show Recommendations'),
                  subtitle: const Text('Get personalized suggestions'),
                  trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}
