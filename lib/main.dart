import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:firebase_core/firebase_core.dart'; // استيراد مكتبة Firebase Core
import 'package:flutter/foundation.dart' show kIsWeb; // Add this
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'core/app_colors.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/session_manager.dart';
import 'services/theme_service.dart';
import 'services/websocket_service.dart';
import 'services/background_service.dart';
import 'dart:async';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Fetch Public Notifications (Broadcasts)
      final publicNotification = await ApiService.getPublicLatestNotification();
      if (publicNotification != null) {
        final int id = publicNotification['id'];
        final String title = publicNotification['title'] ?? '';
        final String message = publicNotification['message'] ?? '';
        final lastSeenPublicId = prefs.getInt('last_broadcast_id') ?? -1;

        if (id > lastSeenPublicId) {
          await NotificationService.init();
          await NotificationService.showNotification(
            id: id + 1234, // Offset for public notifications
            title: title,
            body: message,
          );
          await prefs.setInt('last_broadcast_id', id);
        }
      }

      // 2. Fetch Personalized Notifications (Private)
      final token = prefs.getString('auth_token');
      if (token != null) {
        final privateNotifications = await ApiService.getNotifications();
        if (privateNotifications.isNotEmpty) {
          final lastSeenPrivateId = prefs.getInt('last_private_id') ?? -1;

          for (var n in privateNotifications) {
            final int id = n['id'];
            if (id > lastSeenPrivateId) {
              await NotificationService.init();
              await NotificationService.showNotification(
                id: id,
                title: n['title'] ?? 'إشعار جديد',
                body: n['message'] ?? '',
              );
              // Store the highest ID seen
              if (id > (prefs.getInt('last_private_id') ?? -1)) {
                await prefs.setInt('last_private_id', id);
              }
            }
          }
        }
      }
    } catch (e) {
      customPrint('Background Task Error: $e');
    }
    return Future.value(true);
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Intl.defaultLocale = 'en_US';
  EasyLocalization.logger.enableLevels = [];

  try {
    //منع قلب الشاشة
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // تهيئة Firebase قبل أي خدمة أخرى تعتمد عليه (مثل الإشعارات)
    // ملاحظة: هذا السطر يتطلب وجود ملف google-services.json في مجلد android/app
    //  await Firebase.initializeApp();

    await NotificationService.init();
    await themeService.init();

    // تشغيل خدمة الإشعارات في الخلفية
    if (!kIsWeb) {
      await initializeBackgroundService();
    }

    // تشغيل خدمات الخلفية فقط على الجوال (Android/iOS)
    if (!kIsWeb) {
      // تهيئة Workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

      // تسجيل مهمة دورية كل 15 دقيقة
      await Workmanager().registerPeriodicTask(
        "1",
        "fetchPublicNotifications",
        frequency: const Duration(minutes: 5),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }

    // تشغيل خدمة الـ WebSocket للإشعارات اللحظية (للموبايل والويب)
    webSocketService.connect();
  } catch (e) {
    customPrint('Error initializing services: $e');
  }
  // runApp(const MyApp());
  runApp(
    EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [Locale('en'), Locale('ar')],
      fallbackLocale: const Locale('en'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    //sessionManager.stopSession();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // void _resetInactivityTimer() {
  //   if (ApiService.isAuthenticated) {
  //     sessionManager.startSession();
  //   }
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppInBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppInForeground();
        break;
      default:
        break;
    }
  }

  void _handleAppInBackground() {
    // قم بتنفيذ أي إجراءات تحتاجها عندما يكون التطبيق في الخلفية
    isAppInBackground = true;
    sessionManager.startSession();
    customPrint('التطبيق في الخلفية$isAppInBackground');
  }

  void _handleAppInForeground() {
    // قم بتنفيذ أي إجراءات تحتاجها عندما يكون التطبيق في المقدمة
    // setState(() {
    //   _isAppInBackground = false;
    // });
    sessionManager.stopSession();
    isAppInBackground = false;
    customPrint('التطبيق في المقدمة$isAppInBackground');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'صيفي باي ',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const SplashScreen(),
        );
      },
    );
  }

  // return Listener(
  //     onPointerDown: (_) => _resetInactivityTimer(),
  //     onPointerMove: (_) => _resetInactivityTimer(),
  //     onPointerUp: (_) => _resetInactivityTimer(),
  //     child: MaterialApp(
  //       navigatorKey: navigatorKey,
  //       title: 'صيفي باي ',
  //       debugShowCheckedModeBanner: false,
  //       themeMode: themeService.themeMode,
  //       localizationsDelegates: context.localizationDelegates,
  //       supportedLocales: context.supportedLocales,
  //       locale: context.locale,
  //       theme: _buildLightTheme(),
  //       darkTheme: _buildDarkTheme(),
  //       home: const SplashScreen(),
  //     ),
  //   );

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeService.accentColor,
        primary: AppColors.primaryBlue,
        secondary: themeService.accentColor,
        brightness: Brightness.light,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.cairo().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeService.accentColor,
        primary: AppColors.primaryBlue,
        secondary: themeService.accentColor,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  TextTheme _buildTextTheme() {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      displayMedium: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      displaySmall: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      titleLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
      titleMedium: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
      titleSmall: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
      bodyLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
      bodyMedium: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
      bodySmall: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 10),
      labelLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
      labelMedium: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 10),
      labelSmall: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 8),
    );
  }
}
