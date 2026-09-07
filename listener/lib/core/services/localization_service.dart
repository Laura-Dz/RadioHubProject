import 'package:flutter/material.dart';
import '../models/language_model.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Locale _currentLocale = const Locale('en', 'US');
  LanguageModel? _currentLanguage;

  Locale get currentLocale => _currentLocale;
  LanguageModel? get currentLanguage => _currentLanguage;

  void setLocale(Locale locale, {LanguageModel? language}) {
    _currentLocale = locale;
    _currentLanguage = language;
  }

  bool isRTL() => _currentLanguage?.isRTL ?? false;

  String translate(String key, {Map<String, String>? params}) {
    return key;
  }

  LanguageModel? detectDeviceLanguage() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locales.first;
    return LanguageModel.supportedLanguages.firstWhere(
      (lang) => lang.code == deviceLocale.languageCode,
      orElse: () => LanguageModel.supportedLanguages.first,
    );
  }
}
