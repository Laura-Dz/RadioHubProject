import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../announcements/create_announcement_modal.dart';
import '../../announcements/announcement_payment_screen.dart';

class RequestAnnouncementCard extends StatelessWidget {
  const RequestAnnouncementCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final radio = vm.radio;
    if (radio == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.gold.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Make an announcement',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text(
                      'Broadcast your message on this radio',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info bullets
          _bullet('Your message will be read on air'),
          _bullet('Pay only if the radio validates it'),
          _bullet('Refunded if the radio rejects it'),

          const SizedBox(height: 18),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openAnnouncementForm(context),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Request an announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAnnouncementForm(BuildContext context) async {
    final vm = context.read<RadioStationViewModel>();
    final radio = vm.radio;
    if (radio == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final listenerName = user?.displayName ?? 'Listener';

    // Open the announcement form with this radio pre-filled
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateAnnouncementModal(
        radioId: radio.id,
        radioName: radio.name,
        listenerName: listenerName,
      ),
    );

    if (result == null || !context.mounted) return;

    // Navigate to payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementPaymentScreen(
          announcementId: result['announcementId'] as String,
          finalPrice: (result['finalPrice'] as num).toDouble(),
          radioName: radio.name,
        ),
      ),
    );
  }
}
