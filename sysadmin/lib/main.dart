import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/sysadmin_service.dart';
import 'view_models/sysadmin_view_model.dart';
import 'views/sysadmin/sysadmin_login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const SysAdminApp());
}

class SysAdminApp extends StatelessWidget {
  const SysAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SysAdminService>(create: (_) => SysAdminService()),
        ChangeNotifierProvider<SysAdminViewModel>(
          create: (context) => SysAdminViewModel(
            sysAdminService: context.read<SysAdminService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'RadioHub SysAdmin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.primaryLight,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const SysAdminLoginScreen(),
      ),
    );
  }
}
