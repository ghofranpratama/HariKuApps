import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'pages/home_page.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // Tanpa ini tz.local = UTC, sehingga pengingat meleset 7 jam di WIB.
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
  
  // Request notification permissions for Android 13+
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  
  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
    await androidImplementation.requestExactAlarmsPermission();
  }

  runApp(const HariKuApp());
}

class HariKuApp extends StatefulWidget {
  const HariKuApp({super.key});

  @override
  State<HariKuApp> createState() => _HariKuAppState();
}

class _HariKuAppState extends State<HariKuApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggleTheme() => setState(
      () => _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HariKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      home: HomePage(onToggleTheme: _toggleTheme),
    );
  }
}
