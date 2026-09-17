import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/services/shared_preferences_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/radio_service.dart';
import 'core/services/schedule_service.dart';
import 'core/services/channel_service.dart';
import 'core/services/timetable_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/metadata_service.dart';
import 'core/services/user_interaction_service.dart';
import 'core/services/realtime_database_service.dart';
import 'core/models/language_model.dart';
import 'view_models/language_selection_view_model.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/login_view_model.dart';
import 'view_models/register_view_model.dart';
import 'view_models/main_layout_view_model.dart';
import 'view_models/home_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_models/channels_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/schedule_view_model.dart';
import 'view_models/timetable_view_model.dart';
import 'view_models/radio_station_view_model.dart';
import 'views/splash_screen.dart';
import 'views/main_layout/main_layout_screen.dart';
import 'views/radio_station/radio_station_page.dart';
import 'view_models/user_interaction_view_model.dart';
import 'views/notifications/notification_center.dart';
import 'views/auth/auth_choice_screen.dart';

import 'core/services/announcement_service.dart';
import 'view_models/announcement_view_model.dart';

import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();
  final prefsService = SharedPreferencesService(prefs);
  final localizationService = LocalizationService();
  final firestoreService = FirestoreService();
  final storageService = StorageService();
  final metadataService = MetadataService();
  final realtimeDbService = RealtimeDatabaseService();
  final userInteractionService = UserInteractionService();

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
    storageService: storageService,
             metadataService: metadataService,
    realtimeDbService: realtimeDbService,
    userInteractionService: userInteractionService,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferencesService prefsService;
  final LocalizationService localizationService;
  final FirestoreService firestoreService;
  final StorageService storageService;
  final MetadataService metadataService;
  final RealtimeDatabaseService realtimeDbService;
  final UserInteractionService userInteractionService;

  const MyApp({
    Key? key,
    required this.prefsService,
    required this.localizationService,
    required this.firestoreService,
    required this.storageService,
    required this.metadataService,
    required this.realtimeDbService,
    required this.userInteractionService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: prefsService),

        Provider.value(value: localizationService),
        Provider.value(value: firestoreService),
        Provider.value(value: storageService),
        Provider.value(value: metadataService),
        Provider.value(value: realtimeDbService),
        Provider.value(value: userInteractionService),
        Provider(create: (_) => AnnouncementService()),

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
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChannelsViewModel()
            ..attach(FirebaseAuth.instance.currentUser?.uid ?? ''),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel()..attach(),
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
        ChangeNotifierProvider(
          create: (_) => RadioStationViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),
        ChangeNotifierProxyProvider<FirestoreService, UserInteractionViewModel>(
          create: (context) => UserInteractionViewModel(
            interactionService: userInteractionService,
            userId: firestoreService.getCurrentUserId() ?? 'guest',
          ),
          update: (context, fs, _) => UserInteractionViewModel(
            interactionService: userInteractionService,
            userId: fs.getCurrentUserId() ?? 'guest',
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
               '/notifications': (context) => const NotificationCenter(),
            },
          );
        },
      ),
    );
  }
}
