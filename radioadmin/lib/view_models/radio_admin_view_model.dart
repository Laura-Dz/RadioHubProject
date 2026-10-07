import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models/radio_admin/announcement_request_model.dart';
import '../core/models/radio_admin/announcement_tariff_model.dart';
import '../core/models/radio_admin/announcement_slot_model.dart';
import '../core/models/radio_admin/radio_profile_model.dart';
import '../core/models/radio_admin/subscription_model.dart';
import '../core/models/radio_admin/staff_model.dart';
import '../core/models/radio_admin/host_model.dart';
import '../core/models/radio_admin/transaction_model.dart';
import '../core/models/radio_admin/metrics_model.dart';
import '../core/models/radio_admin/recommendation_model.dart';
import '../core/models/radio_admin/media_model.dart';
import '../core/models/radio_admin/session_model.dart';
import '../core/models/radio_admin/program_model.dart';
import '../core/services/radio_admin_service.dart';
import '../core/services/subscription_plan_service.dart';
import '../core/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class RadioAdminViewModel extends ChangeNotifier {
  final RadioAdminService _service;
  final SubscriptionPlanService _planService;
  final StorageService _storageService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _radioId = '';
  String _radioName = '';

  // State
  bool _loading = false;
  bool _loadingInsights = false;
  bool _aiReportRequested = false;
  bool _isAiEligible = true;
  String? _aiIneligibleReason;
  String? _error;

  // Data
  Subscription? _subscription;
  List<StaffMember> _staff = [];
  List<AnnouncementRequest> _pendingAnnouncements = [];
  List<AnnouncementRequest> _scheduledAnnouncements = [];
  List<AnnouncementTariff> _tariffs = [];
  List<RadioTransaction> _transactions = [];
  List<MediaItem> _media = [];
  List<Session> _sessions = [];
  List<Program> _programs = [];
  List<String> _categories = [];
  List<SubscriptionPlan> _plans = [];
  RadioProfile? _radioProfile;
  RadioMetrics _metrics = RadioMetrics.empty();
  String _currentMetricsPeriod = '7d';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  RadioInsights? _insights;
  Map<String, String> _paymentAccounts = {};

  // Streams
  StreamSubscription? _subStream;
  StreamSubscription? _staffStream;
  StreamSubscription? _pendingStream;
  StreamSubscription? _scheduledStream;
  StreamSubscription? _tariffStream;
  StreamSubscription? _txStream;
  StreamSubscription? _mediaStream;
  StreamSubscription? _sessionStream;
  StreamSubscription? _programStream;
  StreamSubscription? _categoryStream;
  StreamSubscription? _profileStream;

  RadioAdminViewModel({
    required RadioAdminService service,
    required SubscriptionPlanService planService,
    StorageService? storageService,
  })  : _service = service,
        _planService = planService,
        _storageService = storageService ?? StorageService();

  // Getters
  String get radioId => _radioId;
  String get radioName => _radioName;
  bool get isLoading => _loading;
  bool get loadingInsights => _loadingInsights;
  bool get aiReportRequested => _aiReportRequested;
  bool get isAiEligible => _isAiEligible;
  String? get aiIneligibleReason => _aiIneligibleReason;
  String? get error => _error;
  Subscription? get subscription => _subscription;
  List<StaffMember> get staff => _staff;
  List<StaffMember> get hosts => _staff.where((s) => s.role == StaffRole.host).toList();
  List<StaffMember> get technicians => _staff.where((s) => s.role == StaffRole.technician).toList();
  List<AnnouncementRequest> get pendingAnnouncements => _pendingAnnouncements;
  List<AnnouncementRequest> get scheduledAnnouncements => _scheduledAnnouncements;
  List<AnnouncementTariff> get tariffs => _tariffs;
  List<RadioTransaction> get transactions => _transactions;
  List<MediaItem> get media => _media;
  List<Session> get sessions => _sessions;
  List<Program> get programs => _programs;
  List<String> get categories => _categories;
  List<SubscriptionPlan> get plans => _plans;
  RadioProfile? get radioProfile => _radioProfile;
  String get broadcastLink => _radioProfile?.broadcastLink ?? '';
  bool get isLive => _radioProfile?.isLive ?? false;
  RadioMetrics get metrics => _metrics;
  String get currentMetricsPeriod => _currentMetricsPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  RadioInsights? get insights => _insights;
  Map<String, String> get paymentAccounts => _paymentAccounts;

  void setCustomDateRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      throw ArgumentError('Start date must be before or equal to end date.');
    }
    final intervalDays = end.difference(start).inDays;
    if (intervalDays > 1826) {
      throw ArgumentError('Date range interval cannot exceed 5 years (maximum 1,826 days).');
    }
    _customStartDate = start;
    _customEndDate = end;
    _currentMetricsPeriod = 'custom';
    notifyListeners();
  }

  void clearCustomDateRange() {
    _customStartDate = null;
    _customEndDate = null;
    notifyListeners();
  }

  void initialize({required String radioId, required String radioName}) {
    _radioId = radioId;
    _radioName = radioName;
    _attachStreams();
    _loadInitialData();
  }

  void _attachStreams() {
    _cancelStreams();
    _subStream = _service.streamSubscription(_radioId).listen((s) {
      _subscription = s;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in subscription stream: $e'));

    _staffStream = _service.streamStaff(_radioId).listen((list) {
      _staff = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in staff stream: $e'));

    _pendingStream = _service.streamPendingAnnouncements(_radioId).listen((list) {
      _pendingAnnouncements = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in pending announcements stream: $e'));

    _scheduledStream = _service.streamScheduledAnnouncements(_radioId).listen((list) {
      _scheduledAnnouncements = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in scheduled announcements stream: $e'));

    _tariffStream = _service.streamTariffs(_radioId).listen((list) {
      _tariffs = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in tariffs stream: $e'));

    _txStream = _service.streamTransactions(_radioId).listen((list) {
      _transactions = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in transactions stream: $e'));

    _mediaStream = _service.streamMedia(_radioId).listen((list) {
      _media = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in media stream: $e'));

    _sessionStream = _service.streamSessions(_radioId).listen((list) {
      _sessions = list;
      loadMetrics(period: _currentMetricsPeriod);
      notifyListeners();
    }, onError: (e) => debugPrint('Error in sessions stream: $e'));

    _programStream = _service.streamPrograms(_radioId).listen((list) {
      _programs = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in programs stream: $e'));

    _categoryStream = _service.streamCategories(_radioId).listen((list) {
      _categories = list;
      notifyListeners();
    }, onError: (e) => debugPrint('Error in categories stream: $e'));

    _profileStream = _service.streamRadioProfile(_radioId, fallbackName: _radioName).listen((p) {
      if (p != null) {
        _radioProfile = p;
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Error in profile stream: $e'));
  }

  Future<void> _loadInitialData() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([
        loadProfile(),
        loadMetrics(),
        loadPlans(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    _radioProfile = await _service.getRadioProfile(_radioId, fallbackName: _radioName);
    notifyListeners();
  }

  Future<void> loadMetrics({
    String period = '7d',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? _customStartDate;
    final end = endDate ?? _customEndDate;
    _currentMetricsPeriod = (start != null && end != null) ? 'custom' : period;
    _metrics = await _service.getMetrics(
      _radioId,
      period: period,
      startDate: start,
      endDate: end,
    );
    notifyListeners();
  }

  Future<void> loadPlans() async {
    try {
      _plans = await _planService.streamPlans().first;
    } catch (_) {
      _plans = _planService.fallbackPlans;
    }
    notifyListeners();
  }

  Future<void> requestAiReport({
    String? timeRange,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? _customStartDate;
    final end = endDate ?? _customEndDate;
    if (start != null && end != null) {
      final intervalDays = end.difference(start).inDays;
      if (intervalDays > 1826) {
        _error = 'Date range interval cannot exceed 5 years (maximum 1,826 days).';
        notifyListeners();
        return;
      }
    }

    _aiReportRequested = true;
    _loadingInsights = true;
    _isAiEligible = true;
    _aiIneligibleReason = null;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.getRadioInsights(
        radioId: _radioId,
        timeRange: timeRange ?? (start != null && end != null ? null : 'last_30_days'),
        startDate: start,
        endDate: end,
      );
      _insights = res;
      _isAiEligible = res.isEligible;
      _aiIneligibleReason = res.ineligibleReason;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingInsights = false;
      notifyListeners();
    }
  }

  Future<void> loadInsights({
    String? timeRange,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      requestAiReport(
        timeRange: timeRange,
        startDate: startDate,
        endDate: endDate,
      );

  Future<List<AnnouncementSlot>> getAvailableSlots({
    required DateTime fromDate,
    required int days,
  }) => _service.getAvailableSlots(radioId: _radioId, fromDate: fromDate, days: days);

  Future<void> validateAnnouncementWithSlots({
    required String id,
    required DateTime scheduledFor,
    required List<AnnouncementSlot> slots,
  }) async {
    await _service.validateAnnouncement(
      announcementId: id,
      adminId: _radioId,
      scheduledFor: scheduledFor,
      assignedSlots: slots,
    );
  }

  Future<void> rejectAnnouncement(String id, String reason) async {
    await _service.rejectAnnouncement(
      announcementId: id,
      adminId: _radioId,
      reason: reason,
    );
  }

  Future<String> generateAnnouncementPDF(String id) async {
    return await _service.generateAnnouncementPDF(id);
  }

  Future<void> markAsPrinted(String id, String pdfUrl) async {
    await _service.markAsPrinted(id, pdfUrl);
  }

  Future<void> updateTariff(AnnouncementTariff tariff) async {
    await _service.upsertTariff(tariff);
  }

  Future<void> deleteTariff(String tariffId) async {
    await _service.deleteTariff(tariffId);
  }

  Future<void> updateRadioProfile(RadioProfile profile) async {
    await _service.updateRadioProfile(_radioId, profile);
    _radioProfile = profile;
    notifyListeners();
  }

  String get _effectiveRadioId {
    if (_radioId.isNotEmpty) return _radioId;
    if (_radioProfile?.id.isNotEmpty == true) return _radioProfile!.id;
    return 'radio_love';
  }

  Future<String> uploadLogo(XFile file, {Function(double progress)? onProgress}) async {
    final targetId = _effectiveRadioId;
    final url = await _storageService.uploadRadioLogo(
      targetId,
      file,
      onProgress: onProgress,
    );
    await _firestore.collection('radios').doc(targetId).set({'logoUrl': url}, SetOptions(merge: true));
    if (_radioProfile != null) {
      _radioProfile = _radioProfile!.copyWith(logoUrl: url);
    } else {
      _radioProfile = RadioProfile(id: targetId, name: _radioName, description: '', logoUrl: url);
    }
    notifyListeners();
    return url;
  }

  Future<void> setLogoUrl(String url) async {
    final targetId = _effectiveRadioId;
    await _firestore.collection('radios').doc(targetId).set({'logoUrl': url}, SetOptions(merge: true));
    if (_radioProfile != null) {
      _radioProfile = _radioProfile!.copyWith(logoUrl: url);
    } else {
      _radioProfile = RadioProfile(id: targetId, name: _radioName, description: '', logoUrl: url);
    }
    notifyListeners();
  }

  Future<String> uploadBanner(XFile file, {Function(double progress)? onProgress}) async {
    final targetId = _effectiveRadioId;
    final url = await _storageService.uploadRadioBanner(
      targetId,
      file,
      onProgress: onProgress,
    );
    await _firestore.collection('radios').doc(targetId).set({'bannerUrl': url}, SetOptions(merge: true));
    if (_radioProfile != null) {
      _radioProfile = _radioProfile!.copyWith(bannerUrl: url);
    } else {
      _radioProfile = RadioProfile(id: targetId, name: _radioName, description: '', bannerUrl: url);
    }
    notifyListeners();
    return url;
  }

  Future<void> setBannerUrl(String url) async {
    final targetId = _effectiveRadioId;
    await _firestore.collection('radios').doc(targetId).set({'bannerUrl': url}, SetOptions(merge: true));
    if (_radioProfile != null) {
      _radioProfile = _radioProfile!.copyWith(bannerUrl: url);
    } else {
      _radioProfile = RadioProfile(id: targetId, name: _radioName, description: '', bannerUrl: url);
    }
    notifyListeners();
  }

  Future<void> removeLogo() async {
    final targetId = _effectiveRadioId;
    final oldUrl = _radioProfile?.logoUrl;
    await _firestore.collection('radios').doc(targetId).update({'logoUrl': FieldValue.delete()});
    if (_radioProfile != null) {
      _radioProfile = RadioProfile(
        id: _radioProfile!.id,
        name: _radioProfile!.name,
        description: _radioProfile!.description,
        function: _radioProfile!.function,
        vision: _radioProfile!.vision,
        mission: _radioProfile!.mission,
        logoUrl: null,
        bannerUrl: _radioProfile!.bannerUrl,
        contactEmail: _radioProfile!.contactEmail,
        contactPhone: _radioProfile!.contactPhone,
        website: _radioProfile!.website,
        location: _radioProfile!.location,
        socialLinks: _radioProfile!.socialLinks,
        tags: _radioProfile!.tags,
        language: _radioProfile!.language,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    if (oldUrl != null) {
      await _storageService.deleteOldFile(oldUrl);
    }
  }

  Future<void> removeBanner() async {
    final targetId = _effectiveRadioId;
    final oldUrl = _radioProfile?.bannerUrl;
    await _firestore.collection('radios').doc(targetId).update({'bannerUrl': FieldValue.delete()});
    if (_radioProfile != null) {
      _radioProfile = RadioProfile(
        id: _radioProfile!.id,
        name: _radioProfile!.name,
        description: _radioProfile!.description,
        function: _radioProfile!.function,
        vision: _radioProfile!.vision,
        mission: _radioProfile!.mission,
        logoUrl: _radioProfile!.logoUrl,
        bannerUrl: null,
        contactEmail: _radioProfile!.contactEmail,
        contactPhone: _radioProfile!.contactPhone,
        website: _radioProfile!.website,
        location: _radioProfile!.location,
        socialLinks: _radioProfile!.socialLinks,
        tags: _radioProfile!.tags,
        language: _radioProfile!.language,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    if (oldUrl != null) {
      await _storageService.deleteOldFile(oldUrl);
    }
  }

  Future<void> uploadMediaItem({
    required XFile file,
    required String title,
    String? description,
    required MediaType mediaType,
    Function(double progress)? onProgress,
  }) async {
    final targetId = _effectiveRadioId;
    final url = await _storageService.uploadMedia(
      targetId,
      file,
      folder: mediaType == MediaType.audio ? 'audio' : 'video',
      onProgress: onProgress,
    );
    final id = 'media_${DateTime.now().millisecondsSinceEpoch}';
    final bytes = await file.readAsBytes();
    final item = MediaItem(
      id: id,
      radioId: targetId,
      title: title,
      description: description,
      mediaType: mediaType,
      url: url,
      fileSizeBytes: bytes.lengthInBytes,
      uploadedBy: 'Radio Admin',
      uploadedAt: DateTime.now(),
    );
    await _firestore.collection('media').doc(id).set(item.toFirestore());
    notifyListeners();
  }

  Future<void> deleteMediaItem(MediaItem item) async {
    await _firestore.collection('media').doc(item.id).delete();
    if (item.url.isNotEmpty) {
      await _storageService.deleteOldFile(item.url);
    }
    notifyListeners();
  }

  Future<String> uploadStaffAvatar(XFile file, {Function(double progress)? onProgress}) async {
    return await _storageService.uploadAvatar(_radioId, file, onProgress: onProgress);
  }

  Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    String? bio,
    required StaffRole role,
    String? photoUrl,
    String? password,
  }) async {
    await _service.createStaff(
      radioId: _radioId,
      radioName: radioProfile?.name ?? '',
      name: name,
      email: email,
      phone: phone,
      bio: bio,
      role: role,
      photoUrl: photoUrl,
      password: password,
    );
  }

  Future<void> createHost(Host host) async {
    await createStaff(
      name: host.name,
      email: host.email,
      phone: host.phone ?? '',
      bio: host.bio,
      role: StaffRole.host,
      photoUrl: host.photoUrl,
    );
  }

  Future<void> updateHost(Host host) async {
    await updateStaff(host.id, {
      'name': host.name,
      'displayName': host.name,
      'phone': host.phone,
      'bio': host.bio,
      'photoUrl': host.photoUrl,
      'isActive': host.isActive,
    });
  }

  Future<void> resetTechnicianPassword({
    required String authUid,
    required String newPassword,
  }) async {
    await _service.resetTechnicianPassword(
      authUid: authUid,
      newPassword: newPassword,
    );
  }

  Future<void> updateStaff(String staffId, Map<String, dynamic> updates) async {
    await _service.updateStaff(staffId, updates);
  }

  Future<void> suspendStaff(String staffId, String reason) async {
    await _service.suspendStaff(staffId, reason);
  }

  Future<void> reactivateStaff(String staffId) async {
    await _service.reactivateStaff(staffId);
  }

  Future<void> paySubscription({
    required SubscriptionPlan plan,
    required String paymentMethod,
    String? paymentAccount,
  }) async {
    await _service.paySubscription(
      radioId: _radioId,
      radioName: _radioName,
      amount: plan.amount,
      days: plan.days,
      planName: plan.label,
      paymentMethod: paymentMethod,
      paymentAccount: paymentAccount,
    );
  }

  Future<void> createProgram(Program p) => _service.createProgram(p);
  Future<void> updateProgram(dynamic idOrProgram, [Map<String, dynamic>? updates]) async {
    if (idOrProgram is Program) {
      await _service.updateProgram(idOrProgram.id, idOrProgram.toFirestore());
    } else if (idOrProgram is String) {
      await _service.updateProgram(idOrProgram, updates ?? {});
    }
  }
  Future<void> archiveProgram(String id) => _service.archiveProgram(id);

  Future<void> createSession(Session s) => _service.createSession(s);
  Future<void> updateSession(Session s) => _service.updateSession(s.id, s.toFirestore());
  Future<void> deleteSession(String id) => _service.deleteSession(id);

  Future<void> loadPaymentAccounts() async {
    try {
      final doc = await _firestore
          .collection('radios')
          .doc(_radioId)
          .collection('settings')
          .doc('paymentAccounts')
          .get();
      if (doc.exists && doc.data() != null) {
        _paymentAccounts = Map<String, String>.from(
          doc.data()!.map((k, v) => MapEntry(k, v.toString())),
        );
      } else {
        _paymentAccounts = {};
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading payment accounts: $e');
    }
  }

  Future<void> savePaymentAccounts(Map<String, String> accounts) async {
    await _firestore
        .collection('radios')
        .doc(_radioId)
        .collection('settings')
        .doc('paymentAccounts')
        .set(accounts);
    _paymentAccounts = accounts;
    notifyListeners();
  }

  Future<void> refreshAll() => _loadInitialData();

  void _cancelStreams() {
    _subStream?.cancel();
    _staffStream?.cancel();
    _pendingStream?.cancel();
    _scheduledStream?.cancel();
    _tariffStream?.cancel();
    _txStream?.cancel();
    _mediaStream?.cancel();
    _sessionStream?.cancel();
    _programStream?.cancel();
    _categoryStream?.cancel();
    _profileStream?.cancel();
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }
}
