import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/director_service.dart';
import 'view_models/director_view_model.dart';
import 'views/director/director_dashboard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RadioAdminApp());
}

class RadioAdminApp extends StatelessWidget {
  const RadioAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DirectorService>(create: (_) => DirectorService()),
        ChangeNotifierProvider<DirectorViewModel>(
          create: (context) => DirectorViewModel(
            directorService: context.read<DirectorService>(),
            radioId: 'radio_1',
          ),
        ),
      ],
      child: const MaterialApp(
        title: 'Director Dashboard',
        debugShowCheckedModeBanner: false,
        home: DirectorDashboard(),
      ),
    );
  }
}
