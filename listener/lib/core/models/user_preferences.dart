class UserPreferences {
  // Notifications
  final bool pushNotifications;
  final bool followedShowAlerts;
  final bool hostReplyAlerts;
  final bool callStatusAlerts;
  final bool announcementUpdates;

  // Audio
  final String audioQuality;   // 'auto' | 'low' | 'medium' | 'high'
  final bool dataSaver;
  final bool autoplayOnOpen;

  // Display
  final String theme;          // 'light' | 'dark' | 'system'
  final bool reduceMotion;

  UserPreferences({
    this.pushNotifications = true,
    this.followedShowAlerts = true,
    this.hostReplyAlerts = true,
    this.callStatusAlerts = true,
    this.announcementUpdates = true,
    this.audioQuality = 'auto',
    this.dataSaver = false,
    this.autoplayOnOpen = false,
    this.theme = 'system',
    this.reduceMotion = false,
  });

  factory UserPreferences.fromFirestore(Map<String, dynamic> d) =>
      UserPreferences(
        pushNotifications: d['pushNotifications'] != false,
        followedShowAlerts: d['followedShowAlerts'] != false,
        hostReplyAlerts: d['hostReplyAlerts'] != false,
        callStatusAlerts: d['callStatusAlerts'] != false,
        announcementUpdates: d['announcementUpdates'] != false,
        audioQuality: (d['audioQuality'] ?? 'auto').toString(),
        dataSaver: d['dataSaver'] == true,
        autoplayOnOpen: d['autoplayOnOpen'] == true,
        theme: (d['theme'] ?? 'system').toString(),
        reduceMotion: d['reduceMotion'] == true,
      );

  Map<String, dynamic> toFirestore() => {
        'pushNotifications': pushNotifications,
        'followedShowAlerts': followedShowAlerts,
        'hostReplyAlerts': hostReplyAlerts,
        'callStatusAlerts': callStatusAlerts,
        'announcementUpdates': announcementUpdates,
        'audioQuality': audioQuality,
        'dataSaver': dataSaver,
        'autoplayOnOpen': autoplayOnOpen,
        'theme': theme,
        'reduceMotion': reduceMotion,
      };

  UserPreferences copyWith({
    bool? pushNotifications,
    bool? followedShowAlerts,
    bool? hostReplyAlerts,
    bool? callStatusAlerts,
    bool? announcementUpdates,
    String? audioQuality,
    bool? dataSaver,
    bool? autoplayOnOpen,
    String? theme,
    bool? reduceMotion,
  }) =>
      UserPreferences(
        pushNotifications: pushNotifications ?? this.pushNotifications,
        followedShowAlerts: followedShowAlerts ?? this.followedShowAlerts,
        hostReplyAlerts: hostReplyAlerts ?? this.hostReplyAlerts,
        callStatusAlerts: callStatusAlerts ?? this.callStatusAlerts,
        announcementUpdates: announcementUpdates ?? this.announcementUpdates,
        audioQuality: audioQuality ?? this.audioQuality,
        dataSaver: dataSaver ?? this.dataSaver,
        autoplayOnOpen: autoplayOnOpen ?? this.autoplayOnOpen,
        theme: theme ?? this.theme,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );
}
