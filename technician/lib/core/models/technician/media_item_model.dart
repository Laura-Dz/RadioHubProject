import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum MediaType { audio, video, podcast }

class MediaItem {
  final String id;
  final String radioId;
  final String name;
  final String url;
  final String storagePath;
  final MediaType type;
  final int durationSeconds;
  final String? thumbnailUrl;
  final int fileSizeKb;
  final String? programId;
  final List<String> tags;
  final String? description;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String moderationStatus; // pending | approved | rejected

  MediaItem({
    required this.id,
    required this.radioId,
    required this.name,
    required this.url,
    required this.storagePath,
    required this.type,
    required this.durationSeconds,
    this.thumbnailUrl,
    this.fileSizeKb = 0,
    this.programId,
    this.tags = const [],
    this.description,
    required this.uploadedBy,
    required this.uploadedAt,
    this.moderationStatus = 'pending',
  });

  factory MediaItem.fromFirestore(Map<String, dynamic> d, String id) => MediaItem(
        id: id,
        radioId: (d['radioId'] ?? '').toString(),
        name: (d['name'] ?? '').toString(),
        url: (d['url'] ?? '').toString(),
        storagePath: (d['storagePath'] ?? '').toString(),
        type: MediaType.values.firstWhere(
          (e) => e.toString() == 'MediaType.${d['type']}',
          orElse: () => MediaType.audio,
        ),
        durationSeconds: FSParsers.toInt(d['durationSeconds']),
        thumbnailUrl: d['thumbnailUrl']?.toString(),
        fileSizeKb: FSParsers.toInt(d['fileSizeKb']),
        programId: d['programId']?.toString(),
        tags: List<String>.from(d['tags'] ?? []),
        description: d['description']?.toString(),
        uploadedBy: (d['uploadedBy'] ?? '').toString(),
        uploadedAt: FSParsers.toDate(d['uploadedAt']) ?? DateTime.now(),
        moderationStatus: (d['moderationStatus'] ?? 'pending').toString(),
      );

  Map<String, dynamic> toFirestore() => {
        'radioId': radioId,
        'name': name,
        'url': url,
        'storagePath': storagePath,
        'type': type.toString().split('.').last,
        'durationSeconds': durationSeconds,
        'thumbnailUrl': thumbnailUrl,
        'fileSizeKb': fileSizeKb,
        'programId': programId,
        'tags': tags,
        'description': description,
        'uploadedBy': uploadedBy,
        'uploadedAt': FieldValue.serverTimestamp(),
        'moderationStatus': moderationStatus,
      };

  String get durationDisplay {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String get typeLabel => switch (type) {
        MediaType.audio => 'Audio',
        MediaType.video => 'Video',
        MediaType.podcast => 'Podcast',
      };
}
