import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleItem {
  final String id;
  final String title;
  final String host;
  final String? guest;
  final String? guestTitle;
  final String? guestBio;
  final String? guestImageUrl;
  final List<Map<String, String>> guests;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleItemType type;
  final String? description;
  final String? imageUrl;
  final int listenerCount;
  final bool isLive;
  final bool isInteractive;
  final bool isRediffusion;
  final bool allowCalls;
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
    this.guests = const [],
    required this.startTime,
    required this.endTime,
    required this.type,
    this.description,
    this.imageUrl,
    this.listenerCount = 0,
    this.isLive = false,
    this.isInteractive = false,
    this.isRediffusion = false,
    this.allowCalls = true,
    this.channelId,
    this.channelName,
    this.flashId,
    this.tags = const [],
    this.recordingUrl,
  });

  factory ScheduleItem.fromFirestore(Map<String, dynamic> data, String id) {
    final typeStr = data['type'] ?? 'regular';
    ScheduleItemType type;
    switch (typeStr) {
      case 'special':
        type = ScheduleItemType.special;
        break;
      case 'flash':
        type = ScheduleItemType.flash;
        break;
      default:
        type = ScheduleItemType.regular;
    }

    final List<Map<String, String>> parsedGuests = [];
    if (data['guests'] is List) {
      for (final item in (data['guests'] as List)) {
        if (item is Map) {
          parsedGuests.add({
            'name': (item['name'] ?? '').toString(),
            'role': (item['role'] ?? '').toString(),
          });
        }
      }
    } else if (data['guest'] != null && data['guest'].toString().isNotEmpty) {
      parsedGuests.add({
        'name': data['guest'].toString(),
        'role': (data['guestTitle'] ?? '').toString(),
      });
    } else if (data['guestName'] != null && data['guestName'].toString().isNotEmpty) {
      parsedGuests.add({
        'name': data['guestName'].toString(),
        'role': (data['guestRole'] ?? '').toString(),
      });
    }

    return ScheduleItem(
      id: id,
      title: data['title'] ?? 'Untitled Show',
      host: data['host'] ?? 'Unknown Host',
      guest: data['guest'] ?? (parsedGuests.isNotEmpty ? parsedGuests.first['name'] : null),
      guestTitle: data['guestTitle'] ?? (parsedGuests.isNotEmpty ? parsedGuests.first['role'] : null),
      guestBio: data['guestBio'],
      guestImageUrl: data['guestImageUrl'],
      guests: parsedGuests,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: type,
      description: data['description'],
      imageUrl: data['imageUrl'],
      listenerCount: data['listenerCount'] ?? 0,
      isLive: data['isLive'] ?? false,
      isInteractive: data['isInteractive'] ?? false,
      isRediffusion: data['isRediffusion'] == true || data['status'] == 'rediffusion',
      allowCalls: data['allowCalls'] != false,
      channelId: data['channelId'],
      channelName: data['channelName'],
      flashId: data['flashId'],
      tags: List<String>.from(data['tags'] ?? []),
      recordingUrl: data['recordingUrl'],
    );
  }

  Duration get duration => endTime.difference(startTime);
  String get timeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isNow => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());

  String get displayTag {
    if (isRediffusion) return 'REDIFFUSION';
    if (isLive || isNow) return 'LIVE';
    if (isUpcoming) return 'UPCOMING';
    return 'ENDED';
  }

  String get statusLabel {
    if (isRediffusion) return '📻 REDIFFUSION';
    if (isLive) return '🔴 LIVE';
    if (isNow) return '🟢 NOW';
    if (isUpcoming) return '⏳ UPCOMING';
    return '✅ ENDED';
  }

  String get timeRemaining {
    if (!isNow && !isUpcoming) return '';
    final now = DateTime.now();
    final diff = isNow ? endTime.difference(now) : startTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
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
