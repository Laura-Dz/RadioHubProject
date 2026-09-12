enum NavigationTabs {
  home,
  channels,
  schedule,
  timetable,
  announcements,
  profile,
  settings,
}

extension NavigationTabsExtension on NavigationTabs {
  String get label {
    switch (this) {
      case NavigationTabs.home:
        return 'Home';
      case NavigationTabs.channels:
        return 'Channels';
      case NavigationTabs.schedule:
        return 'Schedule';
      case NavigationTabs.timetable:
        return 'Timetable';
      case NavigationTabs.announcements:
        return 'Announce';
      case NavigationTabs.profile:
        return 'Profile';
      case NavigationTabs.settings:
        return 'Settings';
    }
  }

  String get icon {
    switch (this) {
      case NavigationTabs.home:
        return 'home';
      case NavigationTabs.channels:
        return 'radio';
      case NavigationTabs.schedule:
        return 'calendar_today';
      case NavigationTabs.timetable:
        return 'event';
      case NavigationTabs.announcements:
        return 'campaign';
      case NavigationTabs.profile:
        return 'person';
      case NavigationTabs.settings:
        return 'settings';
    }
  }

  String get activeIcon {
    switch (this) {
      case NavigationTabs.home:
        return 'home_filled';
      case NavigationTabs.channels:
        return 'radio_filled';
      case NavigationTabs.schedule:
        return 'calendar_today';
      case NavigationTabs.timetable:
        return 'event';
      case NavigationTabs.announcements:
        return 'campaign_filled';
      case NavigationTabs.profile:
        return 'person_filled';
      case NavigationTabs.settings:
        return 'settings_filled';
    }
  }
}

