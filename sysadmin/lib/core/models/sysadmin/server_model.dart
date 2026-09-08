import 'package:cloud_firestore/cloud_firestore.dart';

enum ServerStatus { running, stopped, restarting, error, maintenance }

class Server {
  final String id;
  final String name;
  final String type;
  final String host;
  final int port;
  final ServerStatus status;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkIn;
  final double networkOut;
  final int uptimeSeconds;
  final DateTime? lastRestart;
  final String? version;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Server({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    this.status = ServerStatus.running,
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.diskUsage = 0.0,
    this.networkIn = 0.0,
    this.networkOut = 0.0,
    this.uptimeSeconds = 0,
    this.lastRestart,
    this.version,
    this.config = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory Server.fromFirestore(Map<String, dynamic> data, String id) {
    return Server(
      id: id,
      name: data['name'] ?? 'Unnamed Server',
      type: data['type'] ?? 'unknown',
      host: data['host'] ?? 'localhost',
      port: data['port'] ?? 8080,
      status: ServerStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ServerStatus.running,
      ),
      cpuUsage: (data['cpuUsage'] ?? 0.0).toDouble(),
      memoryUsage: (data['memoryUsage'] ?? 0.0).toDouble(),
      diskUsage: (data['diskUsage'] ?? 0.0).toDouble(),
      networkIn: (data['networkIn'] ?? 0.0).toDouble(),
      networkOut: (data['networkOut'] ?? 0.0).toDouble(),
      uptimeSeconds: data['uptimeSeconds'] ?? 0,
      lastRestart: (data['lastRestart'] as Timestamp?)?.toDate(),
      version: data['version'],
      config: data['config'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'host': host,
    'port': port,
    'status': status.toString().split('.').last,
    'cpuUsage': cpuUsage,
    'memoryUsage': memoryUsage,
    'diskUsage': diskUsage,
    'networkIn': networkIn,
    'networkOut': networkOut,
    'uptimeSeconds': uptimeSeconds,
    'lastRestart': lastRestart,
    'version': version,
    'config': config,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  String get statusLabel {
    switch (status) {
      case ServerStatus.running:
        return '🟢 Running';
      case ServerStatus.stopped:
        return '⚫ Stopped';
      case ServerStatus.restarting:
        return '🟡 Restarting';
      case ServerStatus.error:
        return '🔴 Error';
      case ServerStatus.maintenance:
        return '🟠 Maintenance';
    }
  }

  Color get statusColor {
    switch (status) {
      case ServerStatus.running:
        return Colors.green;
      case ServerStatus.stopped:
        return Colors.grey;
      case ServerStatus.restarting:
        return Colors.orange;
      case ServerStatus.error:
        return Colors.red;
      case ServerStatus.maintenance:
        return Colors.amber;
    }
  }

  String get healthStatus {
    if (cpuUsage > 80 || memoryUsage > 80 || diskUsage > 85) {
      return '⚠️ Critical';
    } else if (cpuUsage > 60 || memoryUsage > 60 || diskUsage > 70) {
      return '🟡 Warning';
    }
    return '✅ Healthy';
  }

  Color get healthColor {
    if (cpuUsage > 80 || memoryUsage > 80 || diskUsage > 85) {
      return Colors.red;
    } else if (cpuUsage > 60 || memoryUsage > 60 || diskUsage > 70) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String get uptimeDisplay {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String get typeLabel {
    switch (type) {
      case 'streaming':
        return '📡 Streaming';
      case 'api':
        return '🔌 API';
      case 'database':
        return '🗄️ Database';
      case 'cache':
        return '⚡ Cache';
      default:
        return '🖥️ Server';
    }
  }
}
