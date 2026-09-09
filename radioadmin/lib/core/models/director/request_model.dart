import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RequestType {
  announcement,
  technicalSupport,
  contentApproval,
  featureRequest,
  report,
  other,
}

enum RequestStatus { pending, approved, rejected, inProgress, completed }

class Request {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final RequestType type;
  final String title;
  final String description;
  final RequestStatus status;
  final Map<String, dynamic> metadata;
  final String? adminResponse;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Request({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.title,
    required this.description,
    this.status = RequestStatus.pending,
    this.metadata = const {},
    this.adminResponse,
    this.processedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Request.fromFirestore(Map<String, dynamic> data, String id) {
    return Request(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userEmail: data['userEmail'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => RequestType.other,
      ),
      title: data['title'] ?? 'Untitled Request',
      description: data['description'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      metadata: data['metadata'] ?? {},
      adminResponse: data['adminResponse'],
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'type': type.toString().split('.').last,
    'title': title,
    'description': description,
    'status': status.toString().split('.').last,
    'metadata': metadata,
    'adminResponse': adminResponse,
    'processedAt': processedAt,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  String get typeLabel {
    switch (type) {
      case RequestType.announcement:
        return '📢 Announcement';
      case RequestType.technicalSupport:
        return '🛠️ Technical Support';
      case RequestType.contentApproval:
        return '📝 Content Approval';
      case RequestType.featureRequest:
        return '💡 Feature Request';
      case RequestType.report:
        return '📊 Report';
      case RequestType.other:
        return '📋 Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return '🟡 Pending';
      case RequestStatus.approved:
        return '🟢 Approved';
      case RequestStatus.rejected:
        return '🔴 Rejected';
      case RequestStatus.inProgress:
        return '🟠 In Progress';
      case RequestStatus.completed:
        return '✅ Completed';
    }
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.inProgress:
        return Colors.blue;
      case RequestStatus.completed:
        return Colors.teal;
    }
  }
}
