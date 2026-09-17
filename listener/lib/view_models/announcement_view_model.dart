import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/announcement_request.dart';
import '../core/services/announcement_service.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementService _service = AnnouncementService();

  // Form state
  List<AnnouncementTariffEntry> _tariffs = [];
  String? _selectedCategory;
  bool _isCustomCategory = false;
  String _message = '';
  String _originalMessage = '';
  AnnouncementPriority _priority = AnnouncementPriority.standard;
  int _diffusionsPerDay = 1;
  int _days = 1;

  // Computed
  double _baseAmount = 0;
  double _transferFee = 0;
  double _finalPrice = 0;
  int _units = 1;

  // UI state
  bool _loadingTariffs = true;
  bool _enhancing = false;
  bool _submitting = false;
  String? _error;

  // Getters
  List<AnnouncementTariffEntry> get tariffs => _tariffs;
  String? get selectedCategory => _selectedCategory;
  bool get isCustomCategory => _isCustomCategory;
  String get message => _message;
  AnnouncementPriority get priority => _priority;
  int get diffusionsPerDay => _diffusionsPerDay;
  int get days => _days;

  double get baseAmount => _baseAmount;
  double get transferFee => _transferFee;
  double get finalPrice => _finalPrice;
  int get units => _units;

  bool get loadingTariffs => _loadingTariffs;
  bool get enhancing => _enhancing;
  bool get submitting => _submitting;
  String? get error => _error;

  bool get canSubmit =>
      _selectedCategory != null &&
      _message.trim().isNotEmpty &&
      _finalPrice > 0 &&
      !_submitting;

  // ---------- LOAD ----------

  Future<void> loadTariffs(String radioId) async {
    _loadingTariffs = true;
    notifyListeners();
    try {
      _tariffs = await _service.getTariffs(radioId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingTariffs = false;
      notifyListeners();
    }
  }

  // ---------- FORM UPDATES ----------

  void setCategory(String? cat, {bool custom = false}) {
    _selectedCategory = cat;
    _isCustomCategory = custom;
    _recomputePrice();
    notifyListeners();
  }

  void setMessage(String text) {
    if (_originalMessage.isEmpty) {
      // Keep the very first typed version for comparison
      _originalMessage = text;
    }
    _message = text;
    _recomputePrice();
    notifyListeners();
  }

  void setPriority(AnnouncementPriority p) {
    _priority = p;
    notifyListeners();
  }

  void setDiffusionsPerDay(int n) {
    _diffusionsPerDay = n.clamp(1, 10);
    _recomputePrice();
    notifyListeners();
  }

  void setDays(int n) {
    _days = n.clamp(1, 30);
    _recomputePrice();
    notifyListeners();
  }

  void reset() {
    _selectedCategory = null;
    _isCustomCategory = false;
    _message = '';
    _originalMessage = '';
    _priority = AnnouncementPriority.standard;
    _diffusionsPerDay = 1;
    _days = 1;
    _baseAmount = 0;
    _transferFee = 0;
    _finalPrice = 0;
    _units = 1;
    _enhancing = false;
    _submitting = false;
    _error = null;
    notifyListeners();
  }

  // ---------- PRICE ----------

  void _recomputePrice() {
    if (_selectedCategory == null) {
      _baseAmount = 0;
      _transferFee = 0;
      _finalPrice = 0;
      return;
    }

    // Find rate for the selected category
    double rate = 0;
    if (_isCustomCategory) {
      // Custom categories fall back to the "general" rate
      final fallback =
          _tariffs.where((t) => t.category == 'general').toList();
      if (fallback.isNotEmpty) rate = fallback.first.ratePerUnit;
    } else {
      final match =
          _tariffs.where((t) => t.category == _selectedCategory).toList();
      if (match.isNotEmpty) rate = match.first.ratePerUnit;
    }

    if (rate <= 0) {
      _baseAmount = 0;
      _transferFee = 0;
      _finalPrice = 0;
      return;
    }

    // Units from word count — mirrors the backend formula
    final wordCount = _message
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final units = wordCount == 0 ? 1 : (wordCount / (2.5 * 15)).ceil();
    _units = units < 1 ? 1 : units;

    _baseAmount = rate * _units * _diffusionsPerDay * _days;
    _transferFee = _baseAmount * 0.04;
    _finalPrice = _baseAmount + _transferFee;
  }

  // ---------- AI ----------

  Future<String?> enhance() async {
    if (_selectedCategory == null) {
      _error = 'Pick a category first';
      notifyListeners();
      return null;
    }
    if (_message.trim().isEmpty) {
      _error = 'Write a message first';
      notifyListeners();
      return null;
    }

    _enhancing = true;
    notifyListeners();

    try {
      final enhanced = await _service.enhanceText(
        category: _selectedCategory!,
        text: _message,
      );
      _enhancing = false;
      notifyListeners();
      return enhanced;
    } catch (e) {
      _error = e.toString();
      _enhancing = false;
      notifyListeners();
      return null;
    }
  }

  void acceptEnhanced(String text) {
    _message = text;
    _recomputePrice();
    notifyListeners();
  }

  // ---------- SUBMIT ----------

  Future<Map<String, dynamic>?> submit({
    required String radioId,
    required String radioName,
    required String listenerId,
    required String listenerName,
  }) async {
    if (!canSubmit) return null;
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.submitRequest(
        radioId: radioId,
        radioName: radioName,
        listenerId: listenerId,
        listenerName: listenerName,
        category: _selectedCategory!,
        isCustomCategory: _isCustomCategory,
        originalText: _originalMessage,
        finalText: _message.trim(),
        priority: _priority,
        diffusionsPerDay: _diffusionsPerDay,
        days: _days,
      );
      _submitting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _submitting = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------- MY ANNOUNCEMENTS ----------

  StreamSubscription? _mineSub;
  List<AnnouncementRequest> _mine = [];
  List<AnnouncementRequest> get mine => _mine;

  /// Streams the current user's announcements.
  void watchMyAnnouncements(String uid) {
    _mineSub?.cancel();
    _mineSub = FirebaseFirestore.instance
        .collection('announcements')
        .where('listenerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        _mine = snap.docs
            .map((d) => AnnouncementRequest.fromFirestore(d.data(), d.id))
            .toList();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('watchMyAnnouncements stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _mineSub?.cancel();
    super.dispose();
  }
}
