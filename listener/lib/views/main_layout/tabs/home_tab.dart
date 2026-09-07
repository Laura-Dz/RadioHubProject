import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../../view_models/home_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/wavy_header.dart';
import '../widgets/show_card.dart';
import '../widgets/section_header.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollingDown = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final direction = _scrollController.position.userScrollDirection;
      final isDown = direction == ScrollDirection.forward;
      if (_isScrollingDown != isDown) {
        setState(() {
          _isScrollingDown = isDown;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeViewModel = context.watch<HomeViewModel>();

    return RefreshIndicator(
      onRefresh: () async => await homeViewModel.refreshData(),
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: WavyHeader(welcomeMessage: homeViewModel.welcomeMessage, userImage: homeViewModel.currentUser?.displayName)),
          if (homeViewModel.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            if (homeViewModel.liveShows.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: '🔴 Live Now', subtitle: '${homeViewModel.liveShows.length} shows live', onSeeAll: () {}),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: homeViewModel.liveShows.length,
                        itemBuilder: (context, index) {
                          final show = homeViewModel.liveShows[index];
                          return ShowCard(show: show, isLive: true, onTap: () {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          if (!homeViewModel.isLoading && homeViewModel.followedShows.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: '📌 Your Shows', subtitle: 'Coming up next', onSeeAll: () {}),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: homeViewModel.followedShows.length,
                      itemBuilder: (context, index) {
                        final show = homeViewModel.followedShows[index];
                        return ShowCard(show: show, isCompact: true, onTap: () {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          if (!homeViewModel.isLoading && homeViewModel.channels.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: '📻 Channels', subtitle: 'Explore all channels', onSeeAll: () {}),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: homeViewModel.channels.length,
                      itemBuilder: (context, index) {
                        final show = homeViewModel.channels[index];
                        return ShowCard(show: show, isChannel: true, onTap: () {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          if (!homeViewModel.isLoading && homeViewModel.recommendedShows.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: '💡 Recommended For You', subtitle: 'Based on your listening', onSeeAll: () {}),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: homeViewModel.recommendedShows.map((show) => ShowCard(show: show, isVertical: true, onTap: () {})).toList()),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          if (!homeViewModel.isLoading && homeViewModel.trendingShows.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: '🔥 Trending', subtitle: 'Popular right now', onSeeAll: () {}),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                    itemCount: min(4, homeViewModel.trendingShows.length),
                    itemBuilder: (context, index) {
                      final show = homeViewModel.trendingShows[index];
                      return ShowCard(show: show, isGrid: true, onTap: () {});
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          if (!homeViewModel.isLoading && homeViewModel.newEpisodes.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: '🆕 New Episodes', subtitle: 'From your favorite shows', onSeeAll: () {}),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: homeViewModel.newEpisodes.length,
                      itemBuilder: (context, index) {
                        final show = homeViewModel.newEpisodes[index];
                        return ShowCard(show: show, isNewEpisode: true, onTap: () {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          if (!homeViewModel.isLoading &&
              homeViewModel.liveShows.isEmpty &&
              homeViewModel.followedShows.isEmpty &&
              homeViewModel.channels.isEmpty &&
              homeViewModel.recommendedShows.isEmpty &&
              homeViewModel.trendingShows.isEmpty &&
              homeViewModel.newEpisodes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radio, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No shows available', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Check back later for new content', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => homeViewModel.refreshData(), child: const Text('Refresh')),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
