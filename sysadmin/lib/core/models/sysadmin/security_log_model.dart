import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SecurityEventType {
  login,
  logout,
  failedLogin,
  permissionChange,
  userCreated,
  userDeleted,
  apiAccess,
  suspiciousActivity,
  securityUpdate,
  backupAccess,
  configChange,
  systemAlert,
}

enum SeverityLevel { info, warning, error, critical }

class SecurityLog {
  final String id;
  final SecurityEventType eventType;
  final SeverityLevel severity;
  final String? userId;
  final String? ipAddress;
  final String? userAgent;
  final String description;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  SecurityLog({
    required this.id,
    required this.eventType,
    required this.severity,
    this.userId,
    this.ipAddress,
    this.userAgent,
    required this.description,
    this.details = const {},
    required this.timestamp,
  });

  factory SecurityLog.fromFirestore(Map<String, dynamic> data, String id) {
    return SecurityLog(
      id: id,
      eventType: SecurityEventType.values.firstWhere(
        (e) => e.toString() == data['eventType'],
        orElse: () => SecurityEventType.systemAlert,
      ),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == data['severity'],
        orElse: () => SeverityLevel.info,
      ),
      userId: data['userId'],
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      description: data['description'] ?? 'No description',
      details: data['details'] ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventType': eventType.toString().split('.').last,
    'severity': severity.toString().split('.').last,
    'userId': userId,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'description': description,
    'details': details,
    'timestamp': FieldValue.serverTimestamp(),
  };

  String get severityLabel {
    switch (severity) {
      case SeverityLevel.info:
        return 'ℹ️ Info';
      case SeverityLevel.warning:
        return '⚠️ Warning';
      case SeverityLevel.error:
        return '❌ Error';
      case SeverityLevel.critical:
        return '🔥 Critical';
    }
  }

  Color get severityColor {
    switch (severity) {
      case SeverityLevel.info:
        return Colors.blue;
      case SeverityLevel.warning:
        return Colors.orange;
      case SeverityLevel.error:
        return Colors.red;
      case SeverityLevel.critical:
        return Colors.deepOrange;
    }
  }

  String get eventLabel {
    switch (eventType) {
      case SecurityEventType.login:
        return '🔐 Login';
      case SecurityEventType.logout:
        return '🚪 Logout';
      case SecurityEventType.failedLogin:
        return '❌ Failed Login';
      case SecurityEventType.permissionChange:
        return '🔑 Permission Change';
      case SecurityEventType.userCreated:
        return '👤 User Created';
      case SecurityEventType.userDeleted:
        return '🗑️ User Deleted';
      case SecurityEventType.apiAccess:
        return '📡 API Access';
      case SecurityEventType.suspiciousActivity:
        return '🚨 Suspicious Activity';
      case SecurityEventType.securityUpdate:
        return '🛡️ Security Update';
      case SecurityEventType.backupAccess:
        return '💾 Backup Access';
      case SecurityEventType.configChange:
        return '⚙️ Config Change';
      case SecurityEventType.systemAlert:
        return '🔔 System Alert';
    }
  }
}
