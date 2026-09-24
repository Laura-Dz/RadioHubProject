import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/technician/technician_announcement.dart';
import '../../../view_models/technician_view_model.dart';

class AnnouncementsPanel extends StatefulWidget {
  final String? activeSessionId;

  const AnnouncementsPanel({Key? key, this.activeSessionId}) : super(key: key);

  @override
  State<AnnouncementsPanel> createState() => _AnnouncementsPanelState();
}

class _AnnouncementsPanelState extends State<AnnouncementsPanel> {
  int _selectedFilter = 0; // 0 = Intermediary (Between), 1 = Show Reads (Within), 2 = All

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final due = vm.activeDueAnnouncement;
    final all = vm.announcements;

    List<TechnicianAnnouncement> displayed;
    if (_selectedFilter == 0) {
      displayed = vm.intermediaryAnnouncements;
    } else if (_selectedFilter == 1) {
      displayed = vm.showAnnouncements;
    } else {
      displayed = all;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Due alert banner
            if (due != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ANNOUNCEMENT DUE NOW IN LINEUP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  due.category.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'From: ${due.listenerName} · ${due.durationSeconds}s · Scheduled for ${due.assignedSlots.isNotEmpty ? due.assignedSlots.first.timeLabel : "Now"}',
                            style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => vm.dismissDueAnnouncement(due.id),
                      child: const Text('Dismiss', style: TextStyle(color: Colors.brown)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: () => vm.markAnnouncementAired(due, sessionId: widget.activeSessionId),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Inject & Air'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Header & Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Announcements Lineup',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${vm.pendingAnnouncements.length} pending',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text('Intermediary (${vm.intermediaryAnnouncements.where((a) => !a.isAired).length})'),
                      selected: _selectedFilter == 0,
                      onSelected: (v) => setState(() => _selectedFilter = 0),
                    ),
                    ChoiceChip(
                      label: Text('Inside Shows (${vm.showAnnouncements.where((a) => !a.isAired).length})'),
                      selected: _selectedFilter == 1,
                      onSelected: (v) => setState(() => _selectedFilter = 1),
                    ),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedFilter == 2,
                      onSelected: (v) => setState(() => _selectedFilter = 2),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // Announcement List
            if (displayed.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text(
                        _selectedFilter == 0
                            ? 'No intermediary announcements scheduled.'
                            : _selectedFilter == 1
                                ? 'No show live reads scheduled.'
                                : 'No announcements found.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final a = displayed[i];
                  return _AnnouncementRow(
                    announcement: a,
                    activeSessionId: widget.activeSessionId,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  final TechnicianAnnouncement announcement;
  final String? activeSessionId;

  const _AnnouncementRow({
    required this.announcement,
    this.activeSessionId,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TechnicianViewModel>();
    final a = announcement;
    final isAired = a.isAired;
    final isBetween = a.isBetweenSlot;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAired ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAired ? Colors.grey.shade200 : (isBetween ? Colors.teal.shade200 : Colors.blue.shade200),
          width: isAired ? 1 : 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAired
                  ? Colors.grey.shade200
                  : (isBetween ? Colors.teal.shade50 : Colors.blue.shade50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBetween ? Icons.queue_music : Icons.record_voice_over,
              size: 18,
              color: isAired ? Colors.grey : (isBetween ? Colors.teal : Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAired ? Colors.grey.shade200 : Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAired ? Colors.grey : Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBetween ? Colors.teal.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isBetween ? 'Between Shows' : 'Show Read',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isBetween ? Colors.teal.shade800 : Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${a.durationSeconds}s · From: ${a.listenerName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  a.finalText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (a.assignedSlots.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Slots: ${a.assignedSlots.map((s) => "${s.timeLabel}${s.showName != null ? " (${s.showName})" : ""}").join(", ")}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isAired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    a.airedBy != null ? 'Aired (${a.airedBy})' : 'Aired',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => vm.markAnnouncementAired(a, sessionId: activeSessionId),
              icon: Icon(isBetween ? Icons.playlist_add : Icons.check, size: 14),
              label: Text(isBetween ? 'Inject & Air' : 'Mark Aired'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBetween ? Colors.teal : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
