import 'package:flutter/material.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/theme/app_colors.dart';

class UpcomingModal extends StatelessWidget {
  final List<ScheduleItem> upcomingPrograms;
  final VoidCallback onViewFullSchedule;

  const UpcomingModal({
    Key? key,
    required this.upcomingPrograms,
    required this.onViewFullSchedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.queue_music, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Upcoming Programs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Next 24 hours',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (upcomingPrograms.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No upcoming programs in the next 24 hours.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: upcomingPrograms.length,
                itemBuilder: (context, index) {
                  final item = upcomingPrograms[index];
                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(item.startTime),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${item.duration.inMinutes}m',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(item.host, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isLive ? Colors.green : (item.isUpcoming ? Colors.orange : Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.isLive ? 'Live' : (item.isUpcoming ? 'Upcoming' : 'Recorded'),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    onTap: () {},
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onViewFullSchedule,
              child: const Text('View Full Schedule →'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
