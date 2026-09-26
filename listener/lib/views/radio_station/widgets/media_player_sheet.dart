import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/station_media_model.dart';
import '../../../core/services/s3_storage_helper.dart';
import '../../../core/widgets/safe_image.dart';

class MediaPlayerSheet extends StatefulWidget {
  final StationMediaModel media;
  final String radioName;

  const MediaPlayerSheet({
    Key? key,
    required this.media,
    required this.radioName,
  }) : super(key: key);

  static void show(BuildContext context, {required StationMediaModel media, required String radioName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaPlayerSheet(media: media, radioName: radioName),
    );
  }

  @override
  State<MediaPlayerSheet> createState() => _MediaPlayerSheetState();
}

class _MediaPlayerSheetState extends State<MediaPlayerSheet> {
  AudioPlayer? _player;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final rawUrl = widget.media.url.trim();
    if (rawUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No audio stream URL available for this recording.';
        });
      }
      return;
    }

    try {
      final url = S3StorageHelper.ensureValidUrl(rawUrl);
      _player = AudioPlayer();
      await _player!.setUrl(url);
      if (mounted) {
        setState(() => _isLoading = false);
        _player!.play();
      }
    } catch (e) {
      debugPrint('MediaPlayerSheet audio error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Could not load media stream. It may be offline or restricted.';
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _cycleSpeed() {
    if (_player == null) return;
    const speeds = [1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final nextSpeed = speeds[nextIndex];
    _player!.setSpeed(nextSpeed);
    setState(() => _playbackSpeed = nextSpeed);
  }

  String _formatTime(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header row with type badge & close
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.media.isVideo
                      ? Colors.purple.withOpacity(0.12)
                      : (widget.media.isPodcast
                          ? Colors.orange.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.media.isVideo
                          ? Icons.videocam_rounded
                          : (widget.media.isPodcast
                              ? Icons.podcasts_rounded
                              : Icons.audiotrack_rounded),
                      size: 13,
                      color: widget.media.isVideo
                          ? Colors.purple
                          : (widget.media.isPodcast ? Colors.orange : AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.media.typeLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.media.isVideo
                            ? Colors.purple
                            : (widget.media.isPodcast ? Colors.orange : AppColors.primary),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thumbnail or artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 120,
              height: 120,
              child: SafeImage(
                imageUrl: widget.media.thumbnailUrl,
                fit: BoxFit.cover,
                fallback: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.7),
                        AppColors.secondary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.media.isVideo
                          ? Icons.play_circle_filled_rounded
                          : Icons.graphic_eq_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Station
          Text(
            widget.media.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.radioName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (widget.media.description != null && widget.media.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.media.description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 18),

          // Playback State / Controls
          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ] else if (_hasError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage ?? 'Unable to play media.',
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_player != null) ...[
            // Progress Scrubber Stream
            StreamBuilder<Duration>(
              stream: _player!.positionStream,
              builder: (context, posSnap) {
                final pos = posSnap.data ?? Duration.zero;
                final total = _player!.duration ?? Duration(seconds: widget.media.durationSeconds);
                final maxSeconds = total.inSeconds > 0 ? total.inSeconds.toDouble() : 1.0;
                final curSeconds = pos.inSeconds.toDouble().clamp(0.0, maxSeconds);

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withOpacity(0.15),
                        thumbColor: AppColors.primary,
                      ),
                      child: Slider(
                        value: curSeconds,
                        max: maxSeconds,
                        onChanged: (val) {
                          _player?.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(pos),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Text(
                            _formatTime(total),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Controls row: Speed, Rewind 15, Play/Pause, Fast-forward 15
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed pill
                TextButton(
                  onPressed: _cycleSpeed,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Rewind 10s
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 28),
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                  onPressed: () {
                    if (_player != null) {
                      final newPos = _player!.position - const Duration(seconds: 10);
                      _player!.seek(newPos < Duration.zero ? Duration.zero : newPos);
                    }
                  },
                ),

                // Play / Pause Stream
                StreamBuilder<PlayerState>(
                  stream: _player!.playerStateStream,
                  builder: (context, snap) {
                    final isPlaying = snap.data?.playing ?? false;
                    return IconButton(
                      iconSize: 48,
                      padding: EdgeInsets.zero,
                      color: AppColors.primary,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          _player?.pause();
                        } else {
                          _player?.play();
                        }
                      },
                    );
                  },
                ),

                // Forward 10s
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, size: 28),
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                  onPressed: () {
                    if (_player != null) {
                      final total = _player!.duration ?? Duration(seconds: widget.media.durationSeconds);
                      final newPos = _player!.position + const Duration(seconds: 10);
                      _player!.seek(newPos > total ? total : newPos);
                    }
                  },
                ),

                // Volume / mute placeholder
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, size: 22),
                  color: AppColors.textMuted,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
