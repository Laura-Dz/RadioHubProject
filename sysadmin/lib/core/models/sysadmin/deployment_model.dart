import 'package:cloud_firestore/cloud_firestore.dart';

enum DeploymentStatus {
  pending,
  building,
  testing,
  deploying,
  verifying,
  completed,
  failed,
  rolledBack,
}

class Deployment {
  final String id;
  final String version;
  final String branch;
  final String commitHash;
  final String? commitMessage;
  final String deployedBy;
  final DeploymentStatus status;
  final int progress;
  final List<String> changes;
  final Map<String, dynamic> metrics;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final DateTime createdAt;

  Deployment({
    required this.id,
    required this.version,
    required this.branch,
    required this.commitHash,
    this.commitMessage,
    required this.deployedBy,
    required this.status,
    this.progress = 0,
    this.changes = const [],
    this.metrics = const {},
    required this.startedAt,
    this.completedAt,
    this.failureReason,
    required this.createdAt,
  });

  factory Deployment.fromFirestore(Map<String, dynamic> data, String id) {
    return Deployment(
      id: id,
      version: data['version'] ?? '1.0.0',
      branch: data['branch'] ?? 'main',
      commitHash: data['commitHash'] ?? '',
      commitMessage: data['commitMessage'],
      deployedBy: data['deployedBy'] ?? 'Unknown',
      status: DeploymentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => DeploymentStatus.pending,
      ),
      progress: data['progress'] ?? 0,
      changes: List<String>.from(data['changes'] ?? []),
      metrics: data['metrics'] ?? {},
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      failureReason: data['failureReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'version': version,
    'branch': branch,
    'commitHash': commitHash,
    'commitMessage': commitMessage,
    'deployedBy': deployedBy,
    'status': status.toString().split('.').last,
    'progress': progress,
    'changes': changes,
    'metrics': metrics,
    'startedAt': startedAt,
    'completedAt': completedAt,
    'failureReason': failureReason,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get statusLabel {
    switch (status) {
      case DeploymentStatus.pending:
        return '⏳ Pending';
      case DeploymentStatus.building:
        return '🔨 Building';
      case DeploymentStatus.testing:
        return '🧪 Testing';
      case DeploymentStatus.deploying:
        return '🚀 Deploying';
      case DeploymentStatus.verifying:
        return '✅ Verifying';
      case DeploymentStatus.completed:
        return '🎉 Completed';
      case DeploymentStatus.failed:
        return '❌ Failed';
      case DeploymentStatus.rolledBack:
        return '🔙 Rolled Back';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeploymentStatus.pending:
        return Colors.orange;
      case DeploymentStatus.building:
        return Colors.blue;
      case DeploymentStatus.testing:
        return Colors.purple;
      case DeploymentStatus.deploying:
        return Colors.indigo;
      case DeploymentStatus.verifying:
        return Colors.cyan;
      case DeploymentStatus.completed:
        return Colors.green;
      case DeploymentStatus.failed:
        return Colors.red;
      case DeploymentStatus.rolledBack:
        return Colors.amber;
    }
  }

  bool get isInProgress {
    return status == DeploymentStatus.building ||
        status == DeploymentStatus.testing ||
        status == DeploymentStatus.deploying ||
        status == DeploymentStatus.verifying;
  }

  String get durationDisplay {
    if (completedAt == null) return 'In progress...';
    final diff = completedAt!.difference(startedAt);
    final minutes = diff.inMinutes;
    if (minutes > 0) return '${minutes}m ${diff.inSeconds.remainder(60)}s';
    return '${diff.inSeconds}s';
  }
}
