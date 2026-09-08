import 'package:flutter/material.dart';
import '../core/models/sysadmin/server_model.dart';
import '../core/models/sysadmin/backup_model.dart';
import '../core/models/sysadmin/security_log_model.dart';
import '../core/models/sysadmin/deployment_model.dart';
import '../core/services/sysadmin_service.dart';
import 'base_view_model.dart';

class SysAdminViewModel extends BaseViewModel {
  final SysAdminService _sysAdminService;

  List<Server> _servers = [];
  List<Backup> _backups = [];
  List<SecurityLog> _securityLogs = [];
  List<Deployment> _deployments = [];

  bool _isLoading = true;
  int _selectedTab = 0;

  SysAdminViewModel({
    required SysAdminService sysAdminService,
  }) : _sysAdminService = sysAdminService {
    _loadData();
  }

  List<Server> get servers => _servers;
  List<Backup> get backups => _backups;
  List<SecurityLog> get securityLogs => _securityLogs;
  List<Deployment> get deployments => _deployments;
  bool get isLoading => _isLoading;
  int get selectedTab => _selectedTab;

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  Future<void> _loadData() async {
    setState(ViewState.loading);
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadServers(),
        _loadBackups(),
        _loadSecurityLogs(),
        _loadDeployments(),
      ]);
      _isLoading = false;
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      setError('Failed to load data');
      notifyListeners();
    }
  }

  Future<void> _loadServers() async {
    _servers = await _sysAdminService.getServers();
  }

  Future<void> _loadBackups() async {
    _backups = await _sysAdminService.getBackups();
  }

  Future<void> _loadSecurityLogs() async {
    _securityLogs = await _sysAdminService.getSecurityLogs();
  }

  Future<void> _loadDeployments() async {
    _deployments = await _sysAdminService.getDeployments();
  }

  Future<void> restartServer(String id) async {
    await _sysAdminService.restartServer(id);
    await _loadServers();
  }

  Future<void> updateServer(String id, Map<String, dynamic> data) async {
    await _sysAdminService.updateServer(id, data);
    await _loadServers();
  }

  Future<void> createBackup(Backup backup) async {
    await _sysAdminService.createBackup(backup);
    await _loadBackups();
  }

  Future<void> deleteBackup(String id) async {
    await _sysAdminService.deleteBackup(id);
    await _loadBackups();
  }

  Future<void> restoreBackup(String id) async {
    await _sysAdminService.restoreBackup(id);
    await _loadBackups();
  }

  Future<void> addSecurityLog(SecurityLog log) async {
    await _sysAdminService.addSecurityLog(log);
    await _loadSecurityLogs();
  }

  Future<void> triggerDeployment(Deployment deployment) async {
    await _sysAdminService.triggerDeployment(deployment);
    await _loadDeployments();
  }

  int get totalServers => _servers.length;
  int get runningServers => _servers.where((s) => s.status == ServerStatus.running).length;
  int get failedServers => _servers.where((s) => s.status == ServerStatus.error).length;
  double get averageCpuUsage {
    if (_servers.isEmpty) return 0;
    return _servers.map((s) => s.cpuUsage).reduce((a, b) => a + b) / _servers.length;
  }
  double get averageMemoryUsage {
    if (_servers.isEmpty) return 0;
    return _servers.map((s) => s.memoryUsage).reduce((a, b) => a + b) / _servers.length;
  }

  int get totalBackups => _backups.length;
  int get completedBackups => _backups.where((b) => b.status == BackupStatus.completed).length;
  int get failedBackups => _backups.where((b) => b.status == BackupStatus.failed).length;

  int get criticalSecurityEvents => _securityLogs.where((l) => l.severity == SeverityLevel.critical).length;
  int get warningSecurityEvents => _securityLogs.where((l) => l.severity == SeverityLevel.warning).length;

  int get successfulDeployments => _deployments.where((d) => d.status == DeploymentStatus.completed).length;
  int get failedDeployments => _deployments.where((d) => d.status == DeploymentStatus.failed).length;

  Future<void> refreshData() async {
    await _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
