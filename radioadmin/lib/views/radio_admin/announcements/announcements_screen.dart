import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/radio_admin/announcement_request_model.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/announcement_card.dart';
import 'widgets/validate_modal.dart';
import 'widgets/reject_modal.dart';
import 'tariffs_management_screen.dart';
import '../../../core/utils/browser_open.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _filter = 'all'; // all, pending, scheduled, rejected
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();

    // Combine all announcements from pending & scheduled streams
    final all = <AnnouncementRequest>[
      ...vm.pendingAnnouncements,
      ...vm.scheduledAnnouncements,
    ];

    // Filter by tab
    final filteredByStatus = all.where((a) {
      if (_filter == 'pending') return a.isPending;
      if (_filter == 'scheduled') return a.isScheduled || a.status == AnnouncementRequestStatus.validated;
      if (_filter == 'rejected') return a.status == AnnouncementRequestStatus.rejected;
      return true;
    }).toList();

    // Search filter
    final query = _searchCtrl.text.toLowerCase().trim();
    final displayed = query.isEmpty
        ? filteredByStatus
        : filteredByStatus.where((a) {
            return a.listenerName.toLowerCase().contains(query) ||
                a.categoryLabel.toLowerCase().contains(query) ||
                a.finalText.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manage Pricing top banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.14),
                    AppColors.gold.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.price_change_outlined, color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Announcement Pricing & Formula',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Configure rate per 15-sec unit for each category. Final price is rate × diffusions/day × days.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TariffsManagementScreen()),
                      );
                    },
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Manage Pricing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search bar and filter chips
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by listener, category, message...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _chip('all', 'All (${all.length})'),
                const SizedBox(width: 8),
                _chip('pending', 'Pending (${vm.pendingAnnouncements.length})'),
                const SizedBox(width: 8),
                _chip('scheduled', 'Scheduled (${vm.scheduledAnnouncements.length})'),
                const SizedBox(width: 8),
                _chip('rejected', 'Rejected'),
              ],
            ),
            const SizedBox(height: 16),

            // List of announcements
            if (displayed.isEmpty)
              const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements found',
                subtitle: 'New requests submitted by listeners will appear here.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = displayed[i];
                  return AnnouncementCard(
                    announcement: a,
                    onValidate: a.isPending
                        ? () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => ValidateAnnouncementModal(announcement: a),
                            )
                        : null,
                    onReject: a.isPending
                        ? () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => RejectAnnouncementModal(announcement: a),
                            )
                        : null,
                    onPrint: (a.isScheduled || a.status == AnnouncementRequestStatus.validated)
                        ? () async {
                            final url = await context.read<RadioAdminViewModel>().generateAnnouncementPDF(a.id);
                            openInBrowserTab(url);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Document officiel généré et prêt pour impression'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String filter, String label) {
    final selected = _filter == filter;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
