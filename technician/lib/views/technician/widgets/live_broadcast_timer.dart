import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/network_time_service.dart';

String _formatDuration(Duration d) {
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

/// A real-time countdown / overtime count-up timer widget for live broadcasts.
/// 
/// - When now < scheduledEnd: counts DOWN the remaining time in regular/success colors.
/// - When now >= scheduledEnd: counts UP the overtime/extra time, with colors turning RED.
class LiveBroadcastTimer extends StatefulWidget {
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final bool isLive;
  final bool isCompact;
  final ValueChanged<bool>? onOvertimeChanged;

  const LiveBroadcastTimer({
    Key? key,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.isLive = true,
    this.isCompact = false,
    this.onOvertimeChanged,
  }) : super(key: key);

  @override
  State<LiveBroadcastTimer> createState() => _LiveBroadcastTimerState();
}

class _LiveBroadcastTimerState extends State<LiveBroadcastTimer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late DateTime _now;
  late AnimationController _pulseController;
  bool _wasOvertime = false;

  @override
  void initState() {
    super.initState();
    _now = NetworkTimeService().now();
    _wasOvertime = _now.isAfter(widget.scheduledEnd);
    if (widget.onOvertimeChanged != null) {
      widget.onOvertimeChanged!(_wasOvertime);
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final current = NetworkTimeService().now();
        final isOvertimeNow = current.isAfter(widget.scheduledEnd);
        if (isOvertimeNow != _wasOvertime) {
          _wasOvertime = isOvertimeNow;
          widget.onOvertimeChanged?.call(isOvertimeNow);
        }
        setState(() {
          _now = current;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveBroadcastTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduledEnd != widget.scheduledEnd) {
      _wasOvertime = _now.isAfter(widget.scheduledEnd);
      widget.onOvertimeChanged?.call(_wasOvertime);
    }
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

    final timeString = (isOvertime ? '+' : '') + _formatDuration(diff);
    final timerColor = isOvertime ? AppColors.error : AppColors.success;
    final labelText = isOvertime ? 'EXTRA TIME' : 'REMAINING';

    if (widget.isCompact) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isOvertime
              ? AppColors.error.withOpacity(0.12)
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
              size: 13,
              color: timerColor,
            ),
            const SizedBox(width: 5),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: timerColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: timerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: timerColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Standard card presentation (used in Live Card and Session Details)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOvertime
            ? AppColors.error.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOvertime ? AppColors.error : AppColors.border,
          width: isOvertime ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: isOvertime
                ? Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController)
                : const AlwaysStoppedAnimation(1.0),
            child: Icon(
              isOvertime ? Icons.warning_rounded : Icons.timer_outlined,
              size: 18,
              color: timerColor,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: timerColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: timerColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: timerColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isOvertime
                    ? 'Exceeded end time (${DateFormat('HH:mm').format(widget.scheduledEnd)})'
                    : 'Scheduled until ${DateFormat('HH:mm').format(widget.scheduledEnd)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isOvertime ? AppColors.error : AppColors.textSecondary,
                  fontWeight:
                      isOvertime ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
