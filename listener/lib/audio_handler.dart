import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    await _player.setAudioSource(_playlist, initialIndex: 0, initialPosition: Duration.zero);

    _player.positionStream.listen((position) {
      playbackState.add(playbackState.valueOrNull?.copyWith(
        updatePosition: position,
      ) ?? PlaybackState(
        controls: _buildControls(),
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _convertProcessingState(_player.processingState, _player.playing),
        playing: _player.playing,
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex ?? 0,
      ));
    });

    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      if (_playlist.children.isNotEmpty && _player.currentIndex != null) {
        final currentSource = _playlist.children[_player.currentIndex!] as IndexedAudioSource?;
        final tag = currentSource?.tag as Map<String, dynamic>?;
        if (tag != null) {
          mediaItem.add(MediaItem(
            id: tag['id'] as String,
            album: tag['album'] as String? ?? '',
            title: tag['title'] as String? ?? 'Unknown',
            artist: tag['artist'] as String?,
            artUri: tag['artUri'] != null ? Uri.parse(tag['artUri'] as String) : null,
            duration: tag['duration'] != null
                ? Duration(seconds: tag['duration'] as int)
                : null,
          ));
        }
      }

      playbackState.add(PlaybackState(
        controls: _buildControls(),
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _convertProcessingState(processingState, playing),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex ?? 0,
      ));
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  List<MediaControl> _buildControls() {
    final playing = playbackState.valueOrNull?.playing ?? false;
    return [
      MediaControl(
        androidIcon: 'drawable/ic_skip_previous',
        label: 'Previous',
        action: MediaAction.skipToPrevious,
      ),
      MediaControl(
        androidIcon: playing ? 'drawable/ic_pause' : 'drawable/ic_play',
        label: playing ? 'Pause' : 'Play',
        action: playing ? MediaAction.pause : MediaAction.play,
      ),
      MediaControl(
        androidIcon: 'drawable/ic_skip_next',
        label: 'Next',
        action: MediaAction.skipToNext,
      ),
      MediaControl(
        androidIcon: 'drawable/ic_stop',
        label: 'Stop',
        action: MediaAction.stop,
      ),
    ];
  }

  AudioProcessingState _convertProcessingState(
    ProcessingState state,
    bool playing,
  ) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return playing ? AudioProcessingState.ready : AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> playLiveStream(String streamUrl, {String? title, String? artist}) async {
    final mediaItemValue = MediaItem(
      id: 'live://$streamUrl',
      album: 'Live Stream',
      title: title ?? 'Live Radio',
      artist: artist,
      duration: null,
    );

    mediaItem.add(mediaItemValue);

    await _playlist.clear();
    await _playlist.add(
      AudioSource.uri(
        Uri.parse(streamUrl),
        tag: {
          'id': mediaItemValue.id,
          'title': mediaItemValue.title,
          'album': mediaItemValue.album,
          'artist': mediaItemValue.artist,
          'duration': null,
        },
      ),
    );

    await _player.setAudioSource(_playlist, initialIndex: 0);
    await _player.play();
  }

  Future<void> playEpisode(String episodeId, String audioUrl,
      {String? title, String? artist, int? durationSeconds}) async {
    final mediaItemValue = MediaItem(
      id: 'episode://$episodeId',
      album: 'On Demand',
      title: title ?? 'Episode',
      artist: artist,
      duration: durationSeconds != null ? Duration(seconds: durationSeconds) : null,
    );

    mediaItem.add(mediaItemValue);

    await _playlist.clear();
    await _playlist.add(
      AudioSource.uri(
        Uri.parse(audioUrl),
        tag: {
          'id': mediaItemValue.id,
          'title': mediaItemValue.title,
          'album': mediaItemValue.album,
          'artist': mediaItemValue.artist,
          'duration': durationSeconds,
        },
      ),
    );

    await _player.setAudioSource(_playlist, initialIndex: 0);
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    await _playlist.clear();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> _playNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      await _player.play();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() async {
    await stop();
    await super.onNotificationDeleted();
  }
}
