import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
// Note: We avoid importing non-essential UI code here so the isolate remains light

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'saifi_background_channel', // id
    'Saifi Pay Background Service', // name
    description:
        'This channel is used for important notification monitoring.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart,
  //     autoStart: true,
  //     isForegroundMode: true,
  //     notificationChannelId: 'saifi_background_channel',
  //     initialNotificationTitle: 'Saifi Pay Services',
  //     initialNotificationContent: 'الاستماع للإشعارات في الخلفية...',
  //     foregroundServiceNotificationId: 888,
  //   ),
  //   iosConfiguration: IosConfiguration(
  //     autoStart: true,
  //     onForeground: onStart,
  //     onBackground: onIosBackground,
  //   ),
  // );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // If you need custom local notifications on Android for the messages we receive
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  WebSocketChannel? channel;
  Timer? reconnectTimer;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Function to setup WebSocket
  Future<void> setupWebSocket() async {
    try {
      // Need to read the token. If ApiService uses flutter_secure_storage or shared_preferences, read it here
      String? token;
      try {
        // Assuming shared_preferences is used for token, or secure storage.
        // You will replace this with however you actually store your token.
        // Usually ApiService.getToken() uses SharedPreferences.
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token'); // Or the correct key
        if (token == null) {
          final storage = FlutterSecureStorage();
          token = await storage.read(key: 'auth_token');
        }
      } catch (e) {
        customPrint("Background Service: Failed to read token $e");
      }

      if (token == null || token.isEmpty) {
        customPrint(
          'Background Service: No token found. Stopping WS connection.',
        );
        // Retry later
        reconnectTimer?.cancel();
        reconnectTimer = Timer(const Duration(seconds: 30), setupWebSocket);
        return;
      }

      // Need the base URL. Reconstruct it here since we might not have access to ApiService safely in isolate if it's complex
      // Construct URL using the same ApiService logic
      String baseUrl = ApiService.baseUrl;
      baseUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      final String wsUrl = '${baseUrl}ws/notifications/?token=$token';

      customPrint('Background Service: Connecting to WS: $wsUrl');
      channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      channel!.stream.listen(
        (message) async {
          customPrint('Background Service: Message Received: $message');
          try {
            final data = json.decode(message);
            final action = data['action'] ?? data['type'];

            if (action == 'notification') {
              flutterLocalNotificationsPlugin.show(
                data['id'] ?? DateTime.now().millisecondsSinceEpoch % 100000,
                data['title'] ?? 'إشعار جديد',
                data['message'] ?? '',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'saifi_notifications', // must have a different channel for actual heads-up alerts
                    'Saifi Notifications',
                    importance: Importance.max,
                    priority: Priority.high,
                    ticker: 'ticker',
                  ),
                ),
              );
            }
          } catch (e) {
            customPrint('Background Service parse error: $e');
          }
        },
        onDone: () {
          customPrint('Background Service: WS sequence Closed');
          reconnectTimer?.cancel();
          reconnectTimer = Timer(const Duration(seconds: 30), setupWebSocket);
        },
        onError: (error) {
          customPrint('Background Service: WS Error: $error');
          reconnectTimer?.cancel();
          reconnectTimer = Timer(const Duration(seconds: 30), setupWebSocket);
        },
      );
    } catch (e) {
      customPrint('Background Service: WS Connect Exception: $e');
      reconnectTimer?.cancel();
      reconnectTimer = Timer(const Duration(seconds: 30), setupWebSocket);
    }
  }

  // Initial connection
  setupWebSocket();

  // Bring to foreground
  // Timer.periodic(const Duration(minutes: 15), (timer) async {
  //   if (service is AndroidServiceInstance) {
  //     if (await service.isForegroundService()) {
  //       service.setForegroundNotificationInfo(
  //         title: "Saifi Pay",
  //         content: "التطبيق متصل لتلقي الاشعارات بشكل آمن واستقرار",
  //       );
  //     }
  //   }
  // });
}
