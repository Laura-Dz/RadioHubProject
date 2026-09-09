import 'package:cloud_firestore/cloud_firestore.dart';

enum FollowStatus { active, inactive }

enum NotificationType { showLive, showUpcoming, showReminder, newEpisode, channelUpdate, general }

class StarredChannel {
  final String id;
  final String userId;
  final String channelId;
  final DateTime createdAt;

  StarredChannel({
    required this.id,
    required this.userId,
    required this.channelId,
    required this.createdAt,
  });

  factory StarredChannel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StarredChannel(
      id: doc.id,
      userId: data['userId'] ?? '',
      channelId: data['channelId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'channelId': channelId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class ShowFollow {
  final String id;
  final String userId;
  final String showId;
  final FollowStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShowFollow({
    required this.id,
    required this.userId,
    required this.showId,
    this.status = FollowStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShowFollow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShowFollow(
      id: doc.id,
      userId: data['userId'] ?? '',
      showId: data['showId'] ?? '',
      status: FollowStatus.values.firstWhere(
        (e) => e.toString() == 'FollowStatus.${data['status']}',
        orElse: () => FollowStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'showId': showId,
    'status': status.toString().split('.').last,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class ShowReminder {
  final String id;
  final String userId;
  final String showId;
  final String programName;
  final DateTime showStartTime;
  final int reminderMinutesBefore;
  final bool isActive;
  final bool isNotified;
  final DateTime createdAt;
  final DateTime? notifiedAt;

  ShowReminder({
    required this.id,
    required this.userId,
    required this.showId,
    required this.programName,
    required this.showStartTime,
    this.reminderMinutesBefore = 15,
    this.isActive = true,
    this.isNotified = false,
    required this.createdAt,
    this.notifiedAt,
  });

  factory ShowReminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShowReminder(
      id: doc.id,
      userId: data['userId'] ?? '',
      showId: data['showId'] ?? '',
      programName: data['programName'] ?? '',
      showStartTime: (data['showStartTime'] as Timestamp).toDate(),
      reminderMinutesBefore: data['reminderMinutesBefore'] ?? 15,
      isActive: data['isActive'] ?? true,
      isNotified: data['isNotified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notifiedAt: (data['notifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'showId': showId,
    'programName': programName,
    'showStartTime': showStartTime,
    'reminderMinutesBefore': reminderMinutesBefore,
    'isActive': isActive,
    'isNotified': isNotified,
    'createdAt': createdAt,
    'notifiedAt': notifiedAt,
  };

  DateTime get reminderTime => showStartTime.subtract(
    Duration(minutes: reminderMinutesBefore),
  );

  bool get shouldNotify => isActive && !isNotified &&
      DateTime.now().isAfter(reminderTime) &&
      DateTime.now().isBefore(showStartTime);
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? showId;
  final String? channelId;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.showId,
    this.channelId,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.general,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      showId: data['showId'],
      channelId: data['channelId'],
      imageUrl: data['imageUrl'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      data: data['data'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.toString().split('.').last,
    'title': title,
    'body': body,
    'showId': showId,
    'channelId': channelId,
    'imageUrl': imageUrl,
    'isRead': isRead,
    'createdAt': FieldValue.serverTimestamp(),
    'readAt': readAt,
    'data': data,
  };
}
