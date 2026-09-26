import 'package:cloud_firestore/cloud_firestore.dart';

class StationMediaModel {
  final String id;
  final String radioId;
  final String title;
  final String? description;
  final String mediaType; // 'audio', 'video', 'podcast'
  final String url;
  final String? thumbnailUrl;
  final int durationSeconds;
  final List<String> tags;
  final String? programId;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final int playCount;

  StationMediaModel({
    required this.id,
    required this.radioId,
    required this.title,
    this.description,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.tags = const [],
    this.programId,
    this.uploadedBy,
    required this.uploadedAt,
    this.playCount = 0,
  });

  bool get isAudio => mediaType.toLowerCase() == 'audio';
  bool get isVideo => mediaType.toLowerCase() == 'video';
  bool get isPodcast => mediaType.toLowerCase() == 'podcast';

  String get typeLabel {
    switch (mediaType.toLowerCase()) {
      case 'video':
        return 'Video';
      case 'podcast':
        return 'Podcast';
      case 'audio':
      default:
        return 'Audio';
    }
  }

  String get formattedDuration {
    if (durationSeconds <= 0) return '';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final remM = m % 60;
      return '${h}h ${remM.toString().padLeft(2, '0')}m';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  factory StationMediaModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return StationMediaModel(
      id: id,
      radioId: (data['radioId'] ?? '').toString(),
      title: (data['title'] ?? data['name'] ?? 'Untitled Media').toString(),
      description: data['description']?.toString(),
      mediaType: (data['mediaType'] ?? data['type'] ?? 'audio').toString(),
      url: (data['url'] ?? data['streamUrl'] ?? data['mediaUrl'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? data['coverUrl'] ?? data['imageUrl'])?.toString(),
      durationSeconds: (data['durationSeconds'] ?? (data['duration'] is int ? data['duration'] : 0)) as int,
      tags: (data['tags'] is List) ? List<String>.from(data['tags']) : <String>[],
      programId: data['programId']?.toString(),
      uploadedBy: data['uploadedBy']?.toString(),
      uploadedAt: parseDate(data['uploadedAt'] ?? data['createdAt']),
      playCount: (data['playCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'title': title,
    'description': description,
    'mediaType': mediaType,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
    'tags': tags,
    'programId': programId,
    'uploadedBy': uploadedBy,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'playCount': playCount,
  };
}
