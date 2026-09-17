import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/constants/app_colors.dart';
import 'comments_sheet.dart';
import 'queue_sheet.dart';
import 'poll_vote_sheet.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Play button — hero of the row
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: vm.togglePlay,
              icon: Icon(
                vm.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 26,
              ),
              label: Text(vm.isPlaying ? 'Pause' : 'Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary actions
          Row(
            children: [
              _action(
                context,
                icon: Icons.queue_music,
                label: 'Queue',
                onTap: () => _openQueue(context, vm),
              ),
              const SizedBox(width: 8),
              _action(
                context,
                icon: Icons.forum_outlined,
                label: 'Chat',
                enabled: vm.canComment,
                onTap: () => _openComments(context, vm),
              ),
              const SizedBox(width: 8),
              _action(
                context,
                icon: vm.isCallAccepted
                    ? Icons.mic
                    : (vm.isCallHeld
                        ? Icons.pause_circle_filled
                        : (vm.hasActiveCall ? Icons.hourglass_top : Icons.headset_mic_outlined)),
                label: vm.isCallAccepted
                    ? 'On Air'
                    : (vm.isCallHeld
                        ? 'On Hold'
                        : (vm.hasActiveCall ? 'In Queue' : 'VOIP Call')),
                enabled: vm.canCall || vm.hasActiveCall,
                highlight: vm.hasActiveCall,
                onTap: () => _requestCall(context, vm),
              ),
              const SizedBox(width: 8),
              _action(
                context,
                icon: Icons.poll_outlined,
                label: 'Poll',
                enabled: vm.hasActivePoll,
                highlight: vm.hasActivePoll && !vm.hasVoted,
                onTap: () => _openPoll(context, vm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    bool highlight = false,
  }) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: MouseRegion(
          cursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: highlight
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border,
                  width: highlight ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(icon, size: 20, color: AppColors.primary),
                        const SizedBox(height: 4),
                        Text(label,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  if (highlight)
                    Positioned(
                      top: 4,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openComments(BuildContext context, RadioStationViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(session: vm.liveSession!),
    );
  }

  void _openQueue(BuildContext context, RadioStationViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueSheet(
        liveSession: vm.liveSession,
        upcomingSessions: vm.upcomingSessions,
      ),
    );
  }

  void _openPoll(BuildContext context, RadioStationViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PollVoteSheet(),
    );
  }

  void _requestCall(BuildContext context, RadioStationViewModel vm) {
    if (vm.hasActiveCall) {
      final status = vm.myCallStatus;
      String title = 'VOIP Call in Queue';
      String message =
          'Your VOIP connection request is waiting for the host or technician to bring you on air.';
      if (status == 'accepted') {
        title = '🎙️ Live On Air (VOIP)';
        message =
            'You are connected live to the studio! The host and listeners can hear you now.';
      } else if (status == 'held') {
        title = '⏸️ VOIP Call On Hold';
        message =
            'The host has temporarily placed you on hold. Please stay connected, you will return on air shortly.';
      }

      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  status == 'accepted'
                      ? Icons.mic
                      : (status == 'held'
                          ? Icons.pause_circle_filled
                          : Icons.hourglass_top),
                  color: status == 'accepted'
                      ? AppColors.success
                      : (status == 'held' ? AppColors.warning : AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 13.5)),
                if (status == 'accepted') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          vm.isVoipMuted ? Icons.mic_off : Icons.graphic_eq,
                          color: vm.isVoipMuted ? AppColors.error : AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            vm.isVoipMuted
                                ? 'Microphone Muted'
                                : 'Microphone Active (Broadcasting)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: vm.isVoipMuted ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            vm.toggleVoipMute();
                            setDialogState(() {});
                          },
                          child: Text(
                            vm.isVoipMuted ? 'Unmute' : 'Mute',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Minimize'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    await vm.cancelCallRequest();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('VOIP Call disconnected'),
                          backgroundColor: AppColors.textSecondary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(status == 'accepted' ? 'Hang Up' : 'Leave Queue'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // New in-app VOIP Call request dialog
    final user = FirebaseAuth.instance.currentUser;
    final topicCtrl = TextEditingController(text: user?.displayName ?? '');
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.headset_mic_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Live Studio VOIP Call',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join the show live over VOIP using your device microphone. No phone charges or cellular calling required.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Name or Question Topic',
                  hintText: 'e.g. Marie - Question on the show topic',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      final topic = topicCtrl.text.trim();
                      setDialogState(() => submitting = true);
                      try {
                        await vm.requestCall(topic);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'VOIP Call queued! The studio host has been notified.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  e.toString().replaceFirst('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.mic, size: 18),
              label: Text(submitting ? 'Connecting…' : 'Connect VOIP'),
            ),
          ],
        ),
      ),
    );
  }
}

