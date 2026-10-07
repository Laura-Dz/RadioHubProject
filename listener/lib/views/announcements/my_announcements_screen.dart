import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../view_models/announcement_view_model.dart';
import '../../core/models/announcement_request.dart';
import '../../core/constants/app_colors.dart';
import 'create_announcement_modal.dart';

class MyAnnouncementsScreen extends StatefulWidget {
  final VoidCallback? onRequestNew;
  final bool showAppBar;

  const MyAnnouncementsScreen({
    Key? key,
    this.onRequestNew,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<MyAnnouncementsScreen> createState() => _MyAnnouncementsScreenState();
}

class _MyAnnouncementsScreenState extends State<MyAnnouncementsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Validated & Airing, 2: Awaiting, 3: Aired, 4: Rejected

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      context.read<AnnouncementViewModel>().watchMyAnnouncements(uid);
    });
  }

  Future<void> _requestAnother([AnnouncementRequest? previous]) async {
    if (widget.onRequestNew != null) {
      widget.onRequestNew!();
      return;
    }

    if (previous != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CreateAnnouncementModal(
          radioId: previous.radioId,
          radioName: previous.radioName,
          listenerName: previous.listenerName,
        ),
      );
      return;
    }

    // Always fetch all available radio stations directly from the Firestore database
    final user = FirebaseAuth.instance.currentUser;
    final listenerName = user?.displayName ?? user?.email ?? 'Listener';
    try {
      final snapshot = await FirebaseFirestore.instance.collection('radios').get();
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        final stationsMap = <String, String>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final name = data['name'] as String? ?? 'Radio Station';
          stationsMap[doc.id] = name;
        }
        _showStationSelectSheet(stationsMap, listenerName);
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    // Fallback if Firestore is offline
    _showStationSelectSheet({
      'radio_1': 'Radio Sunshine',
      'radio_2': 'City Beat FM',
      'radio_3': 'Capital Sound',
    }, listenerName);
  }

  void _showStationSelectSheet(Map<String, String> stations, String listenerName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textMuted = isDark ? Colors.white60 : AppColors.textSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Radio Station',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the station for your new announcement request:',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
                const SizedBox(height: 16),
                ...stations.entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.radio, color: AppColors.primary, size: 20),
                      ),
                      title: Text(e.value, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white12 : AppColors.border),
                      ),
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CreateAnnouncementModal(
                          radioId: e.key,
                          radioName: e.value,
                          listenerName: listenerName,
                        ),
                      );
                    },
                  ),
                );
              }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();
    final allItems = vm.mine;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textMuted = isDark ? Colors.white60 : AppColors.textSecondary;
    final cardBg = Theme.of(context).cardColor;

    // Filter items
    final filtered = allItems.where((it) {
      if (_selectedFilter == 1) return it.isValidated;
      if (_selectedFilter == 2) return it.isPendingValidation || it.isPendingPayment;
      if (_selectedFilter == 3) return it.isBroadcasted;
      if (_selectedFilter == 4) return it.isRejected;
      return true;
    }).toList();

    final validatedCount = allItems.where((it) => it.isValidated).length;
    final pendingCount = allItems.where((it) => it.isPendingValidation || it.isPendingPayment).length;
    final airedCount = allItems.where((it) => it.isBroadcasted).length;
    final rejectedCount = allItems.where((it) => it.isRejected).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('My Announcements'),
              backgroundColor: cardBg,
              foregroundColor: textColor,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () => _requestAnother(),
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                    label: const Text(
                      'New Request',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            )
          : null,
      floatingActionButton: allItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _requestAnother(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Request Another'),
            )
          : null,
      body: Column(
        children: [
          if (!widget.showAppBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Track status & requests',
                    style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _requestAnother(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          // Filter Chips Row
          if (allItems.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _filterChip(0, 'All', allItems.length),
                  const SizedBox(width: 8),
                  _filterChip(1, 'Scheduled / Airing', validatedCount, color: AppColors.success),
                  const SizedBox(width: 8),
                  _filterChip(2, 'Awaiting Validation', pendingCount, color: AppColors.warning),
                  const SizedBox(width: 8),
                  _filterChip(3, 'Aired', airedCount, color: Colors.blue),
                  const SizedBox(width: 8),
                  _filterChip(4, 'Rejected', rejectedCount, color: AppColors.error),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: allItems.isEmpty
                ? _buildEmptyState()
                : filtered.isEmpty
                    ? _buildNoFilteredState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            vm.watchMyAnnouncements(uid);
                          }
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _announcementCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int index, String label, int count, {Color? color}) {
    final isSelected = _selectedFilter == index;
    final activeColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = index),
      selectedColor: activeColor.withOpacity(0.18),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? activeColor : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.border,
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No announcements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit a community announcement to air on your favorite radio station.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _requestAnother(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Request Your First Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilteredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 40, color: AppColors.textMuted.withOpacity(0.6)),
          const SizedBox(height: 12),
          const Text(
            'No announcements in this category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _selectedFilter = 0),
            child: const Text('Show all announcements'),
          ),
        ],
      ),
    );
  }

  Widget _announcementCard(AnnouncementRequest item) {
    final statusInfo = _statusBadge(item.status);
    final isVal = item.isValidated;
    final isAired = item.isBroadcasted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVal
              ? AppColors.success.withOpacity(0.4)
              : (isAired ? Colors.blue.withOpacity(0.3) : AppColors.border),
          width: isVal ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Radio name + Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radio, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.station,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy • HH:mm').format(item.date),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusInfo.color.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.icon, size: 12, color: statusInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Message Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Priority chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.priority == AnnouncementPriority.priority
                                ? Colors.purple.withOpacity(0.1)
                                : (item.priority == AnnouncementPriority.high
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.priority.label} priority',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: item.priority == AnnouncementPriority.priority
                                  ? Colors.purple
                                  : (item.priority == AnnouncementPriority.high
                                      ? Colors.orange.shade800
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.diffusionsPerDay}x/day · ${item.days}d',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Final / Original text
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ==================== AIRING SCHEDULE SECTION (FOR VALIDATED / SCHEDULED) ====================
          if (item.isValidated) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Scheduled Airing Schedule',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if (item.assignedSlots.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.assignedSlots.length} slot${item.assignedSlots.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Primary Next Airing Display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.airingTimeSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Slot Breakdown if multiple slots
                  if (item.assignedSlots.length > 1) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.assignedSlots.take(4).map((slot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                slot.isAired ? Icons.check_circle : Icons.access_time,
                                size: 12,
                                color: slot.isAired ? Colors.blue : Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${slot.dateLabel} ${slot.timeLabel}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              if (slot.isWithinShow && slot.showName != null) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '• ${slot.showName}',
                                  style: TextStyle(fontSize: 10, color: Colors.green.shade800),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (item.assignedSlots.length > 4) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${item.assignedSlots.length - 4} more slot(s)',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],

          // ==================== BROADCAST COMPLETE SECTION ====================
          if (isAired) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Broadcast Completed 🎉',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                        ),
                        if (item.airedAt != null)
                          Text(
                            'Aired on ${DateFormat('EEE, d MMM yyyy • HH:mm').format(item.airedAt!)}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF1565C0)),
                          ),
                        if (item.airedBy != null && item.airedBy!.isNotEmpty)
                          Text(
                            'Broadcasted by ${item.airedBy}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ==================== PENDING ESCROW VALIDATION SECTION ====================
          if (item.isPendingValidation) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment held in escrow. Radio station admin is reviewing text & scheduling broadcast slots.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ==================== REJECTED SECTION ====================
          if (item.isRejected) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cancel, color: AppColors.error, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Request Rejected',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.rejectionReason != null && item.rejectionReason!.isNotEmpty
                        ? 'Reason: ${item.rejectionReason}'
                        : 'Station administration declined this announcement.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Escrow funds have been refunded to your payment method.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Footer: Price + Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Price', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDetailsSheet(item),
                      icon: const Icon(Icons.info_outline, size: 15),
                      label: const Text('Details', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _requestAnother(item),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Request Another', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(AnnouncementRequest item) {
    final statusInfo = _statusBadge(item.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ListView(
                controller: scrollCtrl,
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

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.station,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Category: ${item.category} • ${item.priority.label} Priority',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusInfo.color.withOpacity(0.4)),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusInfo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Full Announcement Text
                  const Text('Broadcast Text', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.message,
                          style: const TextStyle(fontSize: 13.5, height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text: item.message,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message copied to clipboard!')),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scheduled Airing Time / Slot Table (if validated)
                  if (item.assignedSlots.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Airing Schedule Timeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: item.assignedSlots.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final slot = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: entry.key < item.assignedSlots.length - 1
                                    ? const BorderSide(color: AppColors.divider)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: slot.isAired ? Colors.blue : Colors.green.shade100,
                                  child: Text(
                                    '$idx',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: slot.isAired ? Colors.white : Colors.green.shade900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${slot.dateLabel} at ${slot.timeLabel}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Text(
                                        slot.isWithinShow
                                            ? '🎙️ Live host read during "${slot.showName ?? "Show"}"'
                                            : '📻 Intermediary break slot',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: slot.isAired ? Colors.blue.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    slot.isAired ? 'Aired' : 'Scheduled',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: slot.isAired ? Colors.blue.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Tariff & Payment Summary
                  const SizedBox(height: 20),
                  const Text('Payment & Tariff Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Station', item.station),
                        _detailRow('Date', DateFormat('d MMM yyyy, HH:mm').format(item.date)),
                        _detailRow('Status', item.statusLabel),
                        const Divider(height: 16, color: AppColors.divider),
                        _detailRow('Words & Duration', '${item.wordCount} words (${item.units * 15}s)'),
                        _detailRow('Diffusions', '${item.diffusionsPerDay}x/day for ${item.days} days'),
                        _detailRow('Base Tariff', '${item.baseAmount.toStringAsFixed(0)} XAF'),
                        _detailRow('Transfer Fee (4%)', '${item.transferFee.toStringAsFixed(0)} XAF'),
                        const Divider(height: 16, color: AppColors.divider),
                        _detailRow('Total Final Price', item.formattedPrice, isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Action: Request Another Announcement
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _requestAnother(item);
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Request Another Announcement',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: isBold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, color: isBold ? AppColors.primary : AppColors.textPrimary, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  _StatusInfo _statusBadge(String status) {
    switch (status.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'pendingvalidation':
      case 'inescrow':
      case 'held':
      case 'pending':
        return const _StatusInfo(label: 'Awaiting validation', color: AppColors.warning, icon: Icons.hourglass_top);
      case 'validated':
      case 'scheduled':
      case 'approved':
      case 'printed':
        return const _StatusInfo(label: 'Scheduled / Airing', color: AppColors.success, icon: Icons.event_available);
      case 'broadcasted':
      case 'aired':
        return const _StatusInfo(label: 'Aired', color: Colors.blue, icon: Icons.check_circle);
      case 'rejected':
      case 'declined':
        return const _StatusInfo(label: 'Rejected', color: AppColors.error, icon: Icons.cancel);
      case 'refunded':
        return const _StatusInfo(label: 'Refunded', color: AppColors.info, icon: Icons.undo);
      case 'pendingpayment':
        return const _StatusInfo(label: 'Pending payment', color: AppColors.textSecondary, icon: Icons.payment);
      default:
        return _StatusInfo(
          label: status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Awaiting validation',
          color: AppColors.warning,
          icon: Icons.hourglass_top,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusInfo({required this.label, required this.color, required this.icon});
}
