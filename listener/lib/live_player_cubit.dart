import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:radiohub_listener/audio_handler.dart';
import 'package:radiohub_listener/listener_repository.dart';
import 'package:radiohub_listener/models/listener_models.dart';

part 'live_player_state.dart';

class LivePlayerCubit extends Cubit<LivePlayerState> {
  final AudioPlayerHandler _audioHandler;
  final ListenerRepository _repository;
  final FirebaseFirestore _firestore;
  StreamSubscription<List<Announcement>>? _announcementSubscription;

  LivePlayerCubit({
    required AudioPlayerHandler audioHandler,
    required ListenerRepository repository,
    FirebaseFirestore? firestore,
  })  : _audioHandler = audioHandler,
        _repository = repository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const LivePlayerState.initial());

  Future<void> initialize() async {
    emit(const LivePlayerState.loading());
    try {
      final liveStream = await _repository.getActiveLiveStream();
      final announcements = await _repository.getActiveAnnouncements();

      emit(LivePlayerState.ready(
        liveStream: liveStream,
        announcements: announcements,
      ));

      _listenToAnnouncements();
    } catch (e) {
      emit(LivePlayerState.error(e.toString()));
    }
  }

  Future<void> toggleLiveStream(LiveStream stream) async {
    try {
      emit(LivePlayerState.ready(
        liveStream: stream,
        announcements: state.announcements,
        isLoading: true,
      ));

      await _audioHandler.playLiveStream(
        stream.streamUrl,
        title: stream.currentTitle ?? 'Live Radio',
        artist: stream.currentHost,
      );

      emit(LivePlayerState.playing(
        liveStream: stream,
        announcements: state.announcements,
      ));
    } catch (e) {
      emit(LivePlayerState.error(e.toString()));
    }
  }

  Future<void> playEpisode(Episode episode) async {
    try {
      emit(LivePlayerState.ready(
        liveStream: state.liveStream,
        announcements: state.announcements,
        isLoading: true,
      ));

      await _audioHandler.playEpisode(
        episode.id.toString(),
        episode.audioFile,
        title: episode.title,
        artist: episode.showTitle,
        durationSeconds: episode.duration,
      );

      emit(LivePlayerState.playing(
        liveStream: state.liveStream,
        announcements: state.announcements,
        currentEpisode: episode,
      ));
    } catch (e) {
      emit(LivePlayerState.error(e.toString()));
    }
  }

  Future<void> pause() async {
    try {
      await _audioHandler.pause();
      final current = state;
      if (current is LivePlayerReady || current is LivePlayerPlaying) {
        emit(LivePlayerState.paused(
          liveStream: current.liveStream,
          announcements: current.announcements,
          currentEpisode: current is LivePlayerPlaying ? current.currentEpisode : null,
        ));
      }
    } catch (e) {
      emit(LivePlayerState.error(e.toString()));
    }
  }

  Future<void> resume() async {
    try {
      final current = state;
      if (current is LivePlayerPaused) {
        await _audioHandler.play();
        emit(LivePlayerState.playing(
          liveStream: current.liveStream,
          announcements: current.announcements,
          currentEpisode: current.currentEpisode,
        ));
      }
    } catch (e) {
      emit(LivePlayerState.error(e.toString()));
    }
  }

  Future<void> stop() async {
    await _audioHandler.stop();
    _announcementSubscription?.cancel();
    emit(const LivePlayerState.initial());
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioHandler.seek(position);
    } catch (e) {
      emit(LivePlayerState.error(e.toString()));
    }
  }

  void _listenToAnnouncements() {
    _announcementSubscription?.cancel();
    _announcementSubscription = _firestore
        .collection('announcements')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final start = (data['start_time'] as Timestamp).toDate();
            final end = (data['end_time'] as Timestamp).toDate();
            if (now.isBefore(start) || now.isAfter(end)) return null;

            return Announcement(
              id: int.tryParse(doc.id) ?? 0,
              title: data['title'] as String? ?? '',
              message: data['message'] as String? ?? '',
              type: data['type'] as String? ?? 'banner',
              isActive: data['is_active'] as bool? ?? true,
              startTime: start,
              endTime: end,
            );
          })
          .where((a) => a != null)
          .cast<Announcement>()
          .toList();
    }).listen(
      (announcements) {
        final current = state;
        if (current is LivePlayerReady || current is LivePlayerPlaying || current is LivePlayerPaused) {
          emit(current.copyWith(announcements: announcements));
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('Firestore announcements error: $error');
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _announcementSubscription?.cancel();
    return super.close();
  }
}
