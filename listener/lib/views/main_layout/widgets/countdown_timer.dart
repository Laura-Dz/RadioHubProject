import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final String timeRemaining;
  final bool isSmall;

  const CountdownTimer({Key? key, required this.timeRemaining, this.isSmall = false}) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _currentTime = widget.timeRemaining;
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.isSmall ? 6 : 8, vertical: widget.isSmall ? 2 : 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(widget.isSmall ? 6 : 8),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: AppColors.secondary, size: widget.isSmall ? 10 : 12),
          const SizedBox(width: 2),
          Text(_currentTime, style: TextStyle(color: AppColors.secondary, fontSize: widget.isSmall ? 8 : 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
