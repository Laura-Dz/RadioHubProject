import 'package:flutter/material.dart';

class FlashProgram {
  final String id;
  final String title;
  final String description;
  final FlashType type;
  final FlashStatus status;
  final DateTime? broadcastTime;
  final int durationSeconds;
  final String? host;
  final bool isActive;
  final bool interruptedShow;
  final String? interruptedShowId;
  final String? recordingUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;

  FlashProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.broadcastTime,
    this.durationSeconds = 180,
    this.host,
    this.isActive = false,
    this.interruptedShow = false,
    this.interruptedShowId,
    this.recordingUrl,
    required this.createdAt,
    this.expiresAt,
  });

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    if (minutes > 0) return '${minutes}min';
    return '${durationSeconds}s';
  }

  String get typeLabel {
    switch (type) {
      case FlashType.breakingNews:
        return '📰 Breaking News';
      case FlashType.weatherAlert:
        return '🌪️ Weather Alert';
      case FlashType.sportsFlash:
        return '⚽ Sports Flash';
      case FlashType.trafficUpdate:
        return '🚗 Traffic Update';
      case FlashType.specialAnnouncement:
        return '📢 Announcement';
      case FlashType.systemUpdate:
        return '🔧 System Update';
    }
  }

  Color get typeColor {
    switch (type) {
      case FlashType.breakingNews:
        return const Color(0xFFFF0000);
      case FlashType.weatherAlert:
        return const Color(0xFFFF6B00);
      case FlashType.sportsFlash:
        return const Color(0xFF4A90D9);
      case FlashType.trafficUpdate:
        return const Color(0xFFF5A623);
      case FlashType.specialAnnouncement:
        return const Color(0xFF2ECC71);
      case FlashType.systemUpdate:
        return const Color(0xFF9B59B6);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case FlashType.breakingNews:
        return Icons.warning_amber;
      case FlashType.weatherAlert:
        return Icons.wb_sunny;
      case FlashType.sportsFlash:
        return Icons.sports;
      case FlashType.trafficUpdate:
        return Icons.traffic;
      case FlashType.specialAnnouncement:
        return Icons.volume_up;
      case FlashType.systemUpdate:
        return Icons.system_update;
    }
  }
}

enum FlashType {
  breakingNews,
  weatherAlert,
  sportsFlash,
  trafficUpdate,
  specialAnnouncement,
  systemUpdate,
}

enum FlashStatus {
  pending,
  active,
  completed,
  cancelled,
}
