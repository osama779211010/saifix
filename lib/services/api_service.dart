import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'notification_service.dart';
import 'websocket_service.dart';
import 'balance_service.dart';
import '../models/ad_banner.dart';
import '../models/operation_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/app_colors.dart';
import '../main.dart';
import '../widgets/login_dialog.dart';
import '../helper/custom_print_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/remittance_networks.dart';

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = //'https://wallet.alsaifiex.com:7460/';
  //'http://alsaifi.fortiddns.com:7460/';
  //'http://alsaifi.fortiddns.com:7460/'; // إزالة الشرطة المائلة من النهاية لتجنب التكرار
  //'http://10.0.2.2:8000/'; // إزالة الشرطة المائلة من النهاية لتجنب التكرار
  'http://172.16.12.190:8000/'; // إزالة الشرطة المائلة من النهاية لتجنب التكرار
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static String? _token;
  static bool get isAuthenticated => _token != null;
  static DateTime? _lastUserFetch;
  static const Duration _cacheDuration = Duration(seconds: 3);
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static bool _isShowingLoginDialog = false;

  static dynamic handleResponse(
    http.Response response, {
    bool isLogin = false,
  }) async {
    final rawBody = utf8.decode(response.bodyBytes);
    final logBody =
        rawBody.length > 500 ? '${rawBody.substring(0, 500)}...' : rawBody;
    customPrint(
      'API Response : [${response.statusCode}] \n ${response.request?.url}: \n $logBody',
    );

    dynamic data;
    try {
      if (rawBody.isNotEmpty) {
        data = jsonDecode(rawBody);
      }
    } catch (e) {
      customPrint('Failed to decode JSON: $e');
    }

    if (response.statusCode == 401) {
      if (isLogin) {
        // Just throw the message for login attempts
        String errorMsg = 'بيانات الدخول غير صحيحة';
        if (data is Map) {
          errorMsg =
              data['MSG'] ??
              data['msg'] ??
              data['message'] ??
              data['error'] ??
              data['detail'] ??
              errorMsg;
        }
        throw Exception(errorMsg);
      }

      // Session expired
      await logout();
      if (!_isShowingLoginDialog) {
        _isShowingLoginDialog = true;
        final context = navigatorKey.currentContext;
        if (context != null) {
          Future.microtask(() async {
            if (!context.mounted) return;
            await LoginDialog.show(
              context,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            );
            _isShowingLoginDialog = false;
          });
        } else {
          _isShowingLoginDialog = false;
        }
      }
      throw SessionExpiredException('session_expired_message'.tr());
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Handle error status codes
    String errorMsg = 'Error ${response.statusCode}';
    if (data is Map) {
      errorMsg =
          data['MSG'] ??
          data['msg'] ??
          data['message'] ??
          data['error'] ??
          data['detail'] ??
          errorMsg;

      if (data.containsKey('errors') && data['errors'] is Map) {
        final errorsMap = data['errors'] as Map;
        errorMsg = errorsMap.values.map((v) => v.toString()).join('\n');
      } else if (data.values.any((v) => v is List)) {
        errorMsg = data.values.map((v) => v.toString()).join('\n');
      }
    }

    throw Exception(errorMsg);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;

    // 🔐 جلب التوكن من المخزن المشفر (Secure Storage) لضمان أقصى درجات الأمان
    _token = await _storage.read(key: 'auth_token');

    // 🔄 Migration: إذا كان التوكن موجوداً في المخزن القديم (SharedPreferences)، نقله للمشفر ومسحه
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString('auth_token');
      if (oldToken != null) {
        _token = oldToken;
        await _storage.write(key: 'auth_token', value: _token);
        await prefs.remove('auth_token'); // مسح التوكن غير الآمن فوراً
      }
    }

    return _token;
  }

  static bool get isOffline => _token == "offline_session";

  // Future<bool> get isConnected async {
  //     try {
  //       final result = await InternetAddress.lookup('google.com');
  //       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //     } catch (_) {
  //       return false;
  //     }
  //   }
  static Future<bool> isConnected() async {
    try {
      // 📡 حاول الاتصال بسيرفر التطبيق أولاً (استبدل baseUrl بقيمة مشروعك إن وجدت)
      final String urlToCheck =
          (baseUrl.isNotEmpty) ? baseUrl : 'https://www.google.com/';
      final uri = Uri.parse(urlToCheck);

      // إذا استجاب السيرفر بأي كود HTTP (حتى 401 أو 404) نعتبر الاتصال ناجحاً
      // await Future.delayed(const Duration(seconds: 20)); // تأخير بسيط لتحسين تجربة المستخدم
      final response = await http
          .get(uri)
          .timeout(
            const Duration(milliseconds: 15000),
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      customPrint('Connectivity check response code: ${response.statusCode}');
      return response.statusCode >= 100 && response.statusCode < 600;
    } catch (_) {
      // فحص احتياطي عبر DNS إذا فشل الطلب المباشر
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  // static Future<bool> isConnected() async {
  //      try {
  //     final result = await InternetAddress.lookup('google.com');
  //     return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //   } catch (_) {
  //     return false;
  //   }
  //   // try {
  //   //   // 📡 الفحص الفعلي للاتصال بالسيرفر الخاص بالتطبيق بدلاً من Google
  //   //   final uri = Uri.parse(baseUrl);
  //   //   final response =
  //   //       await http.get(uri).timeout(const Duration(seconds: 3));
  //   //   return response.statusCode != 404; // السيرفر استجاب (حتى لو بخطأ 401 أو 404 فهو موجود)
  //   // } catch (_) {
  //   //   // فحص احتياطي عبر DNS إذا فشل الطلب المباشر
  //   //   try {
  //   //     final result = await InternetAddress.lookup('google.com');
  //   //     return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //   //   } catch (_) {
  //   //     return false;
  //   //   }
  //   // }
  // }

  static Future<bool> checkServerStatus() async {
    try {
      final response = await http
          .get(Uri.parse('${baseUrl}api/core/health-check/'))
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    _token = null;

    // 🔐 مسح التوكن من المخزن المشفر بكل أمان
    await _storage.delete(key: 'auth_token');

    // التأكد من مسح أي أثر للتوكن في المخزن القديم أيضاً
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // ملاحظة: نحتفظ بكلمة المرور المشفرة لتمكين تسجيل الدخول السريع بالبصمة
    // ولكن الجلسة الفعلية يتم إنهاؤها بمسح التوكن.
  }

  static Future<Map<String, dynamic>> requestWalletClosure({
    required String reason,
    String? notes,
  }) async {
    final jsonBody = jsonEncode({
      'reason': reason,
      'notes': notes ?? 'أريد حذف حسابي لأسباب أمنية',
    });
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/general/wallet-closure/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $_token',
          },
          body: utf8.encode(jsonBody),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  // طلبات الحسابات الجديد (طلب وكيل، طلب نقطة مبيعات، طلب شركة).
  static Future<Map<String, dynamic>> businessRegister({
    required String fullName,
    required String location,
    String? requestType,
    String? establishmentName,
    String? notes,
  }) async {
    final userName = await getUserName();
    if (userName == null) {
      throw Exception('المستخدم غير معروف. يرجى تسجيل الدخول مرة أخرى.');
    }
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/general/account-requests/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $_token',
          },
          body: utf8.encode(
            jsonEncode({
              "full_name": fullName,
              "request_type": requestType,
              "location": location,
              "establishment_name": establishmentName,
              "notes": notes ?? '',
              "user": userName,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  //تتبع عملية انشاء حساب
  static Future<void> saveRegistrationProgress(
    String phone,
    int step,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}api/general/incomplete-registration/'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: utf8.encode(
              jsonEncode({
                "phone_number": phone,
                "step_reached": step,
                "captured_data": data,
              }),
            ),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      await handleResponse(response);
      customPrint('save register $phone  ====== Step=$step');
    } catch (e) {
      customPrint('Error saving registration progress: $e');
    }

    // if (response.statusCode == 201) {
    //   return jsonDecode(utf8.decode(response.bodyBytes));
    // } else {
    //   customPrint(  'Business registration failed with status ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
    //   throw Exception('فشل إرسال طلب إنشاء حساب اعمال');
    // }
  }

  // --- Hassalaty (Savings) Endpoints ---

  static Future<List<dynamic>> getHassalas() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/hassalaty/'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=utf-8',
      },
    );

    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> createHassala(
    Map<String, dynamic> data,
  ) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/hassalaty/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $_token',
          },
          body: utf8.encode(jsonEncode(data)),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> depositToHassala(
    int id,
    double amount,
  ) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/hassalaty/$id/deposit/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $_token',
          },
          body: utf8.encode(jsonEncode({'amount': amount})),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final result = await handleResponse(response);
    balanceService.refreshBalance();
    return result;
  }

  static Future<Map<String, dynamic>> unlockHassala(int id) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/hassalaty/$id/unlock/'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json; charset=utf-8',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final result = await handleResponse(response);
    balanceService.refreshBalance();
    return result;
  }

  static Future<void> _saveToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();

    if (token != null) {
      // 🔐 تخزين التوكن في المخزن المشفر (Keychain/Keystore)
      await _storage.write(key: 'auth_token', value: token);
      // مسح التوكن القديم من SharedPreferences لضمان النظافة الأمنية
      await prefs.remove('auth_token');
    } else {
      await _storage.delete(key: 'auth_token');
      await prefs.remove('auth_token');
    }
  }

  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🚀 إذا كان هناك حسابات مسجلة مسبقاً، تخطى التعريف فوراً
      if (await hasSavedAccounts()) return false;

      final String? lastShownVersion = prefs.getString(
        'last_onboarding_version',
      );

      // نقوم بإظهار التعريف فقط عند أول تثبيت للتطبيق أو إذا كان الكاش فارغاً تماماً
      return lastShownVersion == null;
    } catch (e) {
      customPrint('DEBUG: Error in shouldShowOnboarding: $e');
      return false;
    }
  }

  static Future<bool> hasSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_accounts_list');
      if (savedJson == null) return false;
      final List<dynamic> decoded = json.decode(savedJson);
      return decoded.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markOnboardingAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      await prefs.setString(
        'last_onboarding_version',
        "${packageInfo.version}+${packageInfo.buildNumber}",
      );
    } catch (_) {}
  }

  static Future<String> getDeviceId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webBrowserInfo = await deviceInfo.webBrowserInfo;
        return webBrowserInfo.userAgent ?? 'web_browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      }
    } catch (_) {}
    return 'unknown_device';
  }

  /*
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      //fast-login
      final deviceId = await getDeviceId();
      final response = await http.post(
        Uri.parse('${baseUrl}api/core/login/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: utf8.encode(jsonEncode({
          'username': username,
          'password': password,
          'mac_address': deviceId,
        })),
      );
      //  customPrint("==================data==================\n==${response.statusCode}==\n===${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        //customPrint("==================data==================\n==$data");
        await _saveToken(data['access']);
        await setUserName(username); // Cache username for offline verification

        // Securely save password for biometric verification
        await _storage.write(key: 'saved_password_$username', value: password);

        // Check if user data is included in login response
        if (data.containsKey('user') && data['user'] != null) {
          final user = Map<String, dynamic>.from(data['user']);
          if (data.containsKey('user_type')) {
            user['user_type'] = data['user_type'];
          }
          if (data.containsKey('force_password_change')) {
            user['force_password_change'] = data['force_password_change'];
          }
          await _saveUser(user);

          await NotificationService.init();
          webSocketService.connect();

          await NotificationService.forceSyncToken();

          return user;
        }

        final user = await getMe();
        await _saveUser(user);

        await NotificationService.init();
        webSocketService.connect();

        return user;
      } else if (response.statusCode == 401) {
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      } else if (response.statusCode == 403) {
        final errData = json.decode(utf8.decode(response.bodyBytes));
        if (errData is Map && errData['code'] == 'DEVICE_BLOCKED') {
          throw Exception('هذا الجهاز موقوف من قبل المستخدم الرئيسي');
        }

        if (errData is Map && errData['code'] == 'NEW_DEVICE_VERIFICATION') {
          final target =
              errData['target_email'] ??
              errData['target_phone'] ??
              'بريدك أو هاتفك';
          throw Exception(
            'تم تسجيل الدخول لحسابك من جهاز اخر قم بالتحقق من بريدك او هاتفك|$target',
          );
        }

        throw Exception('NEW_DEVICE_VERIFICATION');
      } else if (response.statusCode >= 500) {
        throw Exception('حدث خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        String errorMsg = 'فشل تسجيل الدخول (${response.statusCode})';
        try {
          final errData = json.decode(utf8.decode(response.bodyBytes));
          if (errData is Map && errData.containsKey('detail')) {
            errorMsg = errData['detail'];
          } else if (errData is Map && errData.containsKey('error')) {
            errorMsg = errData['error'];
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      customPrint('Error login $e');
      if (e is Exception) rethrow;
      throw Exception('خطأ في الاتصال بالانترنت');
    }
  }
  */

  /// الواجهة الجديدة لتسجيل الدخول السريع (Fast Login)
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
    String userType,
  ) async {
    try {
      final deviceId = await getDeviceId();
      final response = await http
          .post(
            Uri.parse('${baseUrl}api/core/fast-login/'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: utf8.encode(
              jsonEncode({
                'username': username,
                'password': password,
                'user_type': userType,
                'mac_address': deviceId,
              }),
            ),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      final data = await handleResponse(response, isLogin: true);

      await _saveToken(data['access']);
      await setUserName(username);

      // حفظ كلمة المرور للبصمة
      await _storage.write(key: 'saved_password_$username', value: password);

      if (data.containsKey('profile') && data['profile'] != null) {
        final user = Map<String, dynamic>.from(data['profile']);

        // دمج نوع المستخدم ومعلومات نقطة المبيعات
        user['user_type'] = data['user_type'];

        if (user['pos_info'] != null) {
          final posInfo = user['pos_info'] as Map<String, dynamic>;
          user['active_pos_number'] = posInfo['pos_number'];
          user['pos_trade_name'] = posInfo['trade_name'];
        }

        // تحويل full_name إلى first_name و last_name لضمان توافق الشاشات القديمة
        if (user.containsKey('full_name') && user['full_name'] != null) {
          final names = (user['full_name'] as String).split(' ');
          user['first_name'] = names.first;
          user['last_name'] =
              names.length > 1 ? names.sublist(1).join(' ') : '';
        }

        await _saveUser(user);
        await NotificationService.init();
        webSocketService.connect();
        await NotificationService.forceSyncToken();

        return user;
      }

      // في حال عدم وجود البروفايل، نحاول جلب البيانات عبر getMe
      final user = await getMe();
      await _saveUser(user);
      await NotificationService.init();
      webSocketService.connect();
      return user;
    } catch (e) {
      customPrint('Error in fast login: $e');
      // إذا كان الخطأ هو استثناء تم رميه يدوياً (مثل 401 أو 500)، نقوم بإعادة رميه كما هو
      if (e is Exception &&
          !e.toString().contains('SocketException') &&
          !e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('خطأ في الاتصال بالانترنت. يرجى التأكد من توفر الشبكة.');
    }
  }

  static Future<bool> checkUserExists(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}api/core/check-user-exists/?phone_number=$phone'),
      );
      final data = json.decode(utf8.decode(response.bodyBytes));
      customPrint('Check user exists response: $data');
      if (response.statusCode == 200) {
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getDevices() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/core/devices/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  static Future<List<dynamic>> getMapBranches() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/core/map-branches/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  static Future<void> deactivateDevice(int id) async {
    final token = await getToken();
    final response = await http
        .delete(
          Uri.parse('${baseUrl}api/core/devices/$id/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  static Future<void> verifyPassword(String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}api/core/verify-password/'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $_token',
            },
            body: utf8.encode(jsonEncode({'password': password})),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode != 200) {
        // return await handleResponse(response);
        throw Exception('كلمة المرور غير صحيحة');
      }
    } catch (e) {
      throw Exception('فشل التحقق من كلمة المرور: $e');
    }
  }

  //   static Future<void> verifyPassword(String password) async {
  //   try {
  //     // 1. Get current user profile to get the username (phone number)
  //     Map<String, dynamic>? user = await getCachedUser();
  //     if (user == null) {
  //       user = await getMe();
  //     }
  //     final username = user['username'] ?? user['phone_number'];

  //     if (username == null)
  //       throw Exception('تعذر التحقق من المستخدم يرجى تسجيل الدخول مرة أخرى');

  //     // 2. Attempt login with the fetched username and the provided password
  //     // We use a simplified login call or just the same login logic but explicitly for verification
  //     final deviceId = await getDeviceId();
  //     // final token = await getToken();
  //     // final response = await http
  //     //     .post(
  //     //       Uri.parse('${baseUrl}api/core/verify-password/'),
  //     //       headers: {
  //     //         'Content-Type': 'application/json; charset=utf-8',
  //     //         'Authorization': 'Bearer $_token',
  //     //       },
  //     //       body: utf8.encode(jsonEncode({'password': password})),
  //     final response = await http
  //         .post(
  //           Uri.parse('${baseUrl}api/core/fast-login/'),
  //           headers: {'Content-Type': 'application/json; charset=utf-8'},
  //           body: utf8.encode(
  //             jsonEncode({
  //               'username': username,
  //               'password': password,
  //               'mac_address': deviceId,
  //             }),
  //           ),
  //         )
  //         .timeout(
  //           _timeoutDuration,
  //           onTimeout: () {
  //             customPrint('TimeoutException: Future not completed');
  //             throw Exception('انتهى الوقت المسموح للعملية');
  //           },
  //         );

  //     if (response.statusCode != 200) {
  //       // return await handleResponse(response);
  //       throw Exception('كلمة المرور غير صحيحة');
  //     }

  //     // await saveRegistrationProgress(username, 3, {
  //     //   'username': username,
  //     //   'password': password,
  //     //   'mac_address': deviceId,
  //     // });
  //     // We don't need to update token strictly, but refreshing it is fine.
  //   } catch (e) {
  //     throw Exception('فشل التحقق من كلمة المرور: $e');
  //   }
  // }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final deviceId = await getDeviceId();
    final Map<String, dynamic> enrichedData = {...data};
    if (!enrichedData.containsKey('mac_address')) {
      enrichedData['mac_address'] = deviceId;
    }

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/register/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(jsonEncode(enrichedData)),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final resData = await handleResponse(response, isLogin: true);

    // Auto-save token if present
    if (resData['tokens'] != null && resData['tokens']['access'] != null) {
      await _saveToken(resData['tokens']['access']);
    }
    final phone = data['phone_number'].toString();
    //اول خطوة في حفظ السجل
    await saveRegistrationProgress(phone, 1, enrichedData);
    return resData;
  }

  static Future<Map<String, dynamic>> sendEmailOTP(
    String phone,
    String email,
  ) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/send-otp/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(
            jsonEncode({'phone_number': phone, 'email': email}),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response, isLogin: true);
  }

  static Future<Map<String, dynamic>> verifyEmailOTP(
    String phone,
    String email,
    String otp,
  ) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/verify-otp/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(
            jsonEncode({'phone_number': phone, 'email': email, 'otp': otp}),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final resulte = await handleResponse(response, isLogin: true);
    await saveRegistrationProgress(phone, 2, {
      'phone': phone,
      'email': email,
      'otp': otp,
    });
    return resulte;
  }

  static Future<Map<String, dynamic>> getMe({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _lastUserFetch != null &&
          DateTime.now().difference(_lastUserFetch!) < _cacheDuration) {
        final cached = await getCachedUser();
        if (cached != null) return cached;
      }

      final response = await http
          .get(
            Uri.parse('${baseUrl}api/core/me/'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      final data = await handleResponse(response);
      await _saveUser(data); // Cache user data
      _lastUserFetch = DateTime.now();
      return data;
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      final cached = await getCachedUser();
      if (cached != null) return cached;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('انتهت الجلسة');

      final response = await http
          .patch(
            Uri.parse('${baseUrl}api/core/me/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: utf8.encode(jsonEncode(settings)),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      final responseData = await handleResponse(response);
      await _saveUser(responseData); // تحديث الكاش المحلي بالبيانات الجديدة
      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> searchUserByPhone(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${baseUrl}api/core/users/?search=${Uri.encodeComponent(query)}',
            ),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final target = query.replaceAll(RegExp(r'\D'), '');

        // 1. إذا كان البحث بـ 7 أرقام، نتحقق من تطابق wallet_id أولاً
        if (target.length == 7) {
          for (final u in users) {
            if (u['wallet_id'].toString() == target) {
              return u;
            }
          }
        }

        // 2. البحث التقليدي برقم الهاتف (آخر 9 أرقام)
        final last9 =
            target.length > 9 ? target.substring(target.length - 9) : target;

        for (final u in users) {
          final pn = (u['phone_number'] ?? '').toString().replaceAll(
            RegExp('\\D'),
            '',
          );
          final pn9 = pn.length > 9 ? pn.substring(pn.length - 9) : pn;
          if (pn9 == last9) {
            return u;
          }
        }
        if (users.isNotEmpty) return users.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPOSPoint(String posNumber) async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}api/wallets/pos-points/?search=$posNumber'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> points = json.decode(
          utf8.decode(response.bodyBytes),
        );
        for (var p in points) {
          if (p['pos_number'] == posNumber) {
            return p;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getBalances({
    bool forceRefresh = true,
  }) async {
    try {
      customPrint('📡 جلب الأرصدة الحية من السيرفر...');
      final response = await http
          .get(
            Uri.parse('${baseUrl}api/wallets/balance/'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _saveBalances(data); // Cache for offline fallback only
        return data;
      } else {
        return await getCachedBalances();
      }
    } catch (e) {
      return await getCachedBalances();
    }
  }

  static Future<dynamic> get(String path) async {
    try {
      // Ensure path doesn't start with / since baseUrl already ends with it
      if (path.startsWith('/')) {
        path = path.substring(1);
      }

      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        customPrint('API GET Error: ${response.statusCode} for $path');
        return null;
      }
    } catch (e) {
      customPrint('API GET Exception: $e for $path');
      return null;
    }
  }

  static Future<Map<String, dynamic>> submitKYC(
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'لم يتم العثور على صلاحيات الدخول'};
      }

      customPrint('📡 بدء إرسال طلب KYC إلى: $baseUrl/api/core/kyc/requests/');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}api/core/kyc/requests/'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      data.forEach((key, value) {
        if (value != null &&
            !key.contains('path') &&
            !key.contains('image_sim')) {
          request.fields[key] = value.toString();
        }
      });

      // Add images
      // Helper to add files from path or bytes
      Future<void> addFile(
        String fieldName,
        String? pathKey,
        String? bytesKey,
      ) async {
        if (data[bytesKey] != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              data[bytesKey],
              filename: '$fieldName.jpg',
            ),
          );
        } else if (data[pathKey] != null &&
            !data[pathKey].toString().contains('simulated')) {
          if (kIsWeb) {
            // Should have been bytes on Web, but as a fallback/reminder
            customPrint(
              'Warning: MultipartFile.fromPath is not supported on Web.',
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath(fieldName, data[pathKey]),
            );
          }
        }
      }

      await addFile('id_front', 'id_front_path', 'id_front_bytes');
      await addFile('id_back', 'id_back_path', 'id_back_bytes');
      await addFile('selfie', 'selfie_path', 'selfie_bytes');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final result = await handleResponse(response);
      return {'success': true, ...result is Map ? result : {}};
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      customPrint('KYC Submit Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadKYCImages(
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('انتهت الجلسة');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}api/core/kyc/requests/'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // Helper to add files
      Future<void> addFile(
        String fieldName,
        String? pathKey,
        String? bytesKey,
      ) async {
        if (data[bytesKey] != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              data[bytesKey],
              filename: '$fieldName.jpg',
            ),
          );
        } else if (data[pathKey] != null) {
          if (!kIsWeb) {
            request.files.add(
              await http.MultipartFile.fromPath(fieldName, data[pathKey]),
            );
          }
        }
      }

      await addFile('id_front', 'id_front_path', 'id_front_bytes');
      await addFile('id_back', 'id_back_path', 'id_back_bytes');
      await addFile('selfie', 'selfie_path', 'selfie_bytes');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final result = await handleResponse(response);
      return {'success': true, ...result is Map ? result : {}};
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      customPrint('KYC Image Upload Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateKYCData(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('انتهت الجلسة');

      final response = await http.patch(
        Uri.parse('${baseUrl}api/core/kyc/requests/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: utf8.encode(jsonEncode(data)),
      );

      await handleResponse(response);
      return {'success': true};
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      customPrint('KYC Data Update Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getNotifications() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${baseUrl}api/core/notifications/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return await handleResponse(response);
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      return [];
    }
  }

  static Future<void> markNotificationsRead() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http
          .post(
            Uri.parse('${baseUrl}api/core/notifications/mark_all_read/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      await handleResponse(response);
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
    }
  }

  static Future<void> updateFCMToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http
          .post(
            Uri.parse('${baseUrl}api/core/update-fcm-token/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: utf8.encode(jsonEncode({'fcm_token': fcmToken})),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      await handleResponse(response);
      customPrint('FCM Token updated successfully');
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      customPrint('Error updating FCM Token: $e');
    }
  }

  static Future<List<dynamic>> getExchangeRates() async {
    try {
      customPrint('📡 جلب أسعار الصرف من: ${baseUrl}api/wallets/rates/');
      final token = await getToken();

      final response = await http
          .get(
            Uri.parse('${baseUrl}api/wallets/rates/'),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      customPrint(' حالة استجابة أسعار الصرف: ${response.statusCode}');
      customPrint(' محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final rates = json.decode(utf8.decode(response.bodyBytes));
        customPrint(' عدد أسعار الصرف: ${rates.length}');
        return rates;
      }
      customPrint(' فشل جلب أسعار الصرف');
      return [];
    } catch (e) {
      customPrint(' خطأ في getExchangeRates: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> convertCurrency(
    String from,
    String to,
    double amount, {
    String? password,
  }) async {
    try {
      customPrint(' طلب تحويل عملة:');
      customPrint('   من: $from');
      customPrint('   إلى: $to');
      customPrint('   المبلغ: $amount');

      final token = await getToken();
      if (token == null) throw Exception('No Auth Token');

      final requestBody = {
        'from_currency': from,
        'to_currency': to,
        'amount': amount,
        if (password != null) 'password': password,
      };

      customPrint(' البيانات المرسلة: $requestBody');

      final response = await http
          .post(
            Uri.parse('${baseUrl}api/wallets/convert/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: utf8.encode(jsonEncode(requestBody)),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      customPrint(' حالة الاستجابة: ${response.statusCode}');
      customPrint(' محتوى الاستجابة: ${response.body}');

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        customPrint(' تم التحويل بنجاح');
        customPrint(data);
        balanceService.refreshBalance();
        return data;
      } else {
        customPrint(' فشل التحويل: ${data['error']}');
        throw Exception(data['error'] ?? 'فشل التحويل');
      }
    } catch (e) {
      customPrint(' خطأ في convertCurrency: $e');
      if (e.toString().contains('Insufficient funds')) {
        throw Exception('insufficient_funds'); // Specific error for UI
      }
      rethrow;
    }
  }

  static Future<List<dynamic>> getTransactions({
    int limit = 15,
    int offset = 0,
    String? currency,
    String? type,
    String? startDate,
    String? endDate,
    String? query,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return [];

      String queryString = 'limit=$limit&offset=$offset';
      if (currency != null && currency.isNotEmpty) {
        queryString += '&currency=$currency';
      }
      if (type != null && type.isNotEmpty) queryString += '&type=$type';
      if (startDate != null && startDate.isNotEmpty) {
        queryString += '&start_date=$startDate';
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryString += '&end_date=$endDate';
      }
      if (query != null && query.isNotEmpty) {
        queryString += '&search=${Uri.encodeComponent(query)}';
      }

      final response = await http.get(
        Uri.parse('${baseUrl}api/wallets/transactions/?$queryString'),
        headers: {'Authorization': 'Bearer $token'},
      );
      // customPrint('Response Trans ==== ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<OperationHistoryModel?> getOperationsReferenceHistory({
    String? referenceNumber,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('يرجى تسجيل الدخول !!');
      }

      final response = await http
          .get(
            Uri.parse(
              '${baseUrl}api/wallets/operations-history/?reference_number=$referenceNumber',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Handle list response (standard history endpoint)
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            return OperationHistoryModel.fromJson(results.first);
          }
          return null;
        }

        // Handle single object response
        return OperationHistoryModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<OperationHistoryResponse> getOperationsHistory({
    String? username,
    String? operationType,
    String? currency,
    int page = 1,
    int pageSize = 15,
    String? startDate,
    String? endDate,
    String? query,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return OperationHistoryResponse(count: 0, results: []);
      }

      String queryString = 'page=$page&page_size=$pageSize';
      if (username != null && username.isNotEmpty) {
        queryString += '&username=$username';
      }
      if (operationType != null && operationType.isNotEmpty) {
        queryString += '&operation_type=$operationType';
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryString += '&start_date=$startDate';
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryString += '&end_date=$endDate';
      }
      if (query != null && query.isNotEmpty) {
        queryString += '&search=${Uri.encodeComponent(query)}';
      }
      if (currency != null && currency.isNotEmpty) {
        queryString += '&currency=$currency';
      }

      final response = await http
          .get(
            Uri.parse('${baseUrl}api/wallets/operations-history/?$queryString'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return OperationHistoryResponse.fromJson(data);
      } else {
        return OperationHistoryResponse(count: 0, results: []);
      }
    } catch (e) {
      customPrint('Error fetching operations history: $e');
      return OperationHistoryResponse(count: 0, results: []);
    }
  }

  static Future<Map<String, dynamic>> transferP2P(
    String phone,
    String currency,
    double amount, {
    String? description,
    String? password,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('No Auth Token');

      final response = await http
          .post(
            Uri.parse('${baseUrl}api/wallets/transfer-p2p/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: utf8.encode(
              jsonEncode({
                'phone': phone,
                'currency': currency,
                'amount': amount,
                if (description != null) 'description': description,
                if (password != null) 'password': password,
              }),
            ),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        balanceService.refreshBalance();
        return data;
      } else {
        throw Exception(data['error'] ?? 'فشل عملية التحويل');
      }
    } catch (e) {
      if (e.toString().contains('insufficient_funds')) {
        throw Exception('insufficient_funds');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getPublicLatestNotification() async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}api/core/notifications/public-latest/'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        if (body == 'null' || body.trim().isEmpty) return null;
        return json.decode(body);
      }
    } catch (e) {
      customPrint('Error fetching public notification: $e');
    }
    return null;
  }

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('لم يتم العثور على صلاحيات الدخول');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/change-password/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    await handleResponse(response);
    // Update local password cache - need username here
    final user = await getMe();
    final username = user['username'] ?? user['phone_number'];
    if (username != null) {
      await _storage.write(
        key: 'offline_password_$username',
        value: newPassword,
      );
    }
  }

  // --- Remittances API ---

  /// إرسال حوالة جديدة
  static Future<Map<String, dynamic>> sendRemittance(
    Map<String, dynamic> payload, {
    String customEndpoint = 'api/remittances/send/',
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('انتهت الجلسة، يرجى تسجيل الدخول مجدداً');
    }

    customPrint(payload);

    final response = await http
        .post(
          Uri.parse('$baseUrl$customEndpoint'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode(payload)),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final result = await handleResponse(response);
    balanceService.refreshBalance();
    return result;
  }

  /// الاستعلام عن حوالة (قبل الصرف)
  static Future<Map<String, dynamic>> queryRemittance(
    String remittanceNumber,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .get(
          Uri.parse('${baseUrl}api/remittances/receive/$remittanceNumber/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    return await handleResponse(response);
  }

  /// استلام (صرف) حوالة
  static Future<Map<String, dynamic>> receiveRemittance(
    String remittanceNumber,
    Map<String, dynamic> payoutData,
    String password, {
    File? idImage,
    String operationId = '',
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl}api/remittances/receive/$remittanceNumber/'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Add fields
    payoutData.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (operationId.isNotEmpty) {
      request.fields['operation_id'] = operationId;
    }

    request.fields['password'] = password;

    // Add file
    if (idImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'id_image', // Assuming the field name is id_image
          idImage.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final result = await handleResponse(response);
    balanceService.refreshBalance();
    return result;
  }

  /// الاستعلام عن حوالة صيفي كاش
  static Future<Map<String, dynamic>> receiveSaifiCashEnquiry(
    String saifiRmtNo,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/SaifiCash/wallet/receive-enquiry/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode({'saifi_rmt_no': saifiRmtNo})),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final data = json.decode(utf8.decode(response.bodyBytes));
    customPrint('receiveSaifiCashEnquiry response: $data');
    if (response.statusCode == 200 || data['status'] == 'success') {
      return data;
    } else {
      throw Exception(
        data['message'] ?? data['error_detail'] ?? 'فشل الاستعلام عن الحوالة',
      );
    }
  }

  /// الاستعلام عن حالة حوالة صيفي كاش (مستلمة أم لا)
  static Future<Map<String, dynamic>> enquireSaifiCashStatus(
    String rmtNo,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/SaifiCash/wallet/enquire-status/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode({'rmt_no': rmtNo})),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final data = json.decode(utf8.decode(response.bodyBytes));
    customPrint('enquireSaifiCashStatus response: $data');
    if (response.statusCode == 200 || data['status'] == 'success') {
      return data;
    } else {
      throw Exception(
        data['message'] ?? data['error'] ?? 'فشل الاستعلام عن حالة الحوالة',
      );
    }
  }

  /// تأكيد استلام حوالة صيفي كاش
  static Future<Map<String, dynamic>> confirmSaifiCashReceipt(
    String saifiRmtNo,
    String rcvRqstNo,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/SaifiCash/wallet/confirm-receipt/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({'saifi_rmt_no': saifiRmtNo, 'rcv_rqst_no': rcvRqstNo}),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 || data['status'] == 'success') {
      balanceService.refreshBalance();
      return data;
    } else {
      throw Exception(
        data['message'] ?? data['error_detail'] ?? 'فشل تأكيد استلام الحوالة',
      );
    }
  }

  /// حساب العمولة والعمولة
  static Future<Map<String, dynamic>> calculateFee(
    double amount,
    String currency,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/remittances/calculate-fee/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({'amount': amount, 'currency': currency}),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'فشل حساب العمولة');
    }
  }

  /// التحقق من كلمة مرور العمليات
  static Future<bool> verifyOperationPassword(String password) async {
    // If in offline session, verify against stored password
    if (_token == "offline_session") {
      final storedPassword = await _storage.read(key: 'offline_password');
      return password == storedPassword;
    }

    if (password.isEmpty) return false;

    try {
      await verifyPassword(password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// تعديل بيانات الحوالة
  static Future<Map<String, dynamic>> updateRemittance(
    String remittanceNumber,
    Map<String, dynamic> payload,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .patch(
          Uri.parse('${baseUrl}api/remittances/update/$remittanceNumber/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode(payload)),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'فشل تعديل الحوالة');
    }
  }

  /// إلغاء الحوالة
  static Future<Map<String, dynamic>> cancelRemittance(
    String remittanceNumber,
    String password, {
    String operationId = '',
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/remittances/cancel/$remittanceNumber/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({'password': password, 'operation_id': operationId}),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      balanceService.refreshBalance();
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'فشل إلغاء الحوالة');
    }
  }

  /// إيداع رصيد لعميل (للأدمن/الوكلاء)
  static Future<Map<String, dynamic>> fundUser(
    Map<String, dynamic> payload,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/wallets/admin/fund-user/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode(payload)),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 || response.statusCode == 201) {
      balanceService.refreshBalance();
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل عملية الإيداع');
    }
  }

  /// بدء عملية سحب رصيد (Initiate Withdrawal)
  static Future<Map<String, dynamic>> initiateWithdrawal(
    String phoneNumber,
    double amount,
    String currency,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/financials/withdraw/agent/initiate/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({
              'phone_number': phoneNumber,
              'amount': amount,
              'currency': currency,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل بدء عملية السحب');
    }
  }

  /// إكمال عملية سحب رصيد بـ OTP (Complete Withdrawal)
  static Future<Map<String, dynamic>> completeWithdrawal(
    String withdrawalId,
    String otpCode,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/financials/withdraw/agent/complete/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({'withdrawal_id': withdrawalId, 'otp_code': otpCode}),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      balanceService.refreshBalance();
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'كود التحقق غير صحيحة أو منتهي');
    }
  }

  /// البحث عن بيانات الفرع بواسطة رقم النقطة (POS Number)
  static Future<Map<String, dynamic>> getBranchInfoByPOS(
    String posNumber,
  ) async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse(
            '${baseUrl}api/financials/withdraw/customer/branch-info/?pos_number=$posNumber',
          ),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'الفرع غير موجود');
    }
  }

  /// بدء طلب سحب صيفي (بواسطة العميل)
  static Future<Map<String, dynamic>> initiateCustomerWithdrawal(
    String posNumber,
    double amount,
    String currency,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/financials/withdraw/customer/initiate/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(
            jsonEncode({
              'pos_number': posNumber,
              'amount': amount,
              'currency': currency,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل طلب السحب');
    }
  }

  // --- Caching Logic ---

  static Future<void> setUserName(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_username', username);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cached_username');
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    if (user.containsKey('error')) return;
    final prefs = await SharedPreferences.getInstance();
    final username = user['username'] ?? user['phone_number'];

    if (username != null) {
      await prefs.setString('cached_user_$username', jsonEncode(user));
    }

    await prefs.setString(
      'cached_user_${user['id'] ?? 'default'}',
      jsonEncode(user),
    );
    await prefs.setString('last_cached_user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('last_cached_user');
    if (data != null) return jsonDecode(data);
    return null;
  }

  static Future<void> _saveBalances(Map<String, dynamic> balances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_balances', jsonEncode(balances));
    // Update balanceService globally
    balanceService.updateBalances(balances);
  }

  static Future<Map<String, dynamic>> getCachedBalances() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_balances');
    if (data != null) return jsonDecode(data);
    return {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};
  }

  static Future<Map<String, dynamic>> offlineLogin(
    String username,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('cached_user_$username');

    if (userData != null) {
      final user = jsonDecode(userData);
      final cachedUsername = user['username'] ?? user['phone_number'];
      if (cachedUsername.toString() == username) {
        // Verify password offline - user-specific password key
        final storedPassword = await _storage.read(
          key: 'saved_password_$username',
        );
        if (password == storedPassword) {
          _token = "offline_session";
          return user;
        } else {
          throw Exception('كلمة المرور غير صحيحة للدخول بدون إنترنت');
        }
      }
    }
    throw Exception(
      'لا توجد بيانات مخزنة لهذا المستخدم للحصول على دخول بدون إنترنت',
    );
  }

  static Future<List<AdBanner>> getAdBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_ad_banners');

    // 1. Return cached data immediately if available
    List<AdBanner> banners = [];
    if (cachedData != null) {
      try {
        final List<dynamic> data = json.decode(cachedData);
        banners = data.map((json) => AdBanner.fromJson(json)).toList();
        // return banners;
      } catch (e) {
        customPrint('Error parsing cached banners: $e');
      }
    }

    // 2. Fetch fresh data in the background or if cache is empty
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}api/core/ad-banners/'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );
      if (response.statusCode == 200) {
        customPrint(
          '======Ad banners fetched successfully====== \n : ${response.body}',
        );
        final decodedBody = utf8.decode(response.bodyBytes);
        await prefs.setString('cached_ad_banners', decodedBody);

        final List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => AdBanner.fromJson(json)).toList();
      }
    } catch (e) {
      customPrint('Error fetching ad banners from network: $e');
    }

    return banners; // Return cached banners if network fetch failed
  }

  /// يتحقق مما إذا كان حساب المستخدم موثقاً أم لا
  /// ويظهر رسالة تنبيه إذا كان غير موثق
  static Future<bool> checkVerification(
    BuildContext context, {
    required bool isDarkMode,
    Function? onVerifyNavigate,
  }) async {
    final user = await getCachedUser();

    // إذا لم تتوفر بيانات، نفترض أنه موثق مؤقتاً لترك السيرفر يقرر أو نتحقق لاحقاً
    if (user == null) return true;

    final bool isVerified =
        user['is_verified'] ?? user['is_confirmed'] ?? false;
    if (isVerified) return true;

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'توثيق الحساب مطلوب',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                'عذراً، لا يمكنك إجراء هذه العملية لأن حسابك غير موثق حالياً. يرجى إكمال عملية التوثيق لتتمكن من استخدام كافة ميزات التطبيق.',
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (onVerifyNavigate != null) {
                      onVerifyNavigate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'وثق حسابك الآن',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
      );
    }
    return false;
  }

  static Future<List<RemittanceNetwork>> getRemittanceNetworks(
    String lang,
  ) async {
    try {
      // final token = await getToken();
      final response = await http
          .get(
            Uri.parse('${baseUrl}api/settings/remittance-networks/'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              customPrint('TimeoutException: Future not completed');
              throw Exception('انتهى الوقت المسموح للعملية');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        customPrint("=============================================");
        customPrint("networks data: $data");
        customPrint("=============================================");

        // final String lang =
        //     (intl.Intl.getCurrentLocale().startsWith('ar')) ? 'ar' : 'en';

        List<RemittanceNetwork> networks =
            data.map((json) => RemittanceNetwork.fromJson(json, lang)).toList();

        // Sort to ensure Saifi Cash/Pay are at the top if present
        networks.sort((a, b) {
          final codeA = a.networkCode.toUpperCase();
          final codeB = b.networkCode.toUpperCase();

          bool isSaifiA =
              codeA.contains('SAIFI') ||
              codeA.contains('CASH') ||
              codeA.contains('PAY');
          bool isSaifiB =
              codeB.contains('SAIFI') ||
              codeB.contains('CASH') ||
              codeB.contains('PAY');

          if (isSaifiA && !isSaifiB) return -1;
          if (!isSaifiA && isSaifiB) return 1;

          return a.sortOrder.compareTo(b.sortOrder);
        });

        return networks;
      }
      return [];
    } catch (e) {
      customPrint('DEBUG: Error fetching remittance networks: $e');
      return [];
    }
  }

  static Future<bool> verifyDeviceOTP(
    String phone,
    String otp,
    String macAddress,
  ) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/verify-device-otp/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(
            json.encode({
              'phone': phone,
              'otp': otp,
              'mac_address': macAddress,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    return response.statusCode == 200;
  }

  // --- External Remittance Receipt Requests APIs ---

  static Future<Map<String, dynamic>> submitReceiptRequest(
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    final response = await http
        .post(
          Uri.parse('${baseUrl}api/remittances/receipt-requests/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode(data)),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return responseData;
    } else {
      if (responseData is Map && responseData.containsKey('error')) {
        throw Exception(responseData['error']);
      }

      // Handle the form validation errors
      if (responseData is Map) {
        final firstKey = responseData.keys.first;
        final firstError = responseData[firstKey];
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError[0]);
        }
        throw Exception(firstError.toString());
      }

      throw Exception('فشل إرسال الطلب');
    }
  }

  static Future<List<Map<String, dynamic>>> getMyReceiptRequests({
    String? statusFilter,
    String? dateFilter,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('انتهت الجلسة');

    String url = '${baseUrl}api/remittances/receipt-requests/my/';
    final queryParams = <String>[];
    if (statusFilter != null && statusFilter.isNotEmpty) {
      queryParams.add('status=$statusFilter');
    }
    if (dateFilter != null && dateFilter.isNotEmpty) {
      queryParams.add('requested_at=$dateFilter');
    }
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      customPrint(data);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('فشل في جلب قائمة الطلبات');
    }
  }

  // static Future<List<Map<String, dynamic>>> getMyReceiptRequests({
  //   String? statusFilter,
  // }) async {
  //   final token = await getToken();
  //   if (token == null) throw Exception('انتهت الجلسة');

  //   String url = '${baseUrl}api/remittances/receipt-requests/my/';
  //   if (statusFilter != null && statusFilter.isNotEmpty) {
  //     url += '?status=$statusFilter';
  //   }

  //   final response = await http.get(
  //     Uri.parse(url),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json; charset=utf-8',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
  //     return List<Map<String, dynamic>>.from(data);
  //   } else {
  //     throw Exception('فشل في جلب قائمة الطلبات');
  //   }
  // }

  // --- Forgot Password APIs ---

  static Future<Map<String, dynamic>> forgotPasswordVerify({
    required String username,
    required String phone,
    required String idNumber,
    required String dob,
  }) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/forgot-password/verify/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(
            json.encode({
              'username': username,
              'phone_number': phone,
              'id_number': idNumber,
              'dob': dob,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل التحقق من البيانات');
    }
  }

  static Future<Map<String, dynamic>> forgotPasswordReset({
    required String username,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/core/forgot-password/reset/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: utf8.encode(json.encode({'username': username, 'otp': otp})),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل إعادة تعيين كلمة المرور');
    }
  }

  static Future<List<dynamic>> getPendingCollections() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/wallets/collections/pending/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<List<dynamic>> getMyCollections() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/wallets/collections/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<Map<String, dynamic>> createGroupCollection(
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();

    // تأكد من أن المبالغ أرقام نظيفة
    final Map<String, dynamic> cleanData = {
      ...data,
      "total_amount": (data["total_amount"] as num).round(),
      "members":
          (data["members"] as List)
              .map(
                (m) => {
                  "phone_number": m["phone_number"],
                  "amount": (m["amount"] as num).round(),
                },
              )
              .toList(),
    };

    final response = await http.post(
      Uri.parse('${baseUrl}api/wallets/collections/create/'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
      body: utf8.encode(json.encode(cleanData)),
    );

    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return responseData;
    } else {
      // طباعة الخطأ في الكونسول للمساعدة في تشخيص 400
      customPrint('PocketMoney Create Error: ${response.body}');
      throw Exception(
        responseData['error'] ??
            responseData['message'] ??
            responseData['detail'] ??
            'فشل إنشاء الطلب',
      );
    }
  }

  static Future<Map<String, dynamic>> respondToCollection(
    int memberId,
    String action,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${baseUrl}api/wallets/collections/$memberId/respond/'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
      body: utf8.encode(json.encode({'action': action})),
    );
    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(
        responseData['error'] ??
            responseData['message'] ??
            'فشل الرد على الطلب',
      );
    }
  }

  static Future<Map<String, dynamic>> getCollectionStatus(
    int collectionId,
  ) async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/wallets/collections/$collectionId/status/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('فشل جلب حالة الطلب');
    }
  }

  // --- الأسرة (جيب الأسرة) ---

  static Future<Map<String, dynamic>> createSubWallet({
    required String firstName,
    required String secondName,
    required String thirdName,
    required String lastName,
    required String phone,
    required String birthDate,
    required String relationship,
    required String gender,
  }) async {
    final token = await getToken();
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/wallets/family/create/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          body: utf8.encode(
            jsonEncode({
              'first_name': firstName,
              'second_name': secondName,
              'third_name': thirdName,
              'last_name': lastName,
              'phone_number': phone,
              'birth_date': birthDate,
              'relationship_type': relationship,
              'gender': gender,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل إنشاء حساب التابع');
    }
  }

  static Future<Map<String, dynamic>> verifySubWalletOTP(
    String phone,
    String otp,
    String relationship,
  ) async {
    final token = await getToken();
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/wallets/family/verify/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          body: utf8.encode(
            jsonEncode({
              'phone_number': phone,
              'otp': otp,
              'relationship_type': relationship,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل التحقق من الرمز');
    }
  }

  static Future<List<dynamic>> fetchFamilyMembers() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/wallets/family/list-members/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('فشل جلب أفراد الأسرة');
    }
  }

  static Future<List<dynamic>> getFamilyRelationships() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('${baseUrl}api/wallets/family/relationships/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('فشل جلب خيارات صلة القرابة');
    }
  }

  static Future<Map<String, dynamic>> fundSubWallet(
    int subUserId,
    double amount,
    String currency,
  ) async {
    final token = await getToken();
    final response = await http
        .post(
          Uri.parse('${baseUrl}api/wallets/family/fund/'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          body: utf8.encode(
            jsonEncode({
              'sub_user_id': subUserId,
              'amount': amount,
              'currency': currency,
            }),
          ),
        )
        .timeout(
          _timeoutDuration,
          onTimeout: () {
            customPrint('TimeoutException: Future not completed');
            throw Exception('انتهى الوقت المسموح للعملية');
          },
        );
    final responseData = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      balanceService.refreshBalance();
      return responseData;
    } else {
      throw Exception(responseData['error'] ?? 'فشل تغذية الحساب');
    }
  }
}
