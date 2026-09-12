import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/sysadmin/radio_model.dart';
import '../../../view_models/sysadmin_view_model.dart';
import '../radios/widgets/security_verification_modal.dart';

class RadioDetailScreen extends StatefulWidget {
  final RadioModel radio;

  const RadioDetailScreen({Key? key, required this.radio}) : super(key: key);

  @override
  State<RadioDetailScreen> createState() => _RadioDetailScreenState();
}

class _RadioDetailScreenState extends State<RadioDetailScreen> {
  late RadioModel _radio;

  @override
  void initState() {
    super.initState();
    _radio = widget.radio;
  }

  @override
  void didUpdateWidget(covariant RadioDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _radio = widget.radio;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();
    final isLive = _radio.isLive;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header App Bar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () {
                viewModel.selectRadioForDetail(null);
              },
            ),
            title: Row(
              children: [
                const Icon(Icons.radio_rounded, color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 10),
                Text(
                  _radio.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLive ? AppColors.live.withOpacity(0.15) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isLive ? AppColors.live : AppColors.textMuted),
                  ),
                  child: Text(
                    isLive ? '🔴 Live' : '🟢 Recorded',
                    style: TextStyle(
                      color: isLive ? AppColors.live : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit Station'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primaryDark),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _showEditStationDialog(context, viewModel),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _confirmDeleteStation(context, viewModel),
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. OVERVIEW METRICS ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.mic_rounded,
                        title: 'Hosts',
                        value: '${_radio.hostsCount}',
                        color: AppColors.chartMusic,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.tune_rounded,
                        title: 'Techs',
                        value: '${_radio.techniciansCount}',
                        color: AppColors.chartSports,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Admin',
                        value: _radio.radioAdminName,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.bar_chart_rounded,
                        title: 'Listeners',
                        value: NumberFormat('#,###').format(_radio.listenerCount),
                        color: AppColors.chartTalk,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. RADIO INFORMATION CARD
                _buildCard(
                  title: 'RADIO INFORMATION',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      _buildInfoRow('Name:', _radio.name),
                      _buildInfoRow('Broadcast Link:', _radio.broadcastLink, isLink: true),
                      _buildInfoRow(
                        'Contract Copy:',
                        _radio.contractCopy ?? 'Station License Agreement PDF',
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                          label: const Text('View Contract PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _viewContractPDF(context),
                        ),
                      ),
                      _buildInfoRow('Created:', DateFormat('MMMM dd, yyyy').format(_radio.createdAt)),
                      _buildInfoRow(
                        'Status:',
                        isLive ? '🔴 Live Broadcasting' : '🟢 Recorded Broadcasts',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. RADIO ADMIN INFORMATION (WITH STRICT SECURITY)
                _buildCard(
                  title: 'RADIO ADMIN INFORMATION',
                  icon: Icons.person_pin_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name:', _radio.radioAdminName),
                      _buildInfoRow('Email:', _radio.radioAdminEmail),
                      _buildInfoRow('Phone:', _radio.radioAdminPhone ?? '+1 234 567 890'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.security_rounded, size: 16),
                            label: const Text('Modify Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: () => _showModifyAdminModal(context, viewModel),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.camera_alt_outlined, color: AppColors.warning, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'Facial Verification Required for Sensitive Changes',
                                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. HOSTS TABLE
                _buildCard(
                  title: 'HOSTS (${_radio.hostsCount})',
                  icon: Icons.mic_rounded,
                  child: Column(
                    children: [
                      _buildPersonRow(
                        name: 'Sarah Johnson',
                        subtitle: 'Morning Shows Host',
                        status: 'Active',
                        stat: '📅 5 shows this week',
                        isOnline: true,
                      ),
                      const Divider(color: AppColors.cardBorder, height: 16),
                      _buildPersonRow(
                        name: 'Mike Williams',
                        subtitle: 'Co-host & Producer',
                        status: 'Active',
                        stat: '📅 3 shows this week',
                        isOnline: true,
                      ),
                      const Divider(color: AppColors.cardBorder, height: 16),
                      _buildPersonRow(
                        name: 'Emma Chen',
                        subtitle: 'Guest Host',
                        status: 'Inactive',
                        stat: '📅 0 shows this week',
                        isOnline: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. TECHNICIANS TABLE
                _buildCard(
                  title: 'TECHNICIANS (${_radio.techniciansCount})',
                  icon: Icons.tune_rounded,
                  child: Column(
                    children: [
                      _buildPersonRow(
                        name: 'David Brown',
                        subtitle: 'Lead Audio Engineer (Full-time)',
                        status: 'Active',
                        stat: '📅 5 sessions this week',
                        isOnline: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6. PERFORMANCE METRICS (GROWTH & SHOW DISTRIBUTION)
                _buildCard(
                  title: 'PERFORMANCE METRICS',
                  icon: Icons.insights_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listener Growth & Weekly Show Distribution',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      // Listener growth simulated chart bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildChartBar('Mon', 1400, 2500),
                          _buildChartBar('Tue', 1850, 2500),
                          _buildChartBar('Wed', 2100, 2500),
                          _buildChartBar('Thu', 1950, 2500),
                          _buildChartBar('Fri', 2456, 2500, isHighlight: true),
                          _buildChartBar('Sat', 2200, 2500),
                          _buildChartBar('Sun', 1700, 2500),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          '📈 Consistent listener retention over the last 7 broadcast days',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLink ? AppColors.chartTalk : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildPersonRow({
    required String name,
    required String subtitle,
    required String status,
    required String stat,
    required bool isOnline,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            name[0],
            style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isOnline ? AppColors.success.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isOnline ? '🟢 $status' : '🟡 $status',
            style: TextStyle(
              color: isOnline ? AppColors.success : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Text(
            stat,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChartBar(String label, int value, int maxVal, {bool isHighlight = false}) {
    final heightRatio = (value / maxVal).clamp(0.1, 1.0);

    return Expanded(
      child: Column(
        children: [
          Text(
            '${(value / 1000).toStringAsFixed(1)}k',
            style: TextStyle(
              color: isHighlight ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 120 * heightRatio,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isHighlight ? AppColors.primaryLight : AppColors.primaryDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: isHighlight ? Border.all(color: Colors.white, width: 1) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _viewContractPDF(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text('Contract: ${_radio.name}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Container(
          width: 480,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STATION BROADCASTING LICENSE', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Station ID: ${_radio.id}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('Authorized Administrator: ${_radio.radioAdminName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('Streaming Frequency: ${_radio.broadcastLink}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 14),
              const Text(
                'This agreement certifies that the licensee is authorized to stream digital broadcast content over the RadioHub network subject to compliance with platform licensing requirements.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _showModifyAdminModal(BuildContext context, SysAdminViewModel viewModel) {
    final nameController = TextEditingController(text: '${_radio.radioAdminName} (Modified)');
    final phoneController = TextEditingController(text: '+1 234 567 891');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modify RadioAdmin: ${_radio.name}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Admin Name', labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Contact Phone', labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              // Open strict security verification modal
              showDialog(
                context: context,
                builder: (_) => SecurityVerificationModal(
                  title: 'CONFIRMATION REQUIRED',
                  actionDescription: 'You are about to modify the RadioAdmin account for "${_radio.name}"',
                  changes: {
                    'Name': '${_radio.radioAdminName} → ${nameController.text.trim()}',
                    'Phone': '${_radio.radioAdminPhone ?? '+1 234 567 890'} → ${phoneController.text.trim()}',
                  },
                  requireFaceVerification: true,
                  onConfirm: (password, otp) async {
                    await viewModel.updateRadioWithSecurity(
                      radioId: _radio.id,
                      updates: {
                        'radioAdminName': nameController.text.trim(),
                        'radioAdminPhone': phoneController.text.trim(),
                      },
                      password: password,
                      otp: otp,
                      requireFace: true,
                    );
                    setState(() {
                      _radio = _radio.copyWith(
                        radioAdminName: nameController.text.trim(),
                        radioAdminPhone: phoneController.text.trim(),
                      );
                    });
                  },
                ),
              );
            },
            child: const Text('Proceed to Verification'),
          ),
        ],
      ),
    );
  }

  void _showEditStationDialog(BuildContext context, SysAdminViewModel viewModel) {
    final streamController = TextEditingController(text: _radio.broadcastLink);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Station: ${_radio.name}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: streamController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Broadcast Stream Link', labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) => SecurityVerificationModal(
                  title: 'CONFIRMATION REQUIRED',
                  actionDescription: 'Update Broadcast Stream for "${_radio.name}"',
                  changes: {
                    'Broadcast Stream': '${_radio.broadcastLink} → ${streamController.text.trim()}',
                  },
                  requireFaceVerification: false,
                  onConfirm: (password, otp) async {
                    await viewModel.updateRadioWithSecurity(
                      radioId: _radio.id,
                      updates: {'broadcastLink': streamController.text.trim()},
                      password: password,
                      otp: otp,
                    );
                    setState(() {
                      _radio = _radio.copyWith(broadcastLink: streamController.text.trim());
                    });
                  },
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStation(BuildContext context, SysAdminViewModel viewModel) {
    showDialog(
      context: context,
      builder: (_) => SecurityVerificationModal(
        title: 'DECOMMISSION RADIO STATION',
        actionDescription: 'You are about to deactivate station "${_radio.name}" and suspend its RadioAdmin account.',
        changes: {
          'Station': _radio.name,
          'Action': 'Deactivate & Archive',
        },
        requireFaceVerification: true,
        onConfirm: (password, otp) async {
          await viewModel.deleteRadio(
            radioId: _radio.id,
            password: password,
            otp: otp,
          );
        },
      ),
    );
  }
}

