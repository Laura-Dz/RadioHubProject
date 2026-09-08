import 'package:flutter/material.dart';
import '../core/enums/view_state.dart';

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _errorMessage != null;

  void setState(ViewState state) {
    _state = state;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == ViewState.error) {
      _state = ViewState.idle;
    }
    notifyListeners();
  }

  Future<void> execute(Future<void> Function() action) async {
    try {
      setState(ViewState.loading);
      clearError();
      await action();
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
      setState(ViewState.error);
    }
  }
}
