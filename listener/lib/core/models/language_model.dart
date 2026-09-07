import 'package:flutter/material.dart';

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final Locale locale;
  final bool isRTL;
  final List<String> regions;
  final int priority;

  LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.locale,
    required this.isRTL,
    required this.regions,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'nativeName': nativeName,
    'flag': flag,
    'locale': locale.toString(),
    'isRTL': isRTL,
    'regions': regions,
    'priority': priority,
  };

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    final localeParts = json['locale'].toString().split('_');
    return LanguageModel(
      code: json['code'],
      name: json['name'],
      nativeName: json['nativeName'],
      flag: json['flag'],
      locale: Locale(localeParts[0], localeParts.length > 1 ? localeParts[1] : null),
      isRTL: json['isRTL'] ?? false,
      regions: List<String>.from(json['regions'] ?? []),
      priority: json['priority'] ?? 999,
    );
  }

  static final List<LanguageModel> supportedLanguages = [
    LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
      locale: const Locale('en', 'US'),
      isRTL: false,
      regions: ['US', 'UK', 'AU', 'CA'],
      priority: 1,
    ),
    LanguageModel(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      locale: const Locale('es', 'ES'),
      isRTL: false,
      regions: ['ES', 'MX', 'AR', 'CO'],
      priority: 2,
    ),
    LanguageModel(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      locale: const Locale('fr', 'FR'),
      isRTL: false,
      regions: ['FR', 'CA', 'BE', 'CH'],
      priority: 3,
    ),
    LanguageModel(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      locale: const Locale('de', 'DE'),
      isRTL: false,
      regions: ['DE', 'AT', 'CH'],
      priority: 4,
    ),
    LanguageModel(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇦🇪',
      locale: const Locale('ar', 'SA'),
      isRTL: true,
      regions: ['SA', 'AE', 'EG', 'KW'],
      priority: 5,
    ),
  ];
}
