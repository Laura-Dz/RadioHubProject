import 'package:cloud_firestore/cloud_firestore.dart';

class MediaItem {
  final String id;
  final String title;
  final String? description;
  final String mediaType; // 'audio' | 'video' | 'podcast'
  final String url;
  final String? thumbnailUrl;
  final Duration? duration;
  final int fileSizeBytes;
  final List<String> tags;
  final String? programId;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final int playCount;

  MediaItem({
    required this.id,
    required this.title,
    this.description,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.fileSizeBytes = 0,
    this.tags = const [],
    this.programId,
    this.uploadedBy,
    required this.uploadedAt,
    this.playCount = 0,
  });

  factory MediaItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MediaItem(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'],
      mediaType: data['mediaType'] ?? 'audio',
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      duration: data['durationSeconds'] != null
          ? Duration(seconds: data['durationSeconds'] as int)
          : null,
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      programId: data['programId'],
      uploadedBy: data['uploadedBy'],
      uploadedAt: (data['uploadedAt'] is Timestamp)
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      playCount: data['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'mediaType': mediaType,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': duration?.inSeconds,
        'fileSizeBytes': fileSizeBytes,
        'tags': tags,
        'programId': programId,
        'uploadedBy': uploadedBy,
        'uploadedAt': FieldValue.serverTimestamp(),
        'playCount': playCount,
      };
}
