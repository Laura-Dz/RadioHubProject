import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/show_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../view_models/user_interaction_view_model.dart';
import 'live_badge.dart';
import 'countdown_timer.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/reminder_button.dart';

class ShowCard extends StatelessWidget {
  final ShowModel show;
  final bool isLive;
  final bool isCompact;
  final bool isChannel;
  final bool isVertical;
  final bool isGrid;
  final bool isNewEpisode;
  final VoidCallback onTap;

  const ShowCard({
    Key? key,
    required this.show,
    this.isLive = false,
    this.isCompact = false,
    this.isChannel = false,
    this.isVertical = false,
    this.isGrid = false,
    this.isNewEpisode = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isGrid) return _buildGridCard(context, isDark);
    if (isVertical) return _buildVerticalCard(context, isDark);
    if (isCompact) return _buildCompactCard(context, isDark);
    return _buildHorizontalCard(context, isDark);
  }

  Widget _buildHorizontalCard(BuildContext context, bool isDark) {
    final vm = context.read<UserInteractionViewModel>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.primary).withOpacity(isDark ? 0.3 : 0.08), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(
            color: (isLive || show.isLive)
                ? AppColors.error.withOpacity(0.3)
                : (show.isRediffusion
                    ? const Color(0xFFD4A017).withOpacity(0.3)
                    : Colors.transparent),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.3)])),
                    child: show.imageUrl != null
                        ? Image.network(show.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                        : _buildPlaceholder(),
                  ),
                ),
                if (isLive || show.isLive || show.isRediffusion)
                  Positioned(top: 8, left: 8, child: LiveBadge(tag: show.displayTag)),
                if (show.timeRemaining != null)
                  Positioned(top: 8, right: 8, child: CountdownTimer(timeRemaining: show.timeRemaining!)),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.headphones, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(_formatListenerCount(show.listenerCount), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(show.host, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FollowButton(
                        isFollowed: vm.isShowFollowed(show.id),
                        onToggle: () => vm.toggleFollowShow(show.id),
                        followerCount: show.followerCount ?? 0,
                      ),
                      const SizedBox(width: 8),
                      if (show.startTime != null && show.status == ShowStatus.upcoming)
                        ReminderButton(
                          showId: show.id,
                          programName: show.title,
                          showStartTime: show.startTime!,
                          hasReminder: vm.hasReminder(show.id),
                          onSetReminder: (startTime, minutes) => vm.setReminder(
                            showId: show.id,
                            programName: show.title,
                            showStartTime: startTime,
                            reminderMinutesBefore: minutes,
                          ),
                          onRemoveReminder: () => vm.removeReminder(show.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: (isDark ? Colors.black : Colors.grey).withOpacity(isDark ? 0.3 : 0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)])),
                child: show.imageUrl != null ? Image.network(show.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()) : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(show.host, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                  if (show.timeRemaining != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 10, color: AppColors.secondary),
                        const SizedBox(width: 2),
                        Text(show.timeRemaining!, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context, bool isDark) {
    final vm = context.read<UserInteractionViewModel>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: (isDark ? Colors.black : Colors.grey).withOpacity(isDark ? 0.3 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)])),
                child: show.imageUrl != null ? Image.network(show.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()) : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(show.host, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  Row(
                    children: [
                      if (show.isLive || show.isRediffusion)
                        LiveBadge(tag: show.displayTag, isSmall: true),
                      if (show.timeRemaining != null) CountdownTimer(timeRemaining: show.timeRemaining!, isSmall: true),
                      if (show.episodeCount != null)
                        Text('${show.episodeCount} eps', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                vm.isShowFollowed(show.id) ? Icons.favorite : Icons.favorite_border,
                color: vm.isShowFollowed(show.id) ? AppColors.error : null,
                size: 20,
              ),
              onPressed: () => vm.toggleFollowShow(show.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: (isDark ? Colors.black : Colors.grey).withOpacity(isDark ? 0.3 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: show.isTrending ? AppColors.secondary.withOpacity(0.3) : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)])),
                    child: show.imageUrl != null ? Image.network(show.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()) : _buildPlaceholder(),
                  ),
                ),
                if (show.isTrending)
                  const Positioned(top: 8, left: 8, child: LiveBadge(label: '🔥', isTrending: true)),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.headphones, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(_formatListenerCount(show.listenerCount), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(show.host, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                  if (show.timeRemaining != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 10, color: AppColors.secondary),
                        const SizedBox(width: 2),
                        Text(show.timeRemaining!, style: const TextStyle(fontSize: 9, color: AppColors.secondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  if (show.rating > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star, size: 10, color: AppColors.secondary),
                        const SizedBox(width: 2),
                        Text(show.rating.toStringAsFixed(1), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(color: Colors.grey.shade200, child: Center(child: Icon(Icons.radio, color: Colors.grey.shade400, size: 32)));
  }

  String _formatListenerCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
