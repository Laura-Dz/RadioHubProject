import 'package:flutter/foundation.dart';
import '../core/models/comment_model.dart';
import '../core/models/call_model.dart';
import '../core/models/show_metrics_model.dart';
import '../core/services/host_service.dart';

class HostViewModel extends ChangeNotifier {
  final HostService _hostService;
  final String programId;

  List<Comment> _comments = [];
  List<Call> _calls = [];
  ShowMetrics _metrics = ShowMetrics.empty();

  Comment? _selectedComment;
  bool _isReplyMode = false;
  bool _isLoading = true;

  HostViewModel({
    required HostService hostService,
    required this.programId,
  }) : _hostService = hostService {
    _listenToComments();
    _listenToCalls();
    _listenToMetrics();
  }

  List<Comment> get comments => _comments;
  List<Call> get calls => _calls;
  ShowMetrics get metrics => _metrics;
  Comment? get selectedComment => _selectedComment;
  bool get isReplyMode => _isReplyMode;
  bool get isLoading => _isLoading;

  void _listenToComments() {
    _hostService.streamComments(programId).listen(
      (comments) {
        _comments = comments;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Comments stream error: $e');
      },
    );
  }

  void _listenToCalls() {
    _hostService.streamCalls(programId).listen(
      (calls) {
        _calls = calls;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Calls stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _listenToMetrics() {
    _hostService.streamMetrics(programId).listen(
      (metrics) {
        _metrics = metrics;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Metrics stream error: $e');
      },
    );
  }

  void startReplyMode(Comment comment) {
    _selectedComment = comment;
    _isReplyMode = true;
    notifyListeners();
  }

  void exitReplyMode() {
    _selectedComment = null;
    _isReplyMode = false;
    notifyListeners();
  }

  Future<void> submitReply(String replyText) async {
    if (replyText.trim().isEmpty || _selectedComment == null) return;
    await _hostService.replyToComment(_selectedComment!.id, replyText.trim());
    exitReplyMode();
  }

  Future<void> acceptCall(Call call) async {
    await _hostService.acceptCall(call.id);
  }

  Future<void> declineCall(Call call) async {
    await _hostService.declineCall(call.id);
  }

  void navigateToAnalytics() {
    // Push to Analytics Dashboard screen
  }

  @override
  void dispose() {
    super.dispose();
  }
}
