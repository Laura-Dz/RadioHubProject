import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/main_layout_view_model.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import '../widgets/mini_player_bar.dart';
import 'tabs/home_tab.dart';
import 'tabs/channels_tab.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/settings_tab.dart';
import '../../core/enums/navigation_tabs.dart';

class MainLayoutScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainLayoutScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MainLayoutViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: NavigationTabs.values.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final tab = NavigationTabs.values[_tabController.index];
        _viewModel.setTab(tab);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _viewModel = context.watch<MainLayoutViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: _viewModel.currentTitle,
        isStationPage: _viewModel.currentTab == NavigationTabs.home,
        onThemeToggle: _viewModel.toggleTheme,
        isDarkMode: _viewModel.isDarkMode,
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeTab(),
          ChannelsTab(),
          AnnouncementsTab(),
          ProfileTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          CustomBottomNavBar(
            currentTab: _viewModel.currentTab,
            onTabSelected: (tab) {
              final index = NavigationTabs.values.indexOf(tab);
              _tabController.animateTo(index);
              _viewModel.setTab(tab);
            },
          ),
        ],
      ),
    );
  }
}

