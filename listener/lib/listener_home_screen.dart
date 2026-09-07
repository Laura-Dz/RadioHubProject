import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiohub_listener/audio_handler.dart';
import 'package:radiohub_listener/live_player_cubit.dart';
import 'package:radiohub_listener/listener_repository.dart';
import 'package:radiohub_listener/models/listener_models.dart';

class ListenerHomeScreen extends StatelessWidget {
  const ListenerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ListenerRepository>(
          create: (_) => ListenerRepository(),
        ),
        RepositoryProvider<AudioPlayerHandler>(
          create: (_) => AudioPlayerHandler()..init(),
        ),
      ],
      child: BlocProvider(
        create: (context) {
          final audioHandler = context.read<AudioPlayerHandler>();
          final repo = context.read<ListenerRepository>();
          return LivePlayerCubit(
            audioHandler: audioHandler,
            repository: repo,
          )..initialize();
        },
        child: const _ListenerHomeContent(),
      ),
    );
  }
}

class _ListenerHomeContent extends StatefulWidget {
  const _ListenerHomeContent();

  @override
  State<_ListenerHomeContent> createState() => _ListenerHomeContentState();
}

class _ListenerHomeContentState extends State<_ListenerHomeContent> {
  final ScrollController _scrollController = ScrollController();
  List<Show> _shows = [];
  List<Episode> _episodes = [];
  bool _isLoadingSchedule = false;
  bool _isLoadingEpisodes = false;
  String? _scheduleError;
  String? _episodesError;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _loadEpisodes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoadingSchedule = true;
      _scheduleError = null;
    });
    try {
      final repo = context.read<ListenerRepository>();
      final shows = await repo.getShowSchedule(filter: 'upcoming');
      if (mounted) {
        setState(() {
          _shows = shows;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scheduleError = e.toString();
          _isLoadingSchedule = false;
        });
      }
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoadingEpisodes = true;
      _episodesError = null;
    });
    try {
      final repo = context.read<ListenerRepository>();
      final episodes = await repo.getEpisodes();
      if (mounted) {
        setState(() {
          _episodes = episodes;
          _isLoadingEpisodes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _episodesError = e.toString();
          _isLoadingEpisodes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LivePlayerCubit, LivePlayerState>(
      listenWhen: (previous, current) =>
          previous is! LivePlayerPlaying && current is LivePlayerPlaying,
      listener: (context, state) {
        if (state is LivePlayerPlaying) {
          _showFullPlayerModal(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RadioHub'),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: _EpisodeSearchDelegate(episodes: _episodes));
              },
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: _AnnouncementTicker(),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await context.read<LivePlayerCubit>().initialize();
            await _loadSchedule();
            await _loadEpisodes();
          },
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const _LiveStreamHeroCard(),
              const SizedBox(height: 24),
              _ShowScheduleSection(
                shows: _shows,
                isLoading: _isLoadingSchedule,
                error: _scheduleError,
                onRetry: _loadSchedule,
              ),
              const SizedBox(height: 24),
              _RecentEpisodesSection(
                episodes: _episodes,
                isLoading: _isLoadingEpisodes,
                error: _episodesError,
                onRetry: _loadEpisodes,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomSheet: const _StickyPlayerBar(),
      ),
    );
  }

  void _showFullPlayerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FullPlayerModal(),
    );
  }
}

class _AnnouncementTicker extends StatelessWidget {
  const _AnnouncementTicker();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LivePlayerCubit, LivePlayerState, List<Announcement>>(
      selector: (state) {
        if (state is LivePlayerReady || state is LivePlayerPlaying || state is LivePlayerPaused) {
          return state.announcements;
        }
        return const [];
      },
      builder: (context, announcements) {
        final active = announcements.where((a) => a.isCurrentlyActive).toList();
        if (active.isEmpty) {
          return Container(
            height: 40,
            color: Colors.transparent,
          );
        }

        return Container(
          height: 40,
          color: Colors.redAccent,
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final announcement = active[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 24),
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${announcement.title}: ${announcement.message}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveStreamHeroCard extends StatelessWidget {
  const _LiveStreamHeroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocSelector<LivePlayerCubit, LivePlayerState, LiveStream?>(
        selector: (state) {
          if (state is LivePlayerReady || state is LivePlayerPlaying || state is LivePlayerPaused) {
            return state.liveStream;
          }
          return null;
        },
        builder: (context, liveStream) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: liveStream?.isLive == true ? Colors.redAccent : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            liveStream?.isLive == true ? 'LIVE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (liveStream?.isLive == true)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const _PulseIndicator(),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      liveStream?.currentTitle ?? 'Live Radio Stream',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (liveStream?.currentHost != null)
                      Text(
                        liveStream!.currentHost!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: liveStream?.isLive == true
                          ? () {
                              final cubit = context.read<LivePlayerCubit>();
                              cubit.toggleLiveStream(liveStream!);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('LISTEN LIVE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _ShowScheduleSection extends StatelessWidget {
  final List<Show> shows;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _ShowScheduleSection({
    required this.shows,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Show Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          SizedBox(
            height: 140,
            child: Center(
              child: Column(
                children: [
                  Text('Failed to load shows', style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (shows.isEmpty)
          const SizedBox(
            height: 140,
            child: Center(child: Text('No upcoming shows')),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shows.length,
              itemBuilder: (context, index) {
                final show = shows[index];
                return _ShowCard(show: show);
              },
            ),
          ),
      ],
    );
  }
}

class _ShowCard extends StatelessWidget {
  final Show show;

  const _ShowCard({required this.show});

  @override
  Widget build(BuildContext context) {
    final scheduleTime = show.scheduleTime;
    final timeStr = '${scheduleTime.hour.toString().padLeft(2, '0')}:${scheduleTime.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.deepPurple.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.deepPurple.shade300,
              ),
              width: double.infinity,
              child: show.coverImage != null && show.coverImage!.isNotEmpty
                  ? Image.network(show.coverImage!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.radio, size: 48, color: Colors.white);
                    })
                  : const Icon(Icons.radio, size: 48, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEpisodesSection extends StatelessWidget {
  final List<Episode> episodes;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _RecentEpisodesSection({
    required this.episodes,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent Episodes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text('Failed to load episodes', style: TextStyle(color: Colors.grey.shade600)),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          )
        else if (episodes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No episodes available'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _EpisodeTile(episode: episode);
            },
          ),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;

  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.mic, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(episode.title),
        subtitle: Text('${episode.showTitle} • ${_formatDuration(Duration(seconds: episode.duration))}'),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_filled, size: 32),
          onPressed: () {
            context.read<LivePlayerCubit>().playEpisode(episode);
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StickyPlayerBar extends StatelessWidget {
  const _StickyPlayerBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LivePlayerCubit, LivePlayerState>(
      buildWhen: (previous, current) {
        return previous is! (LivePlayerPlaying || LivePlayerPaused) ||
            current is (LivePlayerPlaying || LivePlayerPaused);
      },
      builder: (context, state) {
        final isPlaying = state is LivePlayerPlaying;
        final isPaused = state is LivePlayerPaused;

        if (!isPlaying && !isPaused) {
          return const SizedBox.shrink();
        }

        final title = isPlaying
            ? (state as LivePlayerPlaying).currentEpisode?.title ?? state.liveStream.currentTitle ?? 'Live Radio'
            : (state as LivePlayerPaused).currentEpisode?.title ?? state.liveStream.currentTitle ?? 'Live Radio';

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _FullPlayerModal(),
            );
          },
          child: Container(
            height: 64,
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPlaying ? 'Playing' : 'Paused',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    final cubit = context.read<LivePlayerCubit>();
                    if (isPlaying) {
                      cubit.pause();
                    } else {
                      cubit.resume();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    context.read<LivePlayerCubit>().stop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FullPlayerModal extends StatelessWidget {
  const _FullPlayerModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: BlocBuilder<LivePlayerCubit, LivePlayerState>(
            builder: (context, state) {
              String title = 'Unknown';
              String artist = 'Unknown';
              bool isLive = false;

              if (state is LivePlayerPlaying || state is LivePlayerPaused) {
                title = state.currentEpisode?.title ?? state.liveStream.currentTitle ?? 'Unknown';
                artist = state.currentEpisode?.showTitle ?? state.liveStream.currentHost ?? 'Unknown';
                isLive = state.liveStream.isLive;
              } else if (state is LivePlayerReady) {
                title = state.liveStream.currentTitle ?? 'Live Radio';
                artist = state.liveStream.currentHost ?? '';
                isLive = state.liveStream.isLive;
              }

              final isPlaying = state is LivePlayerPlaying;
              final duration = isLive ? null : (state is LivePlayerPlaying || state is LivePlayerPaused)
                  ? (state is LivePlayerPlaying ? state.currentEpisode?.duration : (state as LivePlayerPaused).currentEpisode?.duration)
                  : null;

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.deepPurple.shade900,
                              ),
                              child: Icon(
                                isLive ? Icons.radio : Icons.album,
                                size: 100,
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            if (isLive)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 32),
                            if (!isLive && duration != null)
                              StreamBuilder<Duration>(
                                stream: AudioService.playbackStateStream.map((ps) => ps.updatePosition).distinct(),
                                builder: (context, snapshot) {
                                  final position = snapshot.data ?? Duration.zero;
                                  return Column(
                                    children: [
                                      Slider(
                                        value: position.inSeconds.toDouble(),
                                        max: duration.toDouble(),
                                        onChanged: (value) {
                                          context.read<LivePlayerCubit>().seek(Duration(seconds: value.toInt()));
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 32),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.black,
                                      size: 48,
                                    ),
                                    onPressed: () {
                                      final cubit = context.read<LivePlayerCubit>();
                                      if (isPlaying) {
                                        cubit.pause();
                                      } else {
                                        cubit.resume();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 32),
                                IconButton(
                                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _EpisodeSearchDelegate extends SearchDelegate<String> {
  final List<Episode> episodes;

  const _EpisodeSearchDelegate({required this.episodes});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = episodes.where((episode) {
      final q = query.toLowerCase();
      return episode.title.toLowerCase().contains(q) ||
          episode.showTitle.toLowerCase().contains(q);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final episode = results[index];
        return ListTile(
          title: Text(episode.title),
          subtitle: Text(episode.showTitle),
          onTap: () {
            context.read<LivePlayerCubit>().playEpisode(episode);
            close(context, '');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Start typing to search episodes'));
    }
    return buildResults(context);
  }
}
