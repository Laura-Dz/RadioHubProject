import 'package:flutter/material.dart';
import '../../../core/models/radio_model.dart';
import '../../../core/models/schedule_model.dart';
import '../../main_layout/widgets/live_badge.dart';

class ProgramPoster extends StatelessWidget {
  final RadioModel radio;
  final ScheduleItem? currentProgram;
  final VoidCallback onKnowMore;

  const ProgramPoster({
    Key? key,
    required this.radio,
    required this.currentProgram,
    required this.onKnowMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final program = currentProgram;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0F3460)]
              : [const Color(0xFF4A90D9), const Color(0xFF6C63FF)],
        ),
      ),
      child: Stack(
        children: [
          if (radio.coverImageUrl != null)
            Positioned.fill(
              child: Image.network(
                radio.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusBadge(program),
                    const Spacer(),
                    if (radio.isLive && radio.listenerCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.headphones, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatCount(radio.listenerCount)} listening',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (program != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_formatDate(program.startTime)} • ${program.timeRange}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    program?.title ?? 'No Program',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                ),
                if (program?.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      program!.description!,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: onKnowMore,
                    child: Row(
                      children: [
                        Text(
                          'Know More',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.6), size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ScheduleItem? program) {
    if (program == null) {
      return buildBadgeForTag('ENDED');
    }
    return buildBadgeForTag(program.displayTag);
  }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
