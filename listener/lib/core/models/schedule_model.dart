import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String title;
  final String host;
  final String? guest;
  final String? guestTitle;
  final String? guestBio;
  final String? guestImageUrl;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleItemType type;
  final String? description;
  final String? imageUrl;
  final int listenerCount;
  final bool isLive;
  final bool isInteractive;
  final String? channelId;
  final String? channelName;
  final String? flashId;
  final List<String> tags;
  final String? recordingUrl;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.host,
    this.guest,
    this.guestTitle,
    this.guestBio,
    this.guestImageUrl,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.description,
    this.imageUrl,
    this.listenerCount = 0,
    this.isLive = false,
    this.isInteractive = false,
    this.channelId,
    this.channelName,
    this.flashId,
    this.tags = const [],
    this.recordingUrl,
  });

  Duration get duration => endTime.difference(startTime);
  String get timeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isNow => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());

  String get timeRemaining {
    if (!isNow && !isUpcoming) return '';
    final now = DateTime.now();
    final diff = isNow ? endTime.difference(now) : startTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String get statusLabel {
    if (isLive) return '🔴 LIVE';
    if (isNow) return '🟢 NOW';
    if (isUpcoming) return '⏳ UPCOMING';
    return '✅ ENDED';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get typeLabel {
    switch (type) {
      case ScheduleItemType.special:
        return '⭐ SPECIAL EVENT';
      case ScheduleItemType.flash:
        return '⚡ FLASH';
      default:
        return '🔄 REGULAR';
    }
  }

  Color get typeColor {
    switch (type) {
      case ScheduleItemType.special:
        return const Color(0xFFF5A623);
      case ScheduleItemType.flash:
        return const Color(0xFFFF4757);
      default:
        return const Color(0xFF4A90D9);
    }
  }

  Color get statusColor {
    if (isLive || isNow) return const Color(0xFF2ECC71);
    if (isUpcoming) return const Color(0xFF4A90D9);
    return Colors.grey;
  }
}

enum ScheduleItemType {
  regular,
  special,
  flash,
}
