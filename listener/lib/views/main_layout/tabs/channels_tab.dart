import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/channels_view_model.dart';
import '../../core/theme/app_colors.dart';

class ChannelsTab extends StatefulWidget {
  const ChannelsTab({Key? key}) : super(key: key);

  @override
  State<ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<ChannelsTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelsViewModel>().loadInitialData();
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
    final viewModel = context.watch<ChannelsViewModel>();

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            title: TextField(
              decoration: InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => viewModel.setSearchQuery(value),
            ),
          ),
          if (viewModel.isLoading && viewModel.channels.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: viewModel.categories.length,
                  itemBuilder: (context, index) {
                    final category = viewModel.categories[index];
                    final isSelected = viewModel.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            viewModel.setCategory(category);
                          }
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (viewModel.featuredChannels.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('⭐ Featured Channels', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: viewModel.featuredChannels.length,
                      itemBuilder: (context, index) {
                        final channel = viewModel.featuredChannels[index];
                        return _buildChannelCard(context, channel, viewModel);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          if (viewModel.trendingChannels.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('🔥 Trending Now', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: viewModel.trendingChannels.length,
                      itemBuilder: (context, index) {
                        final channel = viewModel.trendingChannels[index];
                        return _buildChannelCard(context, channel, viewModel, isCompact: true);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('All Channels', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          if (viewModel.channels.isEmpty && !viewModel.isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radio_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No channels found', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Try adjusting your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final channel = viewModel.channels[index];
                  return _buildChannelTile(context, channel, viewModel);
                },
                childCount: viewModel.channels.length,
              ),
            ),
          if (viewModel.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator()
                      : TextButton.icon(
                          onPressed: () => viewModel.loadChannels(),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Load More'),
                        ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildChannelCard(BuildContext context, dynamic channel, ChannelsViewModel viewModel, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: isCompact ? 140 : 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(channel.imageUrl ?? 'https://via.placeholder.com/300'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: channel.isLive == true
                    ? const Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.category ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.headphones, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${channel.listenerCount ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          channel.isFollowed == true ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: channel.isFollowed == true ? Colors.red : Colors.grey.shade600,
                        ),
                        onPressed: () => viewModel.toggleFollow(channel.id, channel.isFollowed != true),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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

  Widget _buildChannelTile(BuildContext context, dynamic channel, ChannelsViewModel viewModel) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          channel.imageUrl ?? 'https://via.placeholder.com/300',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 56,
            height: 56,
            color: AppColors.surface,
            child: const Icon(Icons.radio, color: AppColors.primary),
          ),
        ),
      ),
      title: Text(
        channel.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channel.category ?? ''),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.headphones, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${channel.listenerCount ?? 0} listeners', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (channel.isLive == true) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          channel.isFollowed == true ? Icons.favorite : Icons.favorite_border,
          color: channel.isFollowed == true ? Colors.red : Colors.grey,
        ),
        onPressed: () => viewModel.toggleFollow(channel.id, channel.isFollowed != true),
      ),
      onTap: () {},
    );
  }
}
