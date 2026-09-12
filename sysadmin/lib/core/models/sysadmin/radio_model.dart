import 'package:cloud_firestore/cloud_firestore.dart';

class RadioModel {
  final String id;
  final String name;
  final String broadcastLink;
  final String? contractCopy;
  final String? logoUrl;
  final String category;
  final String radioAdminId;
  final String radioAdminEmail;
  final String radioAdminName;
  final String? radioAdminPhone;
  final bool isActive;
  final String status; // 'live', 'recorded', 'inactive'
  final int listenerCount;
  int hostsCount;
  int techniciansCount;
  final DateTime createdAt;
  final Map<String, dynamic>? paymentSettings;

  RadioModel({
    required this.id,
    required this.name,
    required this.broadcastLink,
    this.contractCopy,
    this.logoUrl,
    this.category = 'General',
    required this.radioAdminId,
    required this.radioAdminEmail,
    required this.radioAdminName,
    this.radioAdminPhone,
    this.isActive = true,
    this.status = 'live',
    this.listenerCount = 0,
    this.hostsCount = 0,
    this.techniciansCount = 0,
    required this.createdAt,
    this.paymentSettings,
  });

  bool get isLive => status == 'live';

  List<String> get availablePaymentMethods {
    if (paymentSettings != null && paymentSettings!['availableMethods'] is List) {
      return List<String>.from(paymentSettings!['availableMethods']);
    }
    return ['MoMo', 'OM', 'Ecobank'];
  }

  factory RadioModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return RadioModel(
      id: id,
      name: data['name'] ?? 'Unnamed Radio',
      broadcastLink: data['broadcastLink'] ?? '',
      contractCopy: data['contractCopy'],
      logoUrl: data['logoUrl'],
      category: data['category'] ?? 'General',
      radioAdminId: data['radioAdminId'] ?? '',
      radioAdminEmail: data['radioAdminEmail'] ?? '',
      radioAdminName: data['radioAdminName'] ?? 'Admin',
      radioAdminPhone: data['radioAdminPhone'],
      isActive: data['isActive'] ?? true,
      status: data['status'] ?? (data['isActive'] == false ? 'inactive' : 'live'),
      listenerCount: (data['listenerCount'] ?? 0) as int,
      hostsCount: (data['hostsCount'] ?? 0) as int,
      techniciansCount: (data['techniciansCount'] ?? 0) as int,
      createdAt: parseDate(data['createdAt']),
      paymentSettings: data['paymentSettings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'broadcastLink': broadcastLink,
      'contractCopy': contractCopy,
      'logoUrl': logoUrl,
      'category': category,
      'radioAdminId': radioAdminId,
      'radioAdminEmail': radioAdminEmail,
      'radioAdminName': radioAdminName,
      'radioAdminPhone': radioAdminPhone,
      'isActive': isActive,
      'status': status,
      'listenerCount': listenerCount,
      'hostsCount': hostsCount,
      'techniciansCount': techniciansCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentSettings': paymentSettings,
    };
  }

  RadioModel copyWith({
    String? id,
    String? name,
    String? broadcastLink,
    String? contractCopy,
    String? logoUrl,
    String? category,
    String? radioAdminId,
    String? radioAdminEmail,
    String? radioAdminName,
    String? radioAdminPhone,
    bool? isActive,
    String? status,
    int? listenerCount,
    int? hostsCount,
    int? techniciansCount,
    DateTime? createdAt,
    Map<String, dynamic>? paymentSettings,
  }) {
    return RadioModel(
      id: id ?? this.id,
      name: name ?? this.name,
      broadcastLink: broadcastLink ?? this.broadcastLink,
      contractCopy: contractCopy ?? this.contractCopy,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      radioAdminId: radioAdminId ?? this.radioAdminId,
      radioAdminEmail: radioAdminEmail ?? this.radioAdminEmail,
      radioAdminName: radioAdminName ?? this.radioAdminName,
      radioAdminPhone: radioAdminPhone ?? this.radioAdminPhone,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      listenerCount: listenerCount ?? this.listenerCount,
      hostsCount: hostsCount ?? this.hostsCount,
      techniciansCount: techniciansCount ?? this.techniciansCount,
      createdAt: createdAt ?? this.createdAt,
      paymentSettings: paymentSettings ?? this.paymentSettings,
    );
  }
}

