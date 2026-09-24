import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'my_announcements_screen.dart';

class AnnouncementSubmittedScreen extends StatelessWidget {
  final String announcementId;
  final String radioName;
  final String reference;
  final double amount;

  const AnnouncementSubmittedScreen({
    Key? key,
    required this.announcementId,
    required this.radioName,
    required this.reference,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      size: 56, color: AppColors.success),
                ),
                const SizedBox(height: 24),

                const Text('Payment received',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Your announcement has been sent to $radioName for review.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 24),

                // Receipt card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _row('Amount', '${amount.toStringAsFixed(0)} XAF'),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 10),
                      _row('Status', 'Awaiting validation',
                          valueColor: AppColors.warning),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 10),
                      _row('Reference', reference, mono: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmation notification banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Payment confirmation message sent to your Notification Center.',
                          style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // What happens next
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.info),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The radio will review your announcement. You will be notified when it is validated and scheduled, or if it is rejected.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MyAnnouncementsScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('My Requests',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: reference));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Reference copied to clipboard'),
                          backgroundColor: AppColors.info),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Copy Reference ID',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor, bool mono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
              fontFamily: mono ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
