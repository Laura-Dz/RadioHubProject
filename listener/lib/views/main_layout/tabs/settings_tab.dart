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
          _sectionHeader(context, 'Appearance'),
          _card(context, [
            _dropdownRow(
              context,
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
              context,
              icon: Icons.animation_outlined,
              label: 'Reduce motion',
              subtitle: 'Minimize animations across the app',
              value: prefs.reduceMotion,
              onChanged: (_) => vm.toggle('reduceMotion'),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ NOTIFICATIONS ============
          _sectionHeader(context, 'Notifications'),
          _card(context, [
            _switchRow(
              context,
              icon: Icons.notifications_active_outlined,
              label: 'Push notifications',
              subtitle: 'Master switch for all notifications',
              value: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('pushNotifications'),
            ),
            _divider(context),
            _switchRow(
              context,
              icon: Icons.star_border,
              label: 'Followed shows',
              subtitle: 'Alerts when shows you follow are about to air',
              value: prefs.followedShowAlerts,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('followedShowAlerts'),
            ),
            _divider(context),
            _switchRow(
              context,
              icon: Icons.reply_outlined,
              label: 'Host replies',
              subtitle: 'Notify me when a host replies to my comment',
              value: prefs.hostReplyAlerts,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('hostReplyAlerts'),
            ),
            _divider(context),
            _switchRow(
              context,
              icon: Icons.call_outlined,
              label: 'Call status',
              subtitle: 'Updates on my call request',
              value: prefs.callStatusAlerts,
              enabled: prefs.pushNotifications,
              onChanged: (_) => vm.toggle('callStatusAlerts'),
            ),
            _divider(context),
            _switchRow(
              context,
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
          _sectionHeader(context, 'Audio'),
          _card(context, [
            _dropdownRow(
              context,
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
            _divider(context),
            _switchRow(
              context,
              icon: Icons.data_saver_on_outlined,
              label: 'Data saver',
              subtitle: 'Reduce data usage during playback',
              value: prefs.dataSaver,
              onChanged: (_) => vm.toggle('dataSaver'),
            ),
            _divider(context),
            _switchRow(
              context,
              icon: Icons.play_circle_outline,
              label: 'Autoplay on open',
              subtitle: 'Start playing when a show is opened',
              value: prefs.autoplayOnOpen,
              onChanged: (_) => vm.toggle('autoplayOnOpen'),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ LANGUAGE ============
          _sectionHeader(context, 'Language'),
          _card(context, [
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
                          Text(
                            'App language',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocalizationService()
                                    .currentLanguage
                                    ?.nativeName ??
                                'English',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ============ ABOUT ============
          _sectionHeader(context, 'About'),
          _card(context, [
            _staticRow(
              context,
              icon: Icons.info_outline,
              label: 'App version',
              value: '1.0.0',
            ),
            _divider(context),
            _linkRow(
              context,
              icon: Icons.policy_outlined,
              label: 'Privacy policy',
              onTap: () {},
            ),
            _divider(context),
            _linkRow(
              context,
              icon: Icons.description_outlined,
              label: 'Terms of service',
              onTap: () {},
            ),
            _divider(context),
            _linkRow(
              context,
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

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _card(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.border,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? Colors.white12 : AppColors.divider,
      indent: 60,
    );
  }

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      );

  Widget _switchRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
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

  Widget _dropdownRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required List<(String, String)> options,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            dropdownColor: isDark ? const Color(0xFF242438) : Colors.white,
            items: options
                .map((o) => DropdownMenuItem(
                      value: o.$1,
                      child: Text(
                        o.$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? Colors.white38 : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
