class Category {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  Category({required this.id, required this.name, required this.slug, this.icon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
    );
  }
}

class Show {
  final int id;
  final String title;
  final String? description;
  final String? coverImage;
  final String hostName;
  final DateTime scheduleTime;
  final Category? category;
  final bool isActive;

  Show({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    required this.hostName,
    required this.scheduleTime,
    this.category,
    required this.isActive,
  });

  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      hostName: json['host_name'] as String,
      scheduleTime: DateTime.parse(json['schedule_time'] as String),
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class Episode {
  final int id;
  final int showId;
  final String showTitle;
  final String title;
  final String? description;
  final String audioFile;
  final int duration;
  final DateTime publishedAt;
  final int playCount;

  Episode({
    required this.id,
    required this.showId,
    required this.showTitle,
    required this.title,
    this.description,
    required this.audioFile,
    required this.duration,
    required this.publishedAt,
    required this.playCount,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int,
      showId: json['show'] as int,
      showTitle: json['show_title'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      audioFile: json['audio_file'] as String,
      duration: json['duration'] as int,
      publishedAt: DateTime.parse(json['published_at'] as String),
      playCount: json['play_count'] as int,
    );
  }
}

class LiveStream {
  final int id;
  final String streamUrl;
  final bool isLive;
  final String? currentTitle;
  final String? currentHost;
  final String? bannerMessage;
  final DateTime updatedAt;

  LiveStream({
    required this.id,
    required this.streamUrl,
    required this.isLive,
    this.currentTitle,
    this.currentHost,
    this.bannerMessage,
    required this.updatedAt,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'] as int,
      streamUrl: json['stream_url'] as String,
      isLive: json['is_live'] as bool,
      currentTitle: json['current_title'] as String?,
      currentHost: json['current_host'] as String?,
      bannerMessage: json['banner_message'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class Announcement {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isActive;
  final DateTime startTime;
  final DateTime endTime;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    required this.startTime,
    required this.endTime,
  });

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isActive: json['is_active'] as bool,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
    );
  }
}
