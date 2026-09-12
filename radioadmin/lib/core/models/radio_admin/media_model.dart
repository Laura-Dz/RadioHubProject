import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { audio, video }

class MediaItem {
  final String id;
  final String radioId;
  final String title;
  final String? description;
  final MediaType mediaType;
  final String url;
  final String? thumbnailUrl;
  final Duration? duration;
  final int? fileSizeBytes;
  final List<String> tags;
  final String? programId;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int playCount;

  MediaItem({
    required this.id,
    required this.radioId,
    required this.title,
    this.description,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.fileSizeBytes,
    this.tags = const [],
    this.programId,
    required this.uploadedBy,
    required this.uploadedAt,
    this.playCount = 0,
  });

  factory MediaItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MediaItem(
      id: id,
      radioId: data['radioId'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'],
      mediaType: MediaType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() == (data['mediaType'] ?? '').toString().toLowerCase() ||
            e.toString().toLowerCase() == (data['mediaType'] ?? '').toString().toLowerCase(),
        orElse: () => MediaType.audio,
      ),
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      duration: data['duration'] != null
          ? Duration(seconds: (data['duration'] is num) ? (data['duration'] as num).toInt() : int.tryParse(data['duration'].toString()) ?? 0)
          : null,
      fileSizeBytes: data['fileSizeBytes'] != null
          ? ((data['fileSizeBytes'] is num) ? (data['fileSizeBytes'] as num).toInt() : int.tryParse(data['fileSizeBytes'].toString()))
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      programId: data['programId'],
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: (data['uploadedAt'] is Timestamp)
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      playCount: data['playCount'] != null
          ? ((data['playCount'] is num) ? (data['playCount'] as num).toInt() : int.tryParse(data['playCount'].toString()) ?? 0)
          : 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'title': title,
    'description': description,
    'mediaType': mediaType.toString().split('.').last,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'duration': duration?.inSeconds,
    'fileSizeBytes': fileSizeBytes,
    'tags': tags,
    'programId': programId,
    'uploadedBy': uploadedBy,
    'uploadedAt': FieldValue.serverTimestamp(),
    'playCount': playCount,
  };
}