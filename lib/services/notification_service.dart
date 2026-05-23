import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../main.dart'; // To access navigatorKey
import '../screens/financial_transfers/all_transactions_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------------------------
  // دالة التهيئة (Initialization)
  // ---------------------------------------------------------------------------
  // هذه دالة مسؤولة عن إعداد الإشعارات المحلية.
  // يتم استدعاؤها في بداية تشغيل التطبيق (main.dart).
  static Future<void> init() async {
    if (kIsWeb) return; // لا نقوم بالتهيئة على الويب حالياً

    try {
      // تهيئة الإشعارات المحلية
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // التعامل مع النقر على الإشعارات المحلية
          _navigateToOperations();
        },
      );
    } catch (e) {
      customPrint('فشل تهيئة نظام الإشعارات: $e');
    }
  }

  // مزامنة التوكن يدوياً (تم إيقافه بسبب إلغاء ارتباط Firebase)
  static Future<void> forceSyncToken() async {
    // Disabled
  }

  // الانتقال إلى شاشة سجل العمليات
  static void _navigateToOperations() {
    if (navigatorKey.currentState == null) return;

    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder:
            (context) => const AllTransactionsScreen(
              isDarkMode: false,
            ), // Defaulting to light, themeService handles it if needed
      ),
    );
  }

  // عرض إشعار محلي (يستخدم يدوياً إذا لزم الأمر)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'saifi_channel_id',
          'إشعارات الصيفي',
          channelDescription: 'إشعارات العمليات المالية والتحديثات',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('success'),
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }
}
