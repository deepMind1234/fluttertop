import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:window_manager/window_manager.dart';

import 'domain/services/system_monitor_service.dart';
import 'presentation/theme/theme_manager.dart';
import 'presentation/dashboard/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager(prefs)),
        Provider<SystemMonitorService>(
          create: (_) =>
              SystemMonitorService()..start(const Duration(milliseconds: 1000)),
          dispose: (_, service) => service.stop(),
        ),
      ],
      child: const FlutterTopApp(),
    ),
  );
}

class FlutterTopApp extends StatelessWidget {
  const FlutterTopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return MaterialApp(
      title: 'FlutterTop',
      debugShowCheckedModeBanner: false,
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeManager.themeMode,
      home: const DashboardView(),
    );
  }
}
