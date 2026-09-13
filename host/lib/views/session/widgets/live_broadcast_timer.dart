import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/network_time_service.dart';

/// Helper to format durations into HH:MM:SS or MM:SS
String _formatTimerDuration(Duration d) {
  final totalSeconds = d.inSeconds.abs();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    final hh = hours.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
  return '$mm:$ss';
}

/// Compact Live Broadcast Timer Badge — designed for AppBars and headers.
/// Shows countdown remaining during scheduled duration, and switches to RED extra time count-up.
class LiveBroadcastTimerBadge extends StatefulWidget {
  final DateTime scheduledEnd;
  final DateTime scheduledStart;
  final bool isLive;

  const LiveBroadcastTimerBadge({
    Key? key,
    required this.scheduledEnd,
    required this.scheduledStart,
    this.isLive = true,
  }) : super(key: key);

  @override
  State<LiveBroadcastTimerBadge> createState() => _LiveBroadcastTimerBadgeState();
}

class _LiveBroadcastTimerBadgeState extends State<LiveBroadcastTimerBadge> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = NetworkTimeService().now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = NetworkTimeService().now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      return const SizedBox.shrink();
    }

    final isOvertime = _now.isAfter(widget.scheduledEnd);
    final Duration diff = isOvertime
        ? _now.difference(widget.scheduledEnd)
        : widget.scheduledEnd.difference(_now);

    final timeString = (isOvertime ? '+' : '') + _formatTimerDuration(diff);
    final badgeColor = isOvertime ? AppColors.error : AppColors.success;
    final labelText = isOvertime ? 'EXTRA TIME' : 'REMAINING';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOvertime
            ? AppColors.error.withOpacity(0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOvertime ? AppColors.error : AppColors.border,
          width: isOvertime ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOvertime ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 5),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: badgeColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full Studio Live Broadcast Timer Card — designed for side panels and studio dashboards.
class LiveBroadcastTimerCard extends StatefulWidget {
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final bool isLive;

  const LiveBroadcastTimerCard({
    Key? key,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.isLive = true,
  }) : super(key: key);

  @override
  State<LiveBroadcastTimerCard> createState() => _LiveBroadcastTimerCardState();
}

class _LiveBroadcastTimerCardState extends State<LiveBroadcastTimerCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late DateTime _now;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _now = NetworkTimeService().now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = NetworkTimeService().now();
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      return const SizedBox.shrink();
    }

    final isOvertime = _now.isAfter(widget.scheduledEnd);
    final Duration diff = isOvertime
        ? _now.difference(widget.scheduledEnd)
        : widget.scheduledEnd.difference(_now);

    final formattedTime = (isOvertime ? '+' : '') + _formatTimerDuration(diff);
    final primaryColor = isOvertime ? AppColors.error : AppColors.success;
    final totalSlot = widget.scheduledEnd.difference(widget.scheduledStart).inSeconds;
    final elapsedSec = _now.difference(widget.scheduledStart).inSeconds;
    final progress = totalSlot > 0
        ? (elapsedSec / totalSlot).clamp(0.0, 1.0)
        : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOvertime
            ? AppColors.error.withOpacity(0.08)
            : AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOvertime
              ? AppColors.error
              : AppColors.primary.withOpacity(0.25),
          width: isOvertime ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FadeTransition(
                    opacity: isOvertime
                        ? Tween<double>(begin: 0.3, end: 1.0)
                            .animate(_pulseController)
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOvertime ? 'PROGRAM OVERRUN' : 'BROADCAST TIMER',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOvertime ? 'EXTRA TIME' : 'REMAINING',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOvertime ? 'over allotted slot' : 'left in program',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isOvertime
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: isOvertime ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOvertime ? AppColors.error : AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slot: ${DateFormat('HH:mm').format(widget.scheduledStart)} – ${DateFormat('HH:mm').format(widget.scheduledEnd)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isOvertime)
                const Text(
                  'Please conclude soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
