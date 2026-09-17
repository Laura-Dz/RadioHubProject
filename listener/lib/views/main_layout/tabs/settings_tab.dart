import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/profile_view_model.dart';
import '../../../view_models/main_layout_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/localization_service.dart';
import '../../language_selection/language_selection_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final prefs = vm.preferences;
    final themeVM = context.watch<MainLayoutViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============ APPEARANCE ============
          _sectionHeader('Appearance'),
          _card([
            _dropdownRow(
              icon: Icons.dark_mode_outlined,
              label: 'Theme',
              value: themeVM.isDarkMode ? 'dark' : 'light',
              options: const [
                ('light', 'Light'),
                ('dark', 'Dark'),
              ],
              onChanged: (v) {
                if ((v == 'dark') != themeVM.isDarkMode) {
                  themeVM.toggleTheme();
                }
              },
            ),
            _switchRow(
              icon: Icons.animation_outlined,
              label: 'Reduce motion',
              subtitle: 'Minimize animations across the app',
              value: prefs.reduceMotion,
              onChanged: (_) => vm.toggle('reduceMotion'),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ NOTIFICATIONS ============
          _sectionHeader('Notifications'),
          _card([
            _switchRow(
              icon: Icons.notifications_active_outlined,
              label: 'Push notifications',
              subtitle: 'Master switch for all notifications',
              value: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('pushNotifications'),
            ),
            _divider(),
            _switchRow(
              icon: Icons.star_border,
              label: 'Followed shows',
              subtitle: 'Alerts when shows you follow are about to air',
              value: prefs.followedShowAlerts,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('followedShowAlerts'),
            ),
            _divider(),
            _switchRow(
              icon: Icons.reply_outlined,
              label: 'Host replies',
              subtitle: 'Notify me when a host replies to my comment',
              value: prefs.hostReplyAlerts,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('hostReplyAlerts'),
            ),
            _divider(),
            _switchRow(
              icon: Icons.call_outlined,
              label: 'Call status',
              subtitle: 'Updates on my call request',
              value: prefs.callStatusAlerts,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('callStatusAlerts'),
            ),
            _divider(),
            _switchRow(
              icon: Icons.campaign_outlined,
              label: 'Announcement updates',
              subtitle: 'Alerts when my announcement is validated or rejected',
              value: prefs.announcementUpdates,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('announcementUpdates'),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ AUDIO ============
          _sectionHeader('Audio'),
          _card([
            _dropdownRow(
              icon: Icons.graphic_eq,
              label: 'Stream quality',
              value: prefs.audioQuality,
              options: const [
                ('auto', 'Auto'),
                ('low', 'Low (data saving)'),
                ('medium', 'Medium'),
                ('high', 'High'),
              ],
              onChanged: (v) => vm.setAudioQuality(v),
            ),
            _divider(),
            _switchRow(
              icon: Icons.data_saver_on_outlined,
              label: 'Data saver',
              subtitle: 'Reduce data usage during playback',
              value: prefs.dataSaver,
              onChanged: (_) => vm.toggle('dataSaver'),
            ),
            _divider(),
            _switchRow(
              icon: Icons.play_circle_outline,
              label: 'Autoplay on open',
              subtitle: 'Start playing when a show is opened',
              value: prefs.autoplayOnOpen,
              onChanged: (_) => vm.toggle('autoplayOnOpen'),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ LANGUAGE ============
          _sectionHeader('Language'),
          _card([
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LanguageSelectionScreen()),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _iconBox(Icons.language),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App language',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            LocalizationService()
                                    .currentLanguage
                                    ?.nativeName ??
                                'English',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ ABOUT ============
          _sectionHeader('About'),
          _card([
            _staticRow(
              icon: Icons.info_outline,
              label: 'App version',
              value: '1.0.0',
            ),
            _divider(),
            _linkRow(
              icon: Icons.policy_outlined,
              label: 'Privacy policy',
              onTap: () {},
            ),
            _divider(),
            _linkRow(
              icon: Icons.description_outlined,
              label: 'Terms of service',
              onTap: () {},
            ),
            _divider(),
            _linkRow(
              icon: Icons.help_outline,
              label: 'Help & support',
              onTap: () {},
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
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.divider, indent: 60);

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      );

  Widget _switchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final effectiveValue = enabled ? value : false;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: effectiveValue,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required List<(String, String)> options,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            items: options
                .map((o) => DropdownMenuItem(
                      value: o.$1,
                      child: Text(o.$2,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _linkRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}
