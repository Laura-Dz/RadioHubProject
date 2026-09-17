import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/channels_view_model.dart';
import '../../radio_station/radio_station_page.dart';
import 'channels/radio_card.dart';
import 'channels/search_history_dropdown.dart';

class ChannelsTab extends StatefulWidget {
  const ChannelsTab({Key? key}) : super(key: key);
  @override
  State<ChannelsTab> createState() => _State();
}

class _State extends State<ChannelsTab> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showHistory = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      context.read<ChannelsViewModel>().attach(uid);
    });
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (mounted) {
          context.read<ChannelsViewModel>().attach(user?.uid ?? '');
        }
      },
      onError: (e) => debugPrint('authStateChanges error: $e'),
    );
    _searchFocus.addListener(() {
      setState(() => _showHistory = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChannelsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ====== Header ======
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Channels',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Discover radios and streams',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 14),

                      // Search
                      TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        onChanged: (v) {
                          vm.setQuery(v);
                          setState(() {});
                        },
                        onSubmitted: (v) {
                          vm.submitSearch(_uid, v);
                          _searchFocus.unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search radios, categories, cities…',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    vm.setQuery('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter chips
                      if (!vm.isSearching) _filterRow(vm),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),

                // ====== Body ======
                Expanded(
                  child: vm.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _body(vm),
                ),
              ],
            ),

            // Search history overlay
            if (_showHistory && _searchCtrl.text.isEmpty)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: SearchHistoryDropdown(
                  entries: vm.searchHistory,
                  onSelect: (q) {
                    _searchCtrl.text = q;
                    vm.setQuery(q);
                    vm.submitSearch(_uid, q);
                    _searchFocus.unfocus();
                    setState(() {});
                  },
                  onRemove: (id) => vm.removeHistoryEntry(_uid, id),
                  onClearAll: () => vm.clearHistory(_uid),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- FILTER ROW ----------

  Widget _filterRow(ChannelsViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(vm, ChannelFilter.all, 'All', Icons.apps),
          const SizedBox(width: 8),
          _filterChip(vm, ChannelFilter.trending, 'Trending', Icons.trending_up),
          const SizedBox(width: 8),
          _filterChip(vm, ChannelFilter.forYou, 'For you', Icons.auto_awesome),
          const SizedBox(width: 8),
          _filterChip(vm, ChannelFilter.following, 'Following', Icons.favorite),
        ],
      ),
    );
  }

  Widget _filterChip(
      ChannelsViewModel vm, ChannelFilter f, String label, IconData icon) {
    final sel = vm.filter == f;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(icon,
                size: 14,
                color: sel ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: sel,
        onSelected: (_) => vm.setFilter(f),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
        labelStyle: TextStyle(
          color: sel ? Colors.white : AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------- BODY ----------

  Widget _body(ChannelsViewModel vm) {
    // Search results override the sectioned layout
    if (vm.isSearching) {
      return _searchResults(vm);
    }

    switch (vm.filter) {
      case ChannelFilter.all:
        return _allView(vm);
      case ChannelFilter.trending:
        return _grid(vm.visibleRadios, 'Trending now', vm,
            context: ChannelFilter.trending);
      case ChannelFilter.forYou:
        return _grid(vm.visibleRadios, 'For you', vm,
            context: ChannelFilter.forYou);
      case ChannelFilter.following:
        return _grid(vm.visibleRadios, 'Your radios', vm,
            context: ChannelFilter.following,
            emptyMessage: 'You are not following any radio yet');
    }
  }

  // -------- ALL VIEW — sections --------

  Widget _allView(ChannelsViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending carousel
          if (vm.trendingRadios.isNotEmpty) ...[
            _sectionHeader(
              'Trending now',
              Icons.trending_up,
              subtitle: 'Most listeners in the last 24 hours',
              onSeeAll: () => vm.setFilter(ChannelFilter.trending),
            ),
            _carousel(vm.trendingRadios, vm, context: ChannelFilter.trending),
            const SizedBox(height: 20),
          ],

          // For you carousel
          if (vm.forYouRadios.isNotEmpty) ...[
            _sectionHeader(
              'For you',
              Icons.auto_awesome,
              subtitle: 'Based on your language, city and age group',
              onSeeAll: () => vm.setFilter(ChannelFilter.forYou),
            ),
            _carousel(vm.forYouRadios, vm, context: ChannelFilter.forYou),
            const SizedBox(height: 20),
          ],

          // Following carousel
          if (vm.followingRadios.isNotEmpty) ...[
            _sectionHeader(
              'Your radios',
              Icons.favorite,
              subtitle:
                  '${vm.followingRadios.length} radio${vm.followingRadios.length == 1 ? "" : "s"} you follow',
              onSeeAll: () => vm.setFilter(ChannelFilter.following),
            ),
            _carousel(vm.followingRadios, vm, context: ChannelFilter.following),
            const SizedBox(height: 20),
          ],

          // All stations grid
          _sectionHeader('All stations', Icons.radio),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _gridContent(vm.visibleRadios, vm),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon,
      {String? subtitle, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment:
            subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: subtitle != null ? 2 : 0),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onSeeAll,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios,
                          size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _carousel(
    List<dynamic> radios,
    ChannelsViewModel vm, {
    required ChannelFilter context,
  }) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: radios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = radios[i];
          return SizedBox(
            width: 320,
            child: RadioCard(
              radio: r,
              compact: true,
              reason: vm.reasonFor(r, context: context),
              onTap: () => _openRadio(r.id),
              onToggleFollow: () =>
                  vm.toggleFollow(r.id, _uid, !r.isFollowed),
            ),
          );
        },
      ),
    );
  }

  // -------- SINGLE GRID for tabs --------

  Widget _grid(List<dynamic> radios, String title, ChannelsViewModel vm,
      {String? emptyMessage, ChannelFilter context = ChannelFilter.all}) {
    if (radios.isEmpty) {
      return _emptyState(
        emptyMessage ?? 'No radios found',
        'Try a different filter or search',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${radios.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _gridContent(radios, vm, context: context),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _gridContent(List<dynamic> radios, ChannelsViewModel vm,
      {ChannelFilter context = ChannelFilter.all}) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width > 900
            ? 5
            : (width > 600
                ? 4
                : (width > 340 ? 3 : 2));
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemCount: radios.length,
          itemBuilder: (_, i) {
            final r = radios[i];
            return RadioCard(
              radio: r,
              reason: vm.reasonFor(r, context: context),
              onTap: () => _openRadio(r.id),
              onToggleFollow: () => vm.toggleFollow(r.id, _uid, !r.isFollowed),
            );
          },
        );
      },
    );
  }

  // -------- SEARCH RESULTS --------

  Widget _searchResults(ChannelsViewModel vm) {
    final results = vm.visibleRadios;

    if (results.isEmpty) {
      return _emptyState(
        'No radios found for "${vm.query}"',
        'Try different keywords or browse categories',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Results for "${vm.query}"',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${results.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _gridContent(results, vm),
        ],
      ),
    );
  }

  // -------- HELPERS --------

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radio_outlined,
                size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _openRadio(String radioId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RadioStationPage(radioId: radioId),
      ),
    );
  }
}
