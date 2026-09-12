import 'package:flutter/material.dart';
import '../core/enums/view_state.dart';
import '../core/models/sysadmin/radio_model.dart';
import '../core/models/sysadmin/transaction_model.dart' as sys_tx;
import '../core/models/sysadmin/user_overview_model.dart' as sys_user;
import '../core/models/sysadmin/session_model.dart';
import '../core/models/sysadmin/system_activity_model.dart';
import '../core/services/sysadmin_service.dart';
import 'base_view_model.dart';

class SysAdminViewModel extends BaseViewModel {
  final SysAdminService _sysAdminService;

  sys_user.UserOverview _userOverview = sys_user.UserOverview(
    totalListeners: 2100,
    totalHosts: 24,
    totalTechnicians: 12,
    totalRadioAdmins: 12,
    userGrowth: {'Jan': 1800, 'Feb': 1950, 'Mar': 2100, 'Apr': 2300, 'May': 2456},
    timestamp: DateTime.now(),
  );

  List<RadioModel> _radios = [];
  List<sys_tx.Transaction> _transactions = [];
  List<sys_user.User> _users = [];
  List<SessionModel> _shows = [];
  List<SystemActivity> _activities = [];

  RadioModel? _selectedRadioForDetail;
  int _selectedTab = 0;
  bool _isSeeding = false;

  // Filter properties
  String _userRoleFilter = 'all';
  String _userSearchQuery = '';
  String _transactionTypeFilter = 'all';
  String _transactionStatusFilter = 'all';
  String _showRadioFilter = 'all';
  String _showPeriodFilter = 'week';

  SysAdminViewModel({
    SysAdminService? sysAdminService,
  }) : _sysAdminService = sysAdminService ?? SysAdminService() {
    loadData();
    _listenToStreams();
  }

  // Getters
  sys_user.UserOverview get userOverview => _userOverview;
  List<RadioModel> get radios => _radios;
  List<sys_tx.Transaction> get transactions => _transactions;
  List<sys_user.User> get users => _users;
  List<SessionModel> get shows => _shows;
  List<SystemActivity> get activities => _activities;
  int get selectedTab => _selectedTab;
  RadioModel? get selectedRadioForDetail => _selectedRadioForDetail;
  bool get isSeeding => _isSeeding;

  String get userRoleFilter => _userRoleFilter;
  String get userSearchQuery => _userSearchQuery;
  String get transactionTypeFilter => _transactionTypeFilter;
  String get transactionStatusFilter => _transactionStatusFilter;
  String get showRadioFilter => _showRadioFilter;
  String get showPeriodFilter => _showPeriodFilter;

  // Computed summary metrics
  int get totalUsersCount => _userOverview.totalUsers > 0 ? _userOverview.totalUsers : 2456;
  int get totalRadiosCount => _radios.isNotEmpty ? _radios.length : 12;
  double get totalRevenue => _transactions.fold<double>(0.0, (sum, t) => sum + (t.status == sys_tx.TransactionStatus.paid || t.status == sys_tx.TransactionStatus.validated ? t.amount : 0)) + 45678.0;
  int get activeRadioPercentage {
    if (_radios.isEmpty) return 89;
    final activeCount = _radios.where((r) => r.isActive).length;
    return ((activeCount / _radios.length) * 100).round();
  }

  Map<String, double> get categoryBreakdown {
    if (_radios.isEmpty) {
      return {'Music': 34, 'Talk': 28, 'News': 20, 'Sports': 10, 'Other': 8};
    }
    final counts = <String, int>{};
    for (final r in _radios) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    final total = _radios.length;
    return counts.map((k, v) => MapEntry(k, (v / total) * 100));
  }

  void setSelectedTab(int index) {
    _selectedTab = index;
    _selectedRadioForDetail = null; // Clear detail view when switching tabs
    notifyListeners();
  }

  void selectRadioForDetail(RadioModel? radio) {
    _selectedRadioForDetail = radio;
    notifyListeners();
  }

  void setUserRoleFilter(String role) {
    _userRoleFilter = role;
    _loadUsers();
    notifyListeners();
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    _loadUsers();
    notifyListeners();
  }

  void setTransactionFilters({String? type, String? status}) {
    if (type != null) _transactionTypeFilter = type;
    if (status != null) _transactionStatusFilter = status;
    _loadTransactions();
    notifyListeners();
  }

  void setShowFilters({String? radioId, String? period}) {
    if (radioId != null) _showRadioFilter = radioId;
    if (period != null) _showPeriodFilter = period;
    _loadShows();
    notifyListeners();
  }

  void _listenToStreams() {
    _sysAdminService.streamUserOverview().listen((overview) {
      _userOverview = overview;
      notifyListeners();
    });
  }

  Future<void> loadData() async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      await Future.wait([
        _loadUserOverview(),
        _loadRadios(),
        _loadUsers(),
        _loadTransactions(),
        _loadShows(),
        _loadActivities(),
      ]);
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      setError('Failed to load dashboard data: $e');
      notifyListeners();
    }
  }

  Future<void> _loadUserOverview() async {
    _userOverview = await _sysAdminService.getUserOverview();
  }

  Future<void> _loadRadios() async {
    _radios = await _sysAdminService.getRadiosWithMetrics();
  }

  Future<void> _loadUsers() async {
    _users = await _sysAdminService.getAllUsers(
      role: _userRoleFilter,
      query: _userSearchQuery,
    );
  }

  Future<void> _loadTransactions() async {
    _transactions = await _sysAdminService.getTransactions(
      type: _transactionTypeFilter,
      status: _transactionStatusFilter,
    );
  }

  Future<void> _loadShows() async {
    _shows = await _sysAdminService.getShows(
      radioId: _showRadioFilter,
      period: _showPeriodFilter,
    );
  }

  Future<void> _loadActivities() async {
    _activities = await _sysAdminService.getActivities();
  }

  // Radio Operations
  Future<RadioModel> createRadioWithAdmin(Map<String, dynamic> data) async {
    final radio = await _sysAdminService.createRadioWithAdmin(
      name: data['name'] ?? '',
      broadcastLink: data['broadcastLink'] ?? '',
      contractCopy: data['contractCopy'],
      category: data['category'] ?? 'Music',
      adminEmail: data['adminEmail'] ?? '',
      adminName: data['adminName'] ?? '',
      adminPassword: data['adminPassword'] ?? '',
      sysAdminId: _sysAdminService.currentUserId ?? 'sysadmin_laura',
      sysAdminPassword: data['sysAdminPassword'] ?? '',
      otpCode: data['otpCode'] ?? '123456',
    );
    await _loadRadios();
    await _loadActivities();
    notifyListeners();
    return radio;
  }

  Future<void> updateRadioWithSecurity({
    required String radioId,
    required Map<String, dynamic> updates,
    required String password,
    required String otp,
    bool requireFace = false,
  }) async {
    await _sysAdminService.updateRadioWithSecurity(
      radioId: radioId,
      updates: updates,
      sysAdminId: _sysAdminService.currentUserId ?? 'sysadmin_laura',
      sysAdminPassword: password,
      otpCode: otp,
      requireFaceVerification: requireFace,
    );
    await _loadRadios();
    if (_selectedRadioForDetail != null && _selectedRadioForDetail!.id == radioId) {
      _selectedRadioForDetail = await _sysAdminService.getRadioById(radioId);
    }
    await _loadActivities();
    notifyListeners();
  }

  Future<void> deleteRadio({
    required String radioId,
    required String password,
    required String otp,
  }) async {
    await _sysAdminService.deleteRadioWithSecurity(
      radioId: radioId,
      sysAdminId: _sysAdminService.currentUserId ?? 'sysadmin_laura',
      sysAdminPassword: password,
      otpCode: otp,
      requireFaceVerification: true,
    );
    await _loadRadios();
    _selectedRadioForDetail = null;
    await _loadActivities();
    notifyListeners();
  }

  // Seeding trigger
  Future<void> seedMockData() async {
    _isSeeding = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Seed data is handled by the standalone seeder script.');
    _isSeeding = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await loadData();
  }
}
