import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/sysadmin_service.dart';
import 'view_models/sysadmin_view_model.dart';
import 'views/sysadmin/sysadmin_dashboard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      child: const MaterialApp(
        title: 'SysAdmin Dashboard',
        debugShowCheckedModeBanner: false,
        home: SysAdminDashboard(),
      ),
    );
  }
}
