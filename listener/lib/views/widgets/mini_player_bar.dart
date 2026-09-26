import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/safe_image.dart';
import '../../view_models/radio_station_view_model.dart';
import '../radio_station/radio_station_page.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final radio = vm.radio;

    // Only display if a station has been selected/loaded and not dismissed
    if (radio == null || vm.isPlayerDismissed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final border = isDark ? const Color(0xFF2E2E3E) : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tap area: Station / Program Artwork & Title/Subtitle navigates to RadioStationPage
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RadioStationPage(radioId: radio.id),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Station / Program Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: SafeImage(
                          imageUrl: vm.currentProgramImage,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: AppColors.primary.withOpacity(0.12),
                            child: const Center(
                              child: Icon(
                                Icons.radio,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title and Subtitle / Live indicator
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (vm.isOnAir) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  vm.currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vm.currentSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Play / Pause Button
            IconButton(
              iconSize: 34,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              color: AppColors.primary,
              icon: Icon(
                vm.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                size: 34,
              ),
              onPressed: () => vm.togglePlay(),
            ),

            // Close / Stop button
            IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              color: isDark ? Colors.white54 : AppColors.textMuted,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close player',
              onPressed: () {
                vm.stopAndDismiss();
              },
            ),
          ],
        ),
      ),
    );
  }
}
