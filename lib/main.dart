import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/level_select_screen.dart';
import 'services/progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ProgressService.instance.load();
  runApp(const RogueTdApp());
}

class RogueTdApp extends StatelessWidget {
  const RogueTdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rogue TD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
      ),
      home: const LevelSelectScreen(),
    );
  }
}
