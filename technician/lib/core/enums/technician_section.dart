import 'package:flutter/material.dart';

enum TechnicianSection {
  sessions,
  hosts,
  programs,
  schedule,
  media,
  metrics,
  settings,
}

extension TechnicianSectionExtension on TechnicianSection {
  String get title {
    switch (this) {
      case TechnicianSection.sessions:
        return 'Sessions';
      case TechnicianSection.hosts:
        return 'Hosts';
      case TechnicianSection.programs:
        return 'Programs';
      case TechnicianSection.schedule:
        return 'Schedule';
      case TechnicianSection.media:
        return 'Media';
      case TechnicianSection.metrics:
        return 'Metrics';
      case TechnicianSection.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case TechnicianSection.sessions:
        return Icons.event_note;
      case TechnicianSection.hosts:
        return Icons.mic;
      case TechnicianSection.programs:
        return Icons.tv;
      case TechnicianSection.schedule:
        return Icons.calendar_today;
      case TechnicianSection.media:
        return Icons.folder;
      case TechnicianSection.metrics:
        return Icons.bar_chart;
      case TechnicianSection.settings:
        return Icons.settings;
    }
  }
}
