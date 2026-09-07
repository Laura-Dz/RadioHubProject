import 'package:flutter/material.dart';
import '../core/models/language_model.dart';
import '../core/services/shared_preferences_service.dart';
import '../core/services/localization_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'base_view_model.dart';

class LanguageSelectionViewModel extends BaseViewModel {
  final SharedPreferencesService _prefsService;
  final LocalizationService _localizationService;

  LanguageModel? _selectedLanguage;
  bool _isLoading = false;

  LanguageSelectionViewModel({
    required SharedPreferencesService prefsService,
    required LocalizationService localizationService,
  })  : _prefsService = prefsService,
        _localizationService = localizationService;

  LanguageModel? get selectedLanguage => _selectedLanguage;
  bool get isLoading => _isLoading;

  List<LanguageModel> get supportedLanguages =>
      LanguageModel.supportedLanguages;

  LanguageModel? get deviceLanguage =>
      _localizationService.detectDeviceLanguage();

  void selectLanguage(LanguageModel language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void setUseDeviceLanguage() {
    final deviceLang = deviceLanguage;
    if (deviceLang != null) {
      _selectedLanguage = deviceLang;
      notifyListeners();
    }
  }

  Future<void> saveLanguageSelection() async {
    if (_selectedLanguage == null) {
      setError('Please select a language');
      return;
    }

    await execute(() async {
      _isLoading = true;
      notifyListeners();

      try {
        await _prefsService.setLanguage(_selectedLanguage!.code);
        await _prefsService.setRegion(_selectedLanguage!.regions.first);
        await _prefsService.setFirstLaunchComplete();

        _localizationService.setLocale(
          _selectedLanguage!.locale,
          language: _selectedLanguage,
        );

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        throw AppException('Failed to save language preference');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  bool isLanguageSelected() => _selectedLanguage != null;
}
