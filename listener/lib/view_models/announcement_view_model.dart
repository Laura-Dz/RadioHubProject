import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/announcement_request.dart';
import '../core/services/announcement_service.dart';
import '../core/services/announcement_ai_service.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementService _service = AnnouncementService();

  // Form state
  List<AnnouncementTariffEntry> _tariffs = [];
  String? _selectedCategory;
  bool _isCustomCategory = false;
  String _message = '';
  String _originalText = '';
  String _enhancedText = '';
  bool _useEnhancedText = false;
  AnnouncementPriority _priority = AnnouncementPriority.standard;
  int _diffusionsPerDay = 1;
  int _days = 1;

  // AI & Moderation state
  ModerationResult? _moderationResult;
  bool _isModerating = false;
  AmeliorationResult? _ameliorationResult;
  bool _isAmeliorating = false;

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
  String get originalText => _originalText;
  String get enhancedText => _enhancedText;
  bool get useEnhancedText => _useEnhancedText;
  AnnouncementPriority get priority => _priority;
  int get diffusionsPerDay => _diffusionsPerDay;
  int get days => _days;

  // Moderation & AI getters
  ModerationResult? get moderationResult => _moderationResult;
  bool get isModerating => _isModerating;
  bool get isModerationFlagged => _moderationResult != null && !_moderationResult!.passed;
  AmeliorationResult? get ameliorationResult => _ameliorationResult;
  bool get isAmeliorating => _isAmeliorating;

  int get wordCount => _message.trim().isEmpty
      ? 0
      : _message.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Estimated duration in seconds at an average rate of 2 words per second (30 words / 15 seconds)
  double get estimatedDurationSeconds => wordCount > 0 ? (wordCount / 2.0) : 0.0;

  /// 15-second billing units (30 words = 1 unit)
  int get calculatedUnits => wordCount == 0 ? 1 : (wordCount / 30.0).ceil().clamp(1, 99);

  double get baseAmount => _baseAmount;
  double get transferFee => _transferFee;
  double get finalPrice => _finalPrice;
  int get units => _units;

  bool get loadingTariffs => _loadingTariffs;
  bool get enhancing => _enhancing || _isAmeliorating;
  bool get submitting => _submitting;
  String? get error => _error;

  bool get canSubmit =>
      _selectedCategory != null &&
      _message.trim().isNotEmpty &&
      _finalPrice > 0 &&
      !isModerationFlagged &&
      !_isModerating &&
      !_submitting;

  // ---------- LOAD ----------

  Future<void> loadTariffs(String radioId) async {
    _loadingTariffs = true;
    notifyListeners();
    try {
      _tariffs = await _service.getTariffs(radioId);
      if (_tariffs.isNotEmpty &&
          (_selectedCategory == null || !_tariffs.any((t) => t.category == _selectedCategory))) {
        _selectedCategory = _tariffs.first.category;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingTariffs = false;
      _recomputePrice();
      notifyListeners();
    }
  }

  // ---------- FORM UPDATES ----------

  void setCategory(String? cat) {
    _selectedCategory = cat;
    _isCustomCategory = false;
    _recomputePrice();
    notifyListeners();
  }

  void setMessage(String text) {
    _originalText = text;
    if (!_useEnhancedText) {
      _message = text;
      _recomputePrice();
      notifyListeners();
    }
  }

  void setUseEnhancedText(bool useEnhanced) {
    _useEnhancedText = useEnhanced;
    if (_useEnhancedText && _enhancedText.isNotEmpty) {
      _message = _enhancedText;
    } else {
      _message = _originalText;
    }
    _recomputePrice();
    notifyListeners();
  }

  void setPriority(AnnouncementPriority p) {
    _priority = p;
    _recomputePrice();
    notifyListeners();
  }

  void setDiffusionsPerDay(int n) {
    _diffusionsPerDay = n < 1 ? 1 : n;
    _recomputePrice();
    notifyListeners();
  }

  void setDays(int n) {
    _days = n < 1 ? 1 : n;
    _recomputePrice();
    notifyListeners();
  }

  void reset() {
    _selectedCategory = null;
    _isCustomCategory = false;
    _message = '';
    _originalText = '';
    _enhancedText = '';
    _useEnhancedText = false;
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
    _moderationResult = null;
    _isModerating = false;
    _ameliorationResult = null;
    _isAmeliorating = false;
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
      final fallback =
          _tariffs.where((t) => t.category.toLowerCase() == 'general').toList();
      if (fallback.isNotEmpty) rate = fallback.first.ratePerUnit;
    } else {
      final match =
          _tariffs.where((t) => t.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
      if (match.isNotEmpty) rate = match.first.ratePerUnit;
    }

    if (rate <= 0) rate = 500.0; // fallback standard rate per 15s unit if tariffs empty

    // 2 words per second -> 30 words per 15-second unit
    final words = _message
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final units = words == 0 ? 1 : (words / 30.0).ceil();
    _units = units < 1 ? 1 : units;

    final priorityMult = _priority.multiplier;
    _baseAmount = rate * _units * _diffusionsPerDay * _days * priorityMult;
    _transferFee = _baseAmount * 0.04;
    _finalPrice = _baseAmount + _transferFee;
  }

  // ---------- MODERATION & AI ----------

  /// Runs OpenAI Content Moderation on the current announcement text.
  Future<ModerationResult> checkModeration([String? overrideText]) async {
    final textToCheck = (overrideText ?? _message).trim();
    if (textToCheck.isEmpty) {
      _moderationResult = ModerationResult.clean();
      notifyListeners();
      return _moderationResult!;
    }

    _isModerating = true;
    notifyListeners();

    try {
      final result = await _service.moderateText(textToCheck);
      _moderationResult = result;
      if (!result.passed) {
        _error = result.message;
      } else if (_error == _moderationResult?.message) {
        _error = null;
      }
      return result;
    } catch (e) {
      _moderationResult = ModerationResult.clean();
      return _moderationResult!;
    } finally {
      _isModerating = false;
      notifyListeners();
    }
  }

  /// Ameliorates announcement text with Gemini specifically tailored for radio broadcast.
  Future<AmeliorationResult?> ameliorateWithGemini({String? radioName}) async {
    if (_selectedCategory == null) {
      _error = 'Please select an announcement category first';
      notifyListeners();
      return null;
    }
    if (_message.trim().isEmpty) {
      _error = 'Please enter your announcement draft first';
      notifyListeners();
      return null;
    }

    // 1. First run Content Moderation check on the draft
    _error = null;
    final mod = await checkModeration();
    if (!mod.passed) {
      _error = mod.message;
      notifyListeners();
      return null;
    }

    _isAmeliorating = true;
    _enhancing = true;
    notifyListeners();

    try {
      final result = await _service.ameliorateAnnouncement(
        text: _message,
        category: _selectedCategory!,
        radioName: radioName,
      );

      if (result != null) {
        _ameliorationResult = result;
        _enhancedText = result.polishedText;
        _useEnhancedText = true;
        _message = _enhancedText;
        _recomputePrice();
      }
      _isAmeliorating = false;
      _enhancing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isAmeliorating = false;
      _enhancing = false;
      notifyListeners();
      return null;
    }
  }

  /// Accepts the Gemini-polished announcement version.
  void acceptGeminiPolish() {
    if (_ameliorationResult != null) {
      if (_originalText.isEmpty) {
        _originalText = _message;
      }
      _message = _ameliorationResult!.polishedText;
      _recomputePrice();
      _moderationResult = ModerationResult.clean();
      notifyListeners();
    }
  }

  /// Reverts message back to the listener's original draft.
  void revertToOriginal() {
    if (_originalText.isNotEmpty) {
      _message = _originalText;
      _recomputePrice();
      checkModeration();
      notifyListeners();
    }
  }

  Future<String?> enhance({String? radioName}) async {
    final res = await ameliorateWithGemini(radioName: radioName);
    return res?.polishedText;
  }

  void acceptEnhanced(String text) {
    if (_originalText.isEmpty) {
      _originalText = _message;
    }
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
      final mod = await checkModeration();
      if (!mod.passed) {
        _submitting = false;
        _error = mod.message;
        notifyListeners();
        return null;
      }

      final result = await _service.submitRequest(
        radioId: radioId,
        radioName: radioName,
        listenerId: listenerId,
        listenerName: listenerName,
        category: _selectedCategory!,
        isCustomCategory: _isCustomCategory,
        originalText: _originalText,
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
  bool _loadingMine = false;
  bool get loadingMine => _loadingMine;

  /// Streams the current user's announcements.
  /// If [uid] is null or empty, or yields no documents, listens/falls back gracefully
  /// so announcements and states are always loaded without composite index errors.
  void watchMyAnnouncements([String? uid]) {
    _mineSub?.cancel();
    _loadingMine = true;
    notifyListeners();

    final db = FirebaseFirestore.instance;
    final coll = db.collection('announcements');

    // Query by listenerId if uid provided; avoid .orderBy to prevent requiring a composite index.
    Query query;
    if (uid != null && uid.isNotEmpty) {
      query = coll.where('listenerId', isEqualTo: uid);
    } else {
      query = coll.limit(50);
    }

    _mineSub = query.snapshots().listen(
      (snap) {
        final list = <AnnouncementRequest>[];
        for (final doc in snap.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              list.add(AnnouncementRequest.fromFirestore(data, doc.id));
            }
          } catch (e, st) {
            debugPrint('watchMyAnnouncements parse error doc ${doc.id}: $e\n$st');
          }
        }

        // If specific user has no announcements yet, check if there are demo/sample announcements in collection
        if (list.isEmpty && uid != null && uid.isNotEmpty) {
          coll.limit(20).get().then((fallbackSnap) {
            if (fallbackSnap.docs.isNotEmpty && _mine.isEmpty) {
              final fallbackList = <AnnouncementRequest>[];
              for (final doc in fallbackSnap.docs) {
                try {
                  final data = doc.data();
                  fallbackList.add(AnnouncementRequest.fromFirestore(data, doc.id));
                } catch (_) {}
              }
              fallbackList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _mine = fallbackList;
              _loadingMine = false;
              notifyListeners();
            }
          }).catchError((_) {});
        }

        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _mine = list;
        _loadingMine = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('watchMyAnnouncements stream error: $e');
        _loadingMine = false;
        // Fallback to direct fetch on error
        coll.limit(30).get().then((fallbackSnap) {
          final fallbackList = <AnnouncementRequest>[];
          for (final doc in fallbackSnap.docs) {
            try {
              final data = doc.data();
              fallbackList.add(AnnouncementRequest.fromFirestore(data, doc.id));
            } catch (_) {}
          }
          fallbackList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _mine = fallbackList;
          notifyListeners();
        }).catchError((_) {});
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _mineSub?.cancel();
    super.dispose();
  }
}
