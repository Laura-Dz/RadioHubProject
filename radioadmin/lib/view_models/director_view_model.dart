import '../core/models/director/technician_model.dart';
import '../core/models/director/subscription_model.dart';
import '../core/models/director/homepage_config_model.dart';
import '../core/models/director/request_model.dart';
import '../core/models/director/metric_model.dart';
import '../core/services/director_service.dart';
import '../core/enums/view_state.dart';
import 'base_view_model.dart';

class DirectorViewModel extends BaseViewModel {
  final DirectorService _directorService;
  final String radioId;

  List<Technician> _technicians = [];
  List<Subscription> _subscriptions = [];
  HomepageConfig? _homepageConfig;
  List<Request> _requests = [];
  DirectorMetrics? _metrics;

  bool _isLoading = true;
  int _selectedTab = 0;
  RequestStatus? _requestFilter;
  RequestType? _requestTypeFilter;

  DirectorViewModel({
    required DirectorService directorService,
    required this.radioId,
  }) : _directorService = directorService {
    _loadData();
  }

  List<Technician> get technicians => _technicians;
  List<Subscription> get subscriptions => _subscriptions;
  HomepageConfig? get homepageConfig => _homepageConfig;
  List<Request> get requests => _requests;
  DirectorMetrics? get metrics => _metrics;
  @override
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
        _loadTechnicians(),
        _loadSubscriptions(),
        _loadHomepageConfig(),
        _loadRequests(),
        _loadMetrics(),
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

  Future<void> _loadTechnicians() async {
    _technicians = await _directorService.getTechnicians();
  }

  Future<void> _loadSubscriptions() async {
    _subscriptions = await _directorService.getSubscriptions();
  }

  Future<void> _loadHomepageConfig() async {
    _homepageConfig = await _directorService.getHomepageConfig(radioId);
  }

  Future<void> _loadRequests() async {
    _requests = await _directorService.getRequests();
  }

  Future<void> _loadMetrics() async {
    _metrics = await _directorService.getMetrics(radioId);
  }

  Future<void> addTechnician(Technician technician) async {
    await _directorService.addTechnician(technician);
    await _loadTechnicians();
  }

  Future<void> updateTechnician(String id, Map<String, dynamic> data) async {
    await _directorService.updateTechnician(id, data);
    await _loadTechnicians();
  }

  Future<void> deleteTechnician(String id) async {
    await _directorService.deleteTechnician(id);
    await _loadTechnicians();
  }

  Future<void> suspendTechnician(String id) async {
    await _directorService.suspendTechnician(id);
    await _loadTechnicians();
  }

  Future<void> activateTechnician(String id) async {
    await _directorService.activateTechnician(id);
    await _loadTechnicians();
  }

  Future<void> createSubscription(Subscription subscription) async {
    await _directorService.createSubscription(subscription);
    await _loadSubscriptions();
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    await _directorService.updateSubscription(id, data);
    await _loadSubscriptions();
  }

  Future<void> saveHomepageConfig(HomepageConfig config) async {
    await _directorService.saveHomepageConfig(config);
    await _loadHomepageConfig();
  }

  Future<void> updateHomepageConfigSection(String id, Map<String, dynamic> data) async {
    if (_homepageConfig == null) return;
    final updatedSections = _homepageConfig!.sections.map((s) {
      if (s.id == id) {
        return HomepageSection(
          id: s.id,
          type: data['type'] ?? s.type,
          title: data['title'] ?? s.title,
          subtitle: data['subtitle'] ?? s.subtitle,
          isVisible: data['isVisible'] ?? s.isVisible,
          displayOrder: data['displayOrder'] ?? s.displayOrder,
          config: data['config'] ?? s.config,
        );
      }
      return s;
    }).toList();

    final updatedConfig = HomepageConfig(
      id: _homepageConfig!.id,
      radioId: _homepageConfig!.radioId,
      sections: updatedSections,
      theme: data['theme'] ?? _homepageConfig!.theme,
      bannerImageUrl: data['bannerImageUrl'] ?? _homepageConfig!.bannerImageUrl,
      logoUrl: data['logoUrl'] ?? _homepageConfig!.logoUrl,
      isActive: data['isActive'] ?? _homepageConfig!.isActive,
      updatedAt: DateTime.now(),
    );
    await saveHomepageConfig(updatedConfig);
  }

  Future<void> approveRequest(String id, {String? adminResponse}) async {
    await _directorService.approveRequest(id, adminResponse: adminResponse);
    await _loadRequests();
  }

  Future<void> rejectRequest(String id, {required String adminResponse}) async {
    await _directorService.rejectRequest(id, adminResponse: adminResponse);
    await _loadRequests();
  }

  Future<void> markRequestInProgress(String id) async {
    await _directorService.markRequestInProgress(id);
    await _loadRequests();
  }

  Future<void> completeRequest(String id) async {
    await _directorService.completeRequest(id);
    await _loadRequests();
  }

  void setRequestFilter(RequestStatus? status) {
    _requestFilter = status;
    notifyListeners();
  }

  void setRequestTypeFilter(RequestType? type) {
    _requestTypeFilter = type;
    notifyListeners();
  }

  List<Request> getFilteredRequests() {
    return _requests.where((r) {
      if (_requestFilter != null && r.status != _requestFilter) return false;
      if (_requestTypeFilter != null && r.type != _requestTypeFilter) return false;
      return true;
    }).toList();
  }

  Future<void> refreshMetrics() async {
    await _loadMetrics();
  }

  Future<void> refreshData() async {
    await _loadData();
  }
}
