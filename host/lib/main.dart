import 'core/services/network_time_service.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'view_models/host_view_model.dart';
import 'views/entry/entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NetworkTimeService().sync();
  runApp(const HostApp());
}

class HostApp extends StatelessWidget {
  const HostApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HostViewModel(),
      child: MaterialApp(
        title: 'Host Studio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter',
        ),
        routes: {
          '/': (_) => const EntryScreen(),
        },
      ),
    );
  }
}
