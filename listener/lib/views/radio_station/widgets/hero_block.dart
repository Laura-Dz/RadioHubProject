import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/session_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_image.dart';
import 'session_detail_sheet.dart';

class HeroBlock extends StatelessWidget {
  const HeroBlock({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final r = vm.radio!;
    final live = vm.liveSession;
    final next = vm.nextSession;

    // Visual driver: the live session if on-air, else the next session, else banner or station logo
    final imageUrl = live?.imageUrl ?? next?.imageUrl ?? r.bannerUrl ?? r.logoUrl;
    final title = live?.programName ?? next?.programName ?? r.name;
    final subtitle = live != null
        ? _liveSubtitle(live)
        : (next != null ? _nextSubtitle(next) : r.description);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background with dynamic animated image updating
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? SafeImage(
                      key: ValueKey(imageUrl),
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      fallback: _heroGradientFallback(),
                    )
                  : _heroGradientFallback(),
            ),
            // Gradient overlay for contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 14,
              right: 14,
              top: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: badge + listeners
                  Row(
                    children: [
                      _StatusBadge(live: live, next: next),
                      const Spacer(),
                      if (live != null)
                        _pill(
                          icon: Icons.headphones,
                          text: '${live.listenerCount} listening',
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Bottom content
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Know more button
                  GestureDetector(
                    onTap: () {
                      final s = live ?? next;
                      if (s != null) _openDetail(context, s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Know more',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 10, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroGradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF3F3D56),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.radio,
          size: 64,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  String _liveSubtitle(SessionModel s) {
    final parts = <String>[];
    if (s.hostName != null && s.hostName!.isNotEmpty) parts.add(s.hostName!);
    if (s.guestName != null) parts.add('Guest: ${s.guestName}');
    if (s.thematic != null && s.thematic!.isNotEmpty) parts.add(s.thematic!);
    return parts.join(' · ');
  }

  String _nextSubtitle(SessionModel s) {
    final start = s.scheduledStart;
    final diff = start.difference(DateTime.now());
    final when = diff.inMinutes <= 60
        ? 'in ${diff.inMinutes} min'
        : diff.inHours < 24
            ? 'at ${DateFormat('HH:mm').format(start)}'
            : 'on ${DateFormat('EEE d MMM').format(start)}';
    final h = (s.hostName != null && s.hostName!.isNotEmpty) ? ' · ${s.hostName}' : '';
    return 'Upcoming $when$h';
  }

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, SessionModel s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionDetailSheet(session: s),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SessionModel? live;
  final SessionModel? next;
  const _StatusBadge({required this.live, required this.next});

  @override
  Widget build(BuildContext context) {
    if (live != null) {
      if (live!.isRediffusion) {
        return _badge(
          color: AppColors.gold,
          icon: Icons.replay,
          label: 'REDIFFUSION',
        );
      }
      if (live!.sessionType == SessionType.special) {
        return _badge(
          color: AppColors.error,
          icon: Icons.celebration_outlined,
          label: 'SPECIAL EVENT',
        );
      }
      if (live!.sessionType == SessionType.flash) {
        return _badge(
          color: AppColors.error,
          icon: Icons.bolt,
          label: 'FLASH',
        );
      }
      if (live!.sessionType == SessionType.intermediary) {
        return _badge(
          color: AppColors.gold,
          icon: Icons.queue_music,
          label: 'PLAYING',
        );
      }
      return _liveBadge();
    }
    if (next != null) {
      return _badge(
        color: AppColors.primary,
        icon: Icons.schedule,
        label: 'UPCOMING',
      );
    }
    return _badge(
      color: AppColors.textMuted,
      icon: Icons.radio,
      label: 'OFF AIR',
    );
  }

  Widget _badge(
      {required Color color, required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LivePulse(),
          SizedBox(width: 6),
          Text(
            'ON AIR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      );
}
