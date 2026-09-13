import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/call.dart';
import '../../../view_models/host_view_model.dart';

class OnCallCard extends StatefulWidget {
  final Call call;
  const OnCallCard({Key? key, required this.call}) : super(key: key);

  @override
  State<OnCallCard> createState() => _State();
}

class _State extends State<OnCallCard> {
  @override
  Widget build(BuildContext context) {
    final since = widget.call.acceptedAt ?? DateTime.now();
    final d = DateTime.now().difference(since);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.success.withOpacity(0.12),
          AppColors.success.withOpacity(0.02),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_in_talk,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              const Text('ON CALL',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 0.8)),
              const Spacer(),
              Text('${d.inMinutes}m ${d.inSeconds.remainder(60)}s',
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.call.userName,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          if (widget.call.userPhone.isNotEmpty)
            Text(widget.call.userPhone,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.read<HostViewModel>().endCall(widget.call),
              icon: const Icon(Icons.call_end, size: 16),
              label: const Text('End call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
