part of 'live_player_cubit.dart';

sealed class LivePlayerState extends Equatable {
  const LivePlayerState();
}

class LivePlayerInitial extends LivePlayerState {
  const LivePlayerInitial();

  @override
  List<Object?> get props => const [];
}

class LivePlayerLoading extends LivePlayerState {
  const LivePlayerLoading();

  @override
  List<Object?> get props => const [];
}

class LivePlayerReady extends LivePlayerState {
  final LiveStream liveStream;
  final List<Announcement> announcements;
  final bool isLoading;

  const LivePlayerReady({
    required this.liveStream,
    required this.announcements,
    this.isLoading = false,
  });

  LivePlayerReady copyWith({
    LiveStream? liveStream,
    List<Announcement>? announcements,
    bool? isLoading,
  }) {
    return LivePlayerReady(
      liveStream: liveStream ?? this.liveStream,
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [liveStream, announcements, isLoading];
}

class LivePlayerPlaying extends LivePlayerState {
  final LiveStream liveStream;
  final List<Announcement> announcements;
  final Episode? currentEpisode;

  const LivePlayerPlaying({
    required this.liveStream,
    required this.announcements,
    this.currentEpisode,
  });

  LivePlayerPlaying copyWith({
    LiveStream? liveStream,
    List<Announcement>? announcements,
    Episode? currentEpisode,
  }) {
    return LivePlayerPlaying(
      liveStream: liveStream ?? this.liveStream,
      announcements: announcements ?? this.announcements,
      currentEpisode: currentEpisode ?? this.currentEpisode,
    );
  }

  @override
  List<Object?> get props => [liveStream, announcements, currentEpisode];
}

class LivePlayerPaused extends LivePlayerState {
  final LiveStream liveStream;
  final List<Announcement> announcements;
  final Episode? currentEpisode;

  const LivePlayerPaused({
    required this.liveStream,
    required this.announcements,
    this.currentEpisode,
  });

  LivePlayerPaused copyWith({
    LiveStream? liveStream,
    List<Announcement>? announcements,
    Episode? currentEpisode,
  }) {
    return LivePlayerPaused(
      liveStream: liveStream ?? this.liveStream,
      announcements: announcements ?? this.announcements,
      currentEpisode: currentEpisode ?? this.currentEpisode,
    );
  }

  @override
  List<Object?> get props => [liveStream, announcements, currentEpisode];
}

class LivePlayerError extends LivePlayerState {
  final String message;

  const LivePlayerError(this.message);

  @override
  List<Object?> get props => [message];
}
