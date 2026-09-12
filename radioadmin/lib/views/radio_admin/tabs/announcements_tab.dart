import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/announcement_model.dart';
import '../../../core/widgets/common_widgets.dart';

class AnnouncementsTab extends StatelessWidget {
  final String radioId;

  const AnnouncementsTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();
    final announcements = viewModel.announcements.where((a) {
      if (viewModel.announcementStatusFilter == 'all') return true;
      return a.status.name == viewModel.announcementStatusFilter;
    }).toList();

    final pendingCount = viewModel.announcements.where((a) => a.status == AnnouncementStatus.pending).length;
    final validatedCount = viewModel.announcements.where((a) => a.status == AnnouncementStatus.validated).length;
    final rejectedCount = viewModel.announcements.where((a) => a.status == AnnouncementStatus.rejected).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage listener announcements and requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ActionButton(
                label: 'New Request',
                icon: Icons.add,
                onPressed: () => _showAnnouncementForm(context, viewModel),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingCount.toString(),
                  Icons.pending_actions_rounded,
                  RadioAdminColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Validated',
                  validatedCount.toString(),
                  Icons.check_circle_rounded,
                  RadioAdminColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Rejected',
                  rejectedCount.toString(),
                  Icons.cancel_rounded,
                  RadioAdminColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RadioAdminColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RadioAdminColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: viewModel.announcementStatusFilter,
                style: const TextStyle(color: RadioAdminColors.textPrimary, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'validated', child: Text('Validated')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'printed', child: Text('Printed')),
                ],
                onChanged: (val) {
                  if (val != null) viewModel.setAnnouncementStatusFilter(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Announcements List
          Expanded(
            child: announcements.isEmpty
                ? const EmptyState(
                    icon: Icons.campaign_rounded,
                    title: 'No Announcements',
                    subtitle: 'Announcements from listeners will appear here.',
                  )
                : ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return _buildAnnouncementCard(context, announcement, viewModel);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RadioAdminColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: RadioAdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Announcement announcement, RadioAdminViewModel viewModel) {
    final statusColor = announcement.status == AnnouncementStatus.pending
        ? RadioAdminColors.warning
        : announcement.status == AnnouncementStatus.validated
            ? RadioAdminColors.success
            : announcement.status == AnnouncementStatus.rejected
                ? RadioAdminColors.error
                : RadioAdminColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: RadioAdminColors.primary.withOpacity(0.1),
                      child: Text(
                        announcement.listenerName.isNotEmpty == true ? announcement.listenerName[0].toUpperCase() : 'L',
                        style: const TextStyle(
                          color: RadioAdminColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.listenerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: RadioAdminColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy - hh:mm a').format(announcement.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: RadioAdminColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  announcement.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.message,
            style: const TextStyle(
              color: RadioAdminColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Category: ${announcement.announcementCategory ?? 'General'}',
            style: TextStyle(
              fontSize: 12,
              color: RadioAdminColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount: \$${announcement.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: RadioAdminColors.textSecondary,
            ),
          ),
          if (announcement.status == AnnouncementStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionButton(
                  label: 'Reject',
                  icon: Icons.close,
                  onPressed: () => viewModel.rejectAnnouncement(announcement.id),
                  outlined: true,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  label: 'Validate',
                  icon: Icons.check,
                  onPressed: () => viewModel.validateAnnouncement(announcement.id),
                ),
              ],
            ),
          ],
          if (announcement.status == AnnouncementStatus.validated && !announcement.isPrinted) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionButton(
                  label: 'Generate PDF',
                  icon: Icons.picture_as_pdf,
                  onPressed: () => viewModel.generateAnnouncementPDF(announcement.id),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAnnouncementForm(BuildContext context, RadioAdminViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Announcement Request'),
        content: const Text('Announcement request form placeholder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
