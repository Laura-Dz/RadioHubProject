import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/call.dart';
import '../../../view_models/host_view_model.dart';

class CallQueue extends StatelessWidget {
  const CallQueue({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();
    final pending = vm.pendingCalls;
    final held = vm.heldCalls;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_outlined,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Call queue',
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (pending.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${pending.length}',
                      style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.error,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty && held.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text('No pending calls',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textMuted)),
            )
          else ...[
            ...pending.map((c) => _CallRow(call: c, held: false)),
            ...held.map((c) => _CallRow(call: c, held: true)),
          ],
        ],
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  final Call call;
  final bool held;
  const _CallRow({required this.call, required this.held});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HostViewModel>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: held
            ? AppColors.surfaceAlt
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: held ? AppColors.border : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: (held ? AppColors.textMuted : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  held ? Icons.pause : Icons.call,
                  size: 15,
                  color: held ? AppColors.textMuted : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(call.userName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('VOIP',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ),
                    if (call.topic.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          call.topic,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      held ? 'On hold · ${_held(call)}' : _waiting(call),
                      style: TextStyle(
                          fontSize: 11,
                          color: held
                              ? AppColors.warning
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (held)
            Row(
              children: [
                Expanded(
                  child: _action(
                    'Resume',
                    Icons.play_arrow,
                    AppColors.success,
                    () => vm.acceptCall(call),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _action(
                    'Decline',
                    Icons.close,
                    AppColors.error,
                    () => vm.declineCall(call),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _action(
                    'Accept',
                    Icons.check,
                    AppColors.success,
                    () => vm.acceptCall(call),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _action(
                    'Hold',
                    Icons.pause,
                    AppColors.warning,
                    () => vm.holdCall(call),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _action(
                    'Decline',
                    Icons.close,
                    AppColors.error,
                    () => vm.declineCall(call),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _action(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _waiting(Call c) {
    final d = DateTime.now().difference(c.requestedAt);
    if (d.inMinutes < 1) return 'Waiting ${d.inSeconds}s';
    return 'Waiting ${d.inMinutes}m';
  }

  String _held(Call c) {
    if (c.heldAt == null) return '—';
    final d = DateTime.now().difference(c.heldAt!);
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}
