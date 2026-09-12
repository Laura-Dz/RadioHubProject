import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../view_models/sysadmin_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _facialRecognitionEnabled = true;
  bool _twoFactorEnabled = true;
  bool _auditLoggingEnabled = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.settings_rounded, color: AppColors.primaryLight, size: 22),
            SizedBox(width: 10),
            Text(
              'PLATFORM SETTINGS & TOOLS',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DATABASE & SEEDING SECTION
            _buildSectionCard(
              title: 'DATABASE SEEDING & TEST DATA',
              icon: Icons.storage_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Populate Firestore with sample stations, users, shows, transactions, and announcements.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: viewModel.isSeeding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(viewModel.isSeeding ? 'Seeding Firestore...' : 'Run Full Database Seeding'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: viewModel.isSeeding
                            ? null
                            : () async {
                                await viewModel.seedMockData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.success,
                                      content: Text('Firestore successfully seeded with complete demo dataset!'),
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reload Cached Data'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: viewModel.refreshData,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. SECURITY PROTOCOLS SECTION
            _buildSectionCard(
              title: 'SECURITY & VERIFICATION PROTOCOLS',
              icon: Icons.security_rounded,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Mandatory Facial Recognition for Sensitive Updates', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Requires camera face scan for modifying station administrators and deletions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: _facialRecognitionEnabled,
                    activeColor: AppColors.primaryLight,
                    onChanged: (val) => setState(() => _facialRecognitionEnabled = val),
                  ),
                  const Divider(color: AppColors.cardBorder),
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication (OTP)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Verify 6-digit TOTP code from Authenticator app for privileged actions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: _twoFactorEnabled,
                    activeColor: AppColors.primaryLight,
                    onChanged: (val) => setState(() => _twoFactorEnabled = val),
                  ),
                  const Divider(color: AppColors.cardBorder),
                  SwitchListTile(
                    title: const Text('System Audit Logging', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: const Text('Maintain permanent timestamped logs in system_activity collection', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: _auditLoggingEnabled,
                    activeColor: AppColors.primaryLight,
                    onChanged: (val) => setState(() => _auditLoggingEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. SYSTEM INFORMATION
            _buildSectionCard(
              title: 'SYSTEM ENVIRONMENT',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  _buildSysInfoRow('Application Version', AppConstants.appVersion),
                  _buildSysInfoRow('Current SysAdmin', 'Laura DZ (lauradz@example.com)'),
                  _buildSysInfoRow('Platform Core', 'RadioHub Cloud Infrastructure'),
                  _buildSysInfoRow('Firestore Environment', 'Connected & Synchronized'),
                  _buildSysInfoRow('Biometrics Engine', 'Active Biometrics Model v2.4'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSysInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

