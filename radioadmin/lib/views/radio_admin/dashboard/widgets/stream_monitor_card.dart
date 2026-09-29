import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';

class StreamMonitorCard extends StatefulWidget {
  final String? broadcastLink;
  final bool isLive;
  final int listenerCount;
  final String radioName;

  const StreamMonitorCard({
    Key? key,
    required this.broadcastLink,
    required this.isLive,
    this.listenerCount = 0,
    required this.radioName,
  }) : super(key: key);

  @override
  State<StreamMonitorCard> createState() => _StreamMonitorCardState();
}

class _StreamMonitorCardState extends State<StreamMonitorCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _volume = 1.0;
  bool _isMuted = false;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    try {
      _player.onPlayerStateChanged.listen(
        (state) {
          if (!mounted) return;
          setState(() {
            _isPlaying = state == PlayerState.playing;
            if (state == PlayerState.playing) {
              _isBuffering = false;
              _errorMessage = null;
              _startElapsedTimer();
            } else if (state == PlayerState.paused || state == PlayerState.stopped || state == PlayerState.completed) {
              _isBuffering = false;
              _stopElapsedTimer();
            }
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isBuffering = false;
            _isPlaying = false;
            _errorMessage = 'Stream error: ${e.toString()}';
          });
        },
      );
    } catch (e) {
      debugPrint('StreamMonitor AudioPlayer init error: $e');
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isPlaying) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
  }

  @override
  void dispose() {
    _stopElapsedTimer();
    try {
      _player.stop();
      _player.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final link = widget.broadcastLink?.trim();
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No broadcast link configured. Contact Platform SysAdmin.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isPlaying) {
      await _player.pause();
    } else {
      setState(() {
        _isBuffering = true;
        _errorMessage = null;
      });
      try {
        final validUrl = StorageService.ensureValidUrl(link);
        await _player.setVolume(_isMuted ? 0.0 : _volume);
        await _player.play(UrlSource(validUrl));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isBuffering = false;
          _isPlaying = false;
          _errorMessage = 'Unable to reach audio stream. Check mountpoint.';
        });
      }
    }
  }

  Future<void> _setVolume(double vol) async {
    setState(() {
      _volume = vol;
      _isMuted = vol == 0.0;
    });
    try {
      await _player.setVolume(vol);
    } catch (_) {}
  }

  Future<void> _toggleMute() async {
    final newMute = !_isMuted;
    setState(() {
      _isMuted = newMute;
    });
    try {
      await _player.setVolume(newMute ? 0.0 : _volume);
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasStream = widget.broadcastLink != null && widget.broadcastLink!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isLive ? AppColors.success.withOpacity(0.35) : AppColors.border,
          width: widget.isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Live Beacon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radio_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Stream Monitor',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time broadcast feed for ${widget.radioName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _buildStatusBeacon(hasStream),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Player & Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Play / Pause Button
                GestureDetector(
                  onTap: hasStream ? _togglePlay : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasStream ? AppColors.primary : AppColors.border,
                      boxShadow: hasStream
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isBuffering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Playback Status & Elapsed Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isPlaying
                                ? 'MONITORING LIVE FEED'
                                : _isBuffering
                                    ? 'BUFFERING STREAM...'
                                    : 'MONITOR STANDBY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: _isPlaying
                                  ? AppColors.success
                                  : _isBuffering
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                            ),
                          ),
                          if (_isPlaying) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isPlaying ? 'Listening time: ${_formatDuration(_elapsed)}' : 'Click play to inspect station sound output',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Volume Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMuted || _volume == 0
                            ? Icons.volume_off_rounded
                            : _volume < 0.5
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: _isMuted ? 'Unmute' : 'Mute',
                      onPressed: hasStream ? _toggleMute : null,
                    ),
                    SizedBox(
                      width: 90,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.primary,
                        ),
                        child: Slider(
                          value: _isMuted ? 0.0 : _volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: hasStream ? _setVolume : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Message Banner (if any)
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Infrastructure Boundary Notice (Mountpoint strictly hidden from Radio Staff)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  hasStream ? Icons.verified_user_outlined : Icons.info_outline_rounded,
                  size: 16,
                  color: hasStream ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasStream
                        ? 'Broadcast feed active · Streaming infrastructure and mountpoints are strictly managed by Platform SysAdmin.'
                        : 'Broadcast stream unassigned · Mountpoint configuration is managed exclusively by Platform SysAdmin under biometric face verification.',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBeacon(bool hasStream) {
    if (!hasStream) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: AppColors.warning, size: 8),
            SizedBox(width: 6),
            Text(
              'STREAM UNASSIGNED',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.warning),
            ),
          ],
        ),
      );
    }

    if (widget.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, color: AppColors.success, size: 8),
            const SizedBox(width: 6),
            const Text(
              'ON AIR · LIVE',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.success),
            ),
            if (widget.listenerCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '(${widget.listenerCount} listeners)',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: AppColors.info, size: 8),
          SizedBox(width: 6),
          Text(
            'STANDBY / SCHEDULED',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.info),
          ),
        ],
      ),
    );
  }
}
