import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/shared_preferences_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/firestore_service.dart';
import 'view_models/language_selection_view_model.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/login_view_model.dart';
import 'view_models/register_view_model.dart';
import 'view_models/main_layout_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/channels_view_model.dart';
import 'view_models/schedule_view_model.dart';
import 'view_models/timetable_view_model.dart';
import 'views/splash_screen.dart';
import 'views/main_layout/main_layout_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final prefsService = SharedPreferencesService(prefs);
  final localizationService = LocalizationService();
  final firestoreService = FirestoreService();

  final savedLanguage = prefsService.getLanguage();
  if (savedLanguage != null) {
    final language = LanguageModel.supportedLanguages.firstWhere(
      (lang) => lang.code == savedLanguage,
      orElse: () => LanguageModel.supportedLanguages.first,
    );
    localizationService.setLocale(language.locale, language: language);
  }

  runApp(MyApp(
    prefsService: prefsService,
    localizationService: localizationService,
    firestoreService: firestoreService,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferencesService prefsService;
  final LocalizationService localizationService;
  final FirestoreService firestoreService;

  const MyApp({
    Key? key,
    required this.prefsService,
    required this.localizationService,
    required this.firestoreService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: prefsService),
        Provider.value(value: localizationService),
        Provider.value(value: firestoreService),
        ChangeNotifierProvider(
          create: (_) => LanguageSelectionViewModel(
            prefsService: prefsService,
            localizationService: localizationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            firestoreService: firestoreService,
            prefsService: prefsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(
            firestoreService: firestoreService,
            prefsService: prefsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterViewModel(
            firestoreService: firestoreService,
            prefsService: prefsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MainLayoutViewModel(
            prefsService: prefsService,
            firestoreService: firestoreService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            firestoreService: firestoreService,
            prefsService: prefsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChannelsViewModel(
            ChannelService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleViewModel(
            ScheduleService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TimetableViewModel(
            TimetableService(),
          ),
        ),
      ],
      child: Consumer<MainLayoutViewModel>(
        builder: (context, viewModel, child) {
          return MaterialApp(
            title: 'Radio Stream',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: viewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: localizationService.currentLocale,
            supportedLocales: LanguageModel.supportedLanguages
                .map((lang) => lang.locale)
                .toList(),
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/auth': (context) => const AuthChoiceScreen(),
              '/home': (context) => const MainLayoutScreen(),
            },
          );
        },
      ),
    );
  }
}
