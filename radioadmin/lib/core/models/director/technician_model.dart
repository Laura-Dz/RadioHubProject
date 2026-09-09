import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TechnicianStatus { active, inactive, suspended }

class Technician {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final TechnicianStatus status;
  final List<String> assignedPrograms;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isVerified;

  Technician({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.status = TechnicianStatus.active,
    this.assignedPrograms = const [],
    required this.createdAt,
    this.lastActive,
    this.isVerified = false,
  });

  factory Technician.fromFirestore(Map<String, dynamic> data, String id) {
    return Technician(
      id: id,
      name: data['name'] ?? 'Unknown Technician',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      status: TechnicianStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TechnicianStatus.active,
      ),
      assignedPrograms: List<String>.from(data['assignedPrograms'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'status': status.toString().split('.').last,
    'assignedPrograms': assignedPrograms,
    'createdAt': FieldValue.serverTimestamp(),
    'lastActive': lastActive,
    'isVerified': isVerified,
  };

  String get statusLabel {
    switch (status) {
      case TechnicianStatus.active:
        return '🟢 Active';
      case TechnicianStatus.inactive:
        return '⚫ Inactive';
      case TechnicianStatus.suspended:
        return '🔴 Suspended';
    }
  }

  Color get statusColor {
    switch (status) {
      case TechnicianStatus.active:
        return Colors.green;
      case TechnicianStatus.inactive:
        return Colors.grey;
      case TechnicianStatus.suspended:
        return Colors.red;
    }
  }
}
