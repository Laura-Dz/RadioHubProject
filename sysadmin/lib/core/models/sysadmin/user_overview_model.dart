import 'package:cloud_firestore/cloud_firestore.dart';

class UserOverview {
  final int totalListeners;
  final int totalHosts;
  final int totalTechnicians;
  final int totalRadioAdmins;
  final Map<String, int> userGrowth;
  final DateTime timestamp;

  UserOverview({
    required this.totalListeners,
    required this.totalHosts,
    required this.totalTechnicians,
    required this.totalRadioAdmins,
    required this.userGrowth,
    required this.timestamp,
  });

  int get totalUsers => totalListeners + totalHosts + totalTechnicians + totalRadioAdmins;

  factory UserOverview.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return UserOverview(
      totalListeners: (data['totalListeners'] ?? 0) as int,
      totalHosts: (data['totalHosts'] ?? 0) as int,
      totalTechnicians: (data['totalTechnicians'] ?? 0) as int,
      totalRadioAdmins: (data['totalRadioAdmins'] ?? 0) as int,
      userGrowth: Map<String, int>.from(data['userGrowth'] ?? {}),
      timestamp: parseDate(data['timestamp']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalListeners': totalListeners,
      'totalHosts': totalHosts,
      'totalTechnicians': totalTechnicians,
      'totalRadioAdmins': totalRadioAdmins,
      'userGrowth': userGrowth,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String role; // listener, host, technician, radio_admin, sysadmin
  final String? radioId;
  final String? radioName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.radioId,
    this.radioName,
    this.isActive = true,
    required this.createdAt,
    this.lastActive,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return User(
      id: id,
      name: data['displayName'] ?? data['name'] ?? 'Unknown User',
      email: data['email'] ?? '',
      role: (data['role'] ?? 'listener').toString().toLowerCase(),
      radioId: data['radioId'],
      radioName: data['radioName'],
      isActive: data['isActive'] ?? true,
      createdAt: parseDate(data['createdAt']),
      lastActive: parseNullableDate(data['lastActive']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': name,
      'email': email,
      'role': role,
      'radioId': radioId,
      'radioName': radioName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }

  String get roleLabel {
    switch (role) {
      case 'listener':
        return '🎧 Listener';
      case 'host':
        return '🎙️ Host';
      case 'technician':
        return '🎛️ Technician';
      case 'radio_admin':
        return '👤 RadioAdmin';
      case 'sysadmin':
        return '🛡️ SysAdmin';
      default:
        return role;
    }
  }
}

