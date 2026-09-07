import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LiveBadge extends StatelessWidget {
  final bool isSmall;
  final bool isTrending;
  final String? label;

  const LiveBadge({Key? key, this.isSmall = false, this.isTrending = false, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isTrending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
        child: Text(label ?? '🔥', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 10, vertical: isSmall ? 2 : 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.liveGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: isSmall ? 4 : 8, height: isSmall ? 4 : 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: isSmall ? 8 : 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
