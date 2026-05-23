import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../locations_view_screen.dart';
import '../../components/error_dialog.dart';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import '../../core/app_colors.dart';
import '../home_screen.dart';
import 'register_screen.dart';

import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import 'dart:async';
import 'dart:convert'; // Added for JSON
import '../pos_home_screen.dart';
import 'otp_verification_screen.dart';
import 'forgot_password_verify_screen.dart';
import '../password_setup_screen.dart';

import '../../helper/custom_print_helper.dart';

class LoginScreen extends StatefulWidget {
  final bool showRegisterOnInit;
  const LoginScreen({super.key, this.showRegisterOnInit = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FocusNodes for auto-navigation
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // State Variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _loggedInFullName = "";
  double _headerHeight = 0.33;
  bool _canAuthenticateWithBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  String? _savedUsername;
  Timer? _publicNotificationTimer;
  int _lastPublicNotificationId = -1;
  // Account Switching
  List<Map<String, dynamic>> _savedAccounts = [];
  Map<String, dynamic>? _selectedAccount;
  // bool _isOfflineMode = false;  // DISABLED: Offline login temporarily disabled

  // Security Locks
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  bool _hasAutoPrompted = false; // Added to track auto-prompt state

  // Biometric Authentication
  late final LocalAuthentication _localAuth;

  // Connectivity Monitoring
  bool _isInternetAvailable = true;
  final bool _isConnecting = false;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Listen for text changes to update biometric icon
    _phoneController.addListener(_checkBiometricsForCurrentUser);
    _usernameController.addListener(_checkBiometricsForCurrentUser);

    // تهيئة البصمة
    _localAuth = LocalAuthentication();
    _initializeBiometrics();

    // Initialize with animation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _animateHeader();
      _startPublicNotificationPolling();
      _startConnectivityCheck();
      await _loadSavedAccounts();

      // تأخير بسيط لضمان استقرار الواجهة وتعبئة الحقول قبل طلب البصمة
      await Future.delayed(const Duration(milliseconds: 500));

      // Re-check biometrics now that accounts are loaded and fields auto-filled
      await _checkBiometricsForCurrentUser(autoPrompt: true);
      if (!mounted) return;

      if (widget.showRegisterOnInit) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterScreen(isDarkMode: false),
          ),
        );
      }
    });
  }

  void _startConnectivityCheck() {
    _checkConnectivity(showDialog: false);
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isConnecting) {
        _checkConnectivity(showDialog: false);
      }
    });
  }

  Future<void> _checkConnectivity({bool showDialog = false}) async {
    final available = await ApiService.isConnected();

    if (mounted && available != _isInternetAvailable) {
      setState(() {
        _isInternetAvailable = available;
        // OFFLINE LOGIN DISABLED: No offline mode activation
        // if (!_isInternetAvailable) {
        //   _isOfflineMode = true;
        //   if (showDialog) _showOfflineOptions();
        // }
      });
    }
    return;
  }

  /* DISABLED: Offline login options
  void _showOfflineOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  "network_error".tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "error_network_try_again".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      // DISABLED: Offline login button
                      // child: OutlinedButton(
                      //   onPressed: () {
                      //     Navigator.pop(context);
                      //     setState(() => _isOfflineMode = true);
                      //   },
                      //   style: OutlinedButton.styleFrom(
                      //     padding: const EdgeInsets.symmetric(vertical: 12),
                      //     side: const BorderSide(color: AppColors.primaryBlue),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //   ),
                      //   child: Text('login_offline'.tr()),
                      // ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _manualRetryConnection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('try_again'.tr()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }
  */ // END DISABLED _showOfflineOptions

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('saved_accounts_list');
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = json.decode(savedJson);
        if (mounted) {
          setState(() {
            _savedAccounts =
                decoded.map((e) => Map<String, dynamic>.from(e)).toList();

            // Auto-fill form with the last logged-in account (first in list usually)
            if (_savedAccounts.isNotEmpty) {
              _selectedAccount = _savedAccounts.first;
              if (_selectedAccount != null &&
                  _selectedAccount!['type'] == '0') {
                _phoneController.text = _selectedAccount!['username'] ?? '';
              } else if (_selectedAccount != null) {
                // Determine logic for POS autologin if needed
                _usernameController.text = _selectedAccount!['username'] ?? '';
              }
            }
          });
        }
      } catch (e) {
        customPrint('Error loading accounts: $e');
      }
    }
  }

  Future<void> _saveAccount(String username, String name, String type) async {
    final account = {
      'username': username,
      'name': name,
      'type': type,
      'last_login': DateTime.now().toIso8601String(),
    };

    // Remove existing if present to move to top
    _savedAccounts.removeWhere((a) => a['username'] == username);
    _savedAccounts.insert(0, account);

    // Keep only last 5
    if (_savedAccounts.length > 5) {
      _savedAccounts = _savedAccounts.sublist(0, 5);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_accounts_list', json.encode(_savedAccounts));
  }

  void _startPublicNotificationPolling() {
    // التحقق فوراً عند الفتح
    _checkPublicNotification();
    // التحقق كل دقيقة
    _publicNotificationTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) {
      _checkPublicNotification();
    });
  }

  Future<void> _checkPublicNotification() async {
    final notification = await ApiService.getPublicLatestNotification();
    if (notification != null) {
      final int id = notification['id'];
      final String title = notification['title'] ?? '';
      final String message = notification['message'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      final lastSeenId = prefs.getInt('last_broadcast_id') ?? -1;

      if (id == _lastPublicNotificationId) return;

      if (id > lastSeenId) {
        // عرض التنبيه
        NotificationService.showNotification(
          id: id,
          title: title,
          body: message,
        );
        // تحديث المعرف لمنع التكرار
        await prefs.setInt('last_broadcast_id', id);
        _lastPublicNotificationId = id;
      }
    }
  }

  Future<void> _checkBiometricsForCurrentUser({bool autoPrompt = false}) async {
    try {
      final username = _getCurrentUsername();
      if (username.isEmpty) {
        setState(() => _canAuthenticateWithBiometrics = false);
        return;
      }

      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      final prefs = await SharedPreferences.getInstance();
      final biosEnabled =
          prefs.getBool('biometrics_enabled_$username') ?? false;
      final hasSavedCreds = await _storage.containsKey(
        key: 'saved_password_$username',
      );

      if (mounted) {
        setState(() {
          _canAuthenticateWithBiometrics =
              isSupported && canCheck && biosEnabled && hasSavedCreds;
          _availableBiometrics = availableBiometrics;
          _savedUsername = biosEnabled ? username : null;
        });

        // Auto-prompt if allowed and not yet prompted for this session/user
        if (autoPrompt &&
            _canAuthenticateWithBiometrics &&
            !_hasAutoPrompted &&
            !widget.showRegisterOnInit) {
          _hasAutoPrompted = true;
          _handleBiometricAuth();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _canAuthenticateWithBiometrics = false);
      }
    }
  }

  String _getCurrentUsername() {
    return _tabController.index == 0
        ? _phoneController.text
        : _usernameController.text;
  }

  // دالة تهيئة البصمة والتحقق من توفرها
  Future<void> _initializeBiometrics() async {
    // This is the initial check for device support
    await _checkBiometricsForCurrentUser();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _publicNotificationTimer?.cancel();
    _lockoutTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {});
    _animateTabChange();
    _checkBiometricsForCurrentUser();
  }

  void _animateHeader() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _headerHeight = 0.28);
      }
    });
  }

  void _animateTabChange() {}

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = 30;
    });

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_lockoutSeconds > 0) {
          _lockoutSeconds--;
        } else {
          _isLockedOut = false;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+967778555555';
    // Try native app first
    final nativeUrl = Uri.parse('whatsapp://send?phone=$phone');
    // Fallback to web link using api.whatsapp.com which is more reliable than wa.me
    final webUrl = Uri.parse(
      'https://api.whatsapp.com/send?phone=${phone.replaceAll('+', '')}',
    );

    try {
      if (await canLaunchUrl(nativeUrl)) {
        await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('whatsapp_not_installed'.tr())),
          );
        }
      }
    } catch (e) {
      customPrint('Error launching WhatsApp: $e');
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('unable_to_open_whatsapp'.tr())),
          );
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;

    if (_isLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${"please_wait".tr()} $_lockoutSeconds ${"second_try_again".tr()}',
          ),
          backgroundColor: AppColors.accentBlue,
        ),
      );
      return;
    }

    final username =
        _tabController.index == 0
            ? _phoneController.text
            : _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_enter_the_required_data'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    // فحص إضافي للتأكد من وصول السيرفر قبل المحاولة
    // if (_tabController.index == 0 || _tabController.index == 1) {
    //   final isOnline = await ApiService.isConnected();
    //   if (!isOnline) {
    //     setState(() => _isLoading = false);
    //     _showErrorDialog(
    //       'network_error'.tr(),
    //       'خطأ في الاتصال بالانترنت. يرجى التأكد من توفر الانترنت أو المحاولة لاحقاً.',
    //     );
    //     return;
    //   }
    // }

    try {
      final Map<String, dynamic> userData;
      userData = await ApiService.login(
        username,
        password,
        _tabController.index == 0 ? 'phone_number' : 'pos_point',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('تحقق من الانترنت'),
      );

      // Store password for biometric use in the future
      //final storage = FlutterSecureStorage();
      await _storage.write(key: 'user_password', value: password);

      // Request notification permissions after successful login
      // await NotificationService.init();

      if (!mounted) return;

      final String? posNumber =
          userData['active_pos_number']
              ?.toString(); //?? _usernameController.text;
      final bool returnedAsPOS = posNumber != null && posNumber.isNotEmpty;
      final bool onSubscriberTab = _tabController.index == 0;
      final bool onPOSTab = _tabController.index == 1;

      // حالة 1: المستخدم في تبويب المشترك لكن السيرفر وجد نقطة مبيعات
      if (onSubscriberTab && returnedAsPOS) {
        setState(() => _isLoading = false);
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text('Log_in_as_a_point_of_sale'.tr()),
                content: Text(
                  ' "$username" ${"it_is_a_point_of_sale_number".tr()}.\n${"do_you_want_Log_in_as_a_point_of_sale".tr()}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('cancel'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      '${"confirm".tr()}، ${"Log_in_as_a_point_of_sale".tr()}',
                    ),
                  ),
                ],
              ),
        );
        if (confirm == true && mounted) {
          _tabController.animateTo(1);
          _usernameController.text = username;
          await _doNavigate(userData, posMode: true);
        }
        return;
      }

      // حالة 2: المستخدم في تبويب نقطة المبيعات لكن لا يوجد رقم نقطة
      if (onPOSTab && !returnedAsPOS) {
        setState(() => _isLoading = false);
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text('log_in_as_a_subscriber'.tr()),
                content: Text(
                  '"$username" ${"it_is_a_joint_account".tr()}.\n${"do_you_want_log_in_as_a_subscriber".tr()}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('cancel'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      '${"confirm".tr()}، ${"enter_in_as_a_subscriber".tr()}',
                    ),
                  ),
                ],
              ),
        );
        if (confirm == true && mounted) {
          _tabController.animateTo(0);
          _phoneController.text = username;
          await _doNavigate(userData, posMode: false);
        }
        return;
      }

      await _doNavigate(userData, posMode: onPOSTab || returnedAsPOS);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        final errorStr = e.toString();

        if (errorStr.contains('NEW_DEVICE_VERIFICATION')) {
          String? target;
          if (errorStr.contains('|')) {
            target = errorStr.split('|').last;
          }

          // الانتقال لشاشة التحقق عند اكتشاف جهاز جديد
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OTPVerificationScreen(
                    isDarkMode: themeService.isDarkModeActive(context),
                    phoneNumber: username,
                    isDeviceVerification: true,
                    verificationTarget: target,
                  ),
            ),
          );
          return;
        }

        setState(() {
          _failedAttempts++;
          if (_failedAttempts >= 3) {
            _startLockout();
          }
        });

        if (_isLockedOut) {
          _showErrorDialog('locked_out_title'.tr(), 'locked_out_message'.tr());
        } else {
          // تبسيط رسالة الخطأ للمستخدم
          String displayError = errorStr.replaceAll('Exception:', '').trim();

          // إخفاء تفاصيل السيرفر في حال خطأ الشبكة
          if (displayError.contains('SocketException') ||
              displayError.contains('HttpException') ||
              displayError.contains('Connection failed') ||
              displayError.contains('timeout')) {
            displayError =
                'خطأ في الاتصال بالانترنت. يرجى التأكد من توفر الانترنت أو المحاولة لاحقاً.';
          }

          _showErrorDialog('login_failed'.tr(), displayError);
        }
      }
    }
  }

  Future<void> _doNavigate(
    Map<String, dynamic> userData, {
    required bool posMode,
  }) async {
    if (!mounted) return;

    final username =
        _tabController.index == 0
            ? _phoneController.text
            : _usernameController.text;
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      if (posMode) {
        // Show trade name for POS login
        final tradeName = userData['pos_trade_name']?.toString() ?? '';
        _loggedInFullName =
            tradeName.isNotEmpty
                ? tradeName
                : (userData['username'] ?? '').toString();
      } else {
        final first = (userData['first_name'] ?? '').toString().trim();
        final last = (userData['last_name'] ?? '').toString().trim();
        _loggedInFullName = "$first $last".trim();
        if (_loggedInFullName.isEmpty) {
          _loggedInFullName = (userData['username'] ?? '').toString();
        }
      }
    });

    if (userData['is_suspended'] == true) {
      setState(() => _isLoading = false);
      _showErrorDialog(
        'alert_suspended_title'.tr(),
        'alert_suspended_message'.tr(),
      );

      return;
    }

    if (password.isNotEmpty) {
      final username =
          _tabController.index == 0
              ? _phoneController.text
              : _usernameController.text;

      await _storage.write(key: 'saved_username_$username', value: username);
      await _storage.write(key: 'saved_password_$username', value: password);
      await _storage.write(
        key: 'login_type_$username',
        value: posMode ? '1' : '0',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometrics_enabled_$username', true);
    }

    // ─── حفظ بيانات نقطة المبيعات إذا كان هذا الدخول كنقطة مبيعات ───
    if (posMode) {
      final prefs = await SharedPreferences.getInstance();
      final posNumber = userData['active_pos_number']?.toString() ?? '';
      final posName = userData['pos_trade_name']?.toString() ?? '';
      await prefs.setString('pos_number', posNumber);
      await prefs.setString('pos_trade_name', posName);
    }

    await _saveAccount(username, _loggedInFullName, posMode ? '1' : '0');
    // sessionManager.startSession(); // Removed as per user request to start from HomeScreen instead

    // تقليل زمن الانتظار للانتقال السريع
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        final userType = userData['user_type']?.toString().toUpperCase();
        final bool isStaffOrAgent = userType == 'AGENT' || userType == 'STAFF';

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) {
              // ─── التحقق من فرض تعيين كلمة المرور (عند أول دخول أو طلب السيرفر) ───
              if (userData['force_password_change'] == true ||
                  password == '123456') {
                return PasswordSetupScreen(
                  isDarkMode: themeService.isDarkModeActive(context),
                  isForced: true,
                  isResetMode: true,
                  oldPassword: password,
                  fullUserData: userData,
                );
              }
              if (posMode || isStaffOrAgent) {
                return const POSHomeScreen();
              }
              return HomeScreen(
                isDarkMode: themeService.isDarkModeActive(context),
                isInitiallyVerified: userData['is_verified'] ?? false,
              );
            },
          ),
          (route) => false,
        );
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    final isDark = themeService.isDarkModeActive(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            elevation: 10,
            shadowColor: AppColors.accentBlue.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(
                color: isDark ? Colors.white10 : AppColors.accentBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon with subtle glow effect
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.accentBlue.withValues(alpha: 0.1)
                            : AppColors.accentBlue.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textGreyLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 4,
                      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'ok'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'biometric_login_reason'.tr(),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction:
              false, // Required for Face ID on some Android devices
        ),
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'my_app_name'.tr(),
            biometricHint: '',
          ),
        ],
      );

      if (isAuthenticated && mounted) {
        final username = _getCurrentUsername();
        final savedUsername = await _storage.read(
          key: 'saved_username_$username',
        );
        final savedPassword = await _storage.read(
          key: 'saved_password_$username',
        );

        if (savedUsername != null && savedPassword != null) {
          setState(() => _isLoading = true);
          try {
            final Map<String, dynamic> userData;
            userData = await ApiService.login(
              savedUsername,
              savedPassword,
              _tabController.index == 0 ? 'phone_number' : 'pos_point',
            );

            // Request notification permissions after successful login
            // await NotificationService.init();
            if (mounted) {
              setState(() {
                _isLoading = false;
                final first = userData['first_name'] ?? "";
                final last = userData['last_name'] ?? "";
                _loggedInFullName = "$first $last".trim();
                if (_loggedInFullName.isEmpty) _loggedInFullName = "بعودتك";
              });

              // Enable biometrics locally if not already
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('biometrics_enabled_$username', true);
              } catch (e) {
                customPrint('Error saving biometric preference: $e');
              }

              // Start Session Timer
              //sessionManager.startSession();

              final bool isAgentTab = _tabController.index == 1;
              final userType = userData['user_type']?.toString().toUpperCase();
              final bool isStaffOrAgent =
                  userType == 'AGENT' || userType == 'STAFF';

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) {
                      if (isAgentTab || isStaffOrAgent) {
                        return const POSHomeScreen();
                      }
                      return HomeScreen(
                        isDarkMode: themeService.isDarkModeActive(context),
                        isInitiallyVerified: userData['is_verified'] ?? false,
                      );
                    },
                  ),
                  (route) => false,
                );
              }
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              String displayError =
                  e.toString().replaceAll('Exception:', '').trim();
              if (displayError.contains('SocketException') ||
                  displayError.contains('HttpException') ||
                  displayError.contains('Connection failed') ||
                  displayError.contains('timeout')) {
                displayError =
                    'خطأ في الاتصال بالانترنت. يرجى التأكد من توفر الانترنت أو المحاولة لاحقاً.';
              }
              _showErrorDialog('biometric_error_title'.tr(), displayError);
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('please_login_password_first'.tr())),
            );
          }
        }
      }
    } catch (e) {
      // إخفاء الخطأ عند فشل المصادقة بالبصمة (مثل الإلغاء من قبل المستخدم)
      customPrint('Biometric Auth Error (Hidden): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = _buildThemeColors();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: themeColors.bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildBackgroundPattern()),
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        height:
                            MediaQuery.of(context).size.height * _headerHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _isInternetAvailable
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade800,
                              _isInternetAvailable
                                  ? AppColors.accentBlue.withValues(alpha: 0.9)
                                  : Colors.grey.shade600,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(60),
                            bottomRight: Radius.circular(60),
                          ),
                        ),
                        child: SafeArea(
                          child: Stack(
                            children: [
                              Positioned(
                                top: 15,
                                left: 20,
                                child: Row(
                                  children: [
                                    _buildThemeToggle(themeColors),
                                    const SizedBox(width: 8),
                                    _buildLanguageToggle(themeColors),
                                  ],
                                ),
                              ),
                              // Switch Account Button
                              if (_savedAccounts.isNotEmpty)
                                Positioned(
                                  top: 15,
                                  right: 20,
                                  child: InkWell(
                                    onTap:
                                        () => _showAccountsBottomSheet(
                                          themeColors,
                                        ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.blue),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.people_alt_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${"switch_account".tr()} (${_savedAccounts.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildLogoWithGlow(themeColors),
                                        const SizedBox(height: 8),
                                        Text(
                                          'my_app_name'.tr(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'your_secure_gateway_to_financial_transactions'
                                              .tr(),
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 
                                              0.85,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      // DISABLED: Offline indicator
                      // if (!_isInternetAvailable) ...[
                      //   _buildOfflineIndicator(themeColors),
                      //   const SizedBox(height: 20),
                      // ],
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.12,
                        ),
                        child: _buildModernTabBar(themeColors),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                        ),
                        child: _buildFormContainer(themeColors),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                        ),
                        child: _buildActionButtons(themeColors),
                      ),
                      const SizedBox(height: 20),
                      _buildFooterLinks(themeColors),
                      const SizedBox(height: 20),
                      _buildContactSection(themeColors),
                      const SizedBox(height: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ============= Loading Overlay with TRUE centered arrows animation =============
  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color:
            themeService.isDarkModeActive(context)
                ? AppColors.scaffoldDark
                : const Color.fromARGB(127, 255, 255, 255),
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackgroundPattern()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('pr_logo.png', height: 120, width: 120)
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                      )
                      .rotate(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                        begin:
                            -1.0, // Full 360 degree rotation (counter-clockwise start)
                        end: 0.0,
                      )
                      .then(delay: 200.ms)
                      .shimmer(duration: 1500.ms),
                  const SizedBox(height: 30),
                  const SizedBox(height: 30),
                  Text(
                        _loggedInFullName,
                        // '${"hello".tr()} $_loggedInFullName',
                        style: TextStyle(
                          color:
                              themeService.isDarkModeActive(context)
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // Helper Methods (Summarized/Keeping essential logic)
  ThemeColors _buildThemeColors() {
    final isDark = themeService.isDarkModeActive(context);
    return ThemeColors(
      bgColor: isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      cardColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      inputColor: isDark ? AppColors.inputDark : AppColors.inputLight,
      textColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      hintColor: isDark ? AppColors.textGreyDark : AppColors.textGreyLight,
      logoBg: isDark ? AppColors.cardDark : Colors.white,
      borderColor: isDark ? Colors.white12 : Colors.grey.shade200,
    );
  }

  Widget _buildBackgroundPattern() {
    return Opacity(
      opacity: themeService.isDarkModeActive(context) ? 0.04 : 0.05,
      child: IgnorePointer(
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 200,
          itemBuilder:
              (context, index) => Transform.rotate(
                angle: math.pi / 4,
                child: Icon(
                  Icons.double_arrow_rounded,
                  color:
                      themeService.isDarkModeActive(context)
                          ? Colors.white
                          : Colors.black,
                  size: 35,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(ThemeColors colors) {
    return InkWell(
      onTap: _showThemePicker,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: const Icon(Icons.palette_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildLanguageToggle(ThemeColors colors) {
    // final isArabic = themeService.locale.languageCode == 'ar';
    final isArabic = context.locale == Locale('ar');
    return InkWell(
      onTap: () async {
        if (isArabic) {
          await context.setLocale(Locale('en'));
        } else {
          await context.setLocale(Locale('ar'));
        }

        // themeService.setLocale(
        //   isArabic ? const Locale('en') : const Locale('ar'),
        // );
        // customPrint("Test Ching Lang");
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Text(
          isArabic ? 'EN' : 'AR',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = themeService.isDarkModeActive(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'customize_appearance'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildThemeOption(
                  'theme_light'.tr(),
                  Icons.light_mode_rounded,
                  ThemeMode.light,
                ),
                _buildThemeOption(
                  'theme_dark'.tr(),
                  Icons.dark_mode_rounded,
                  ThemeMode.dark,
                ),
                _buildThemeOption(
                  'theme_system'.tr(),
                  Icons.brightness_auto_rounded,
                  ThemeMode.system,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /* DISABLED: Offline indicator widget
  Widget _buildOfflineIndicator(ThemeColors colors) {
    return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnecting ? Icons.refresh : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  'offline_mode'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (!_isConnecting)
                  InkWell(
                    onTap: _manualRetryConnection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'retry'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
  }
  */ // END DISABLED _buildOfflineIndicator

  Widget _buildThemeOption(String title, IconData icon, ThemeMode mode) {
    final isDark = themeService.isDarkModeActive(context);
    bool isSelected = themeService.themeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accentBlue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textBlack,

          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_circle_rounded, color: AppColors.accentBlue)
              : null,
      onTap: () {
        themeService.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLogoWithGlow(ThemeColors colors) {
    // تحديد أحجام مختلفة بناءً على الوضع
    final double logoSize = themeService.isDarkModeActive(context) ? 95 : 85;

    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.logoBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.glowBlue.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Image.asset(
            themeService.isDarkModeActive(context)
                ? 'logo_circle.png'
                : 'pr_logo.png',
            height: logoSize,
            width: logoSize,
            errorBuilder:
                (c, e, s) => Icon(
                  Icons.account_balance_wallet,
                  size: logoSize * 0.5,
                  color: AppColors.primaryBlue,
                ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(
          duration: 6.seconds,
          begin: 0,
          end: 1,
        ); // دوران باتجاه عقارب الساعة
  }

  Widget _buildModernTabBar(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentBlue, AppColors.primaryBlue],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: colors.hintColor,
        labelPadding: EdgeInsets.zero,
        onTap: (index) async {
          // عند الضغط على نقطة مبيعات، يظهر تأكيد
          if (index == 1 && _tabController.index == 0) {
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store_mall_directory_rounded,
                        color: AppColors.accentBlue,
                        size: 32,
                      ),
                    ),
                    title: Text(
                      'navigate_to_pos_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'navigate_to_pos_message'.tr(),
                      textAlign: TextAlign.center,
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('no'.tr()),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('yes_go'.tr()),
                      ),
                    ],
                  ),
            );
            if (confirm != true) return; // لا ينتقل إلا عند الموافقة
          }
          _tabController.animateTo(index);
          setState(() {});
        },
        tabs: [
          Tab(
            child: Center(
              child: Text(
                'user'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Tab(
            child: Center(
              child: Text(
                'point_of_sale'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          _tabController.index == 0
              ? _buildUserForm(colors)
              : _buildPOSForm(colors),
          const SizedBox(height: 10),
          /* DISABLED: Offline checkbox
          // CheckboxListTile(
          //   value: _isOfflineMode,
          //   onChanged: (val) => setState(() => _isOfflineMode = val ?? false),
          //   title: Text(
          //     'login_offline'.tr(),
          //     style: TextStyle(
          //       fontSize: 12,
          //       color: colors.textColor,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          //   controlAffinity: ListTileControlAffinity.leading,
          //   contentPadding: EdgeInsets.zero,
          //   activeColor: AppColors.accentBlue,
          //   visualDensity: VisualDensity.compact,
          //   checkboxShape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(5),
          //   ),
          // ),
          */
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () {
                  if (_tabController.index == 1) {
                    ErrorDialog.show(
                      context,
                      title: 'forgot_your_password'.tr(),
                      message:
                          'يرجى التواصل مع خدمة العملاء الرقم المجاني 8000002',
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ForgotPasswordVerifyScreen(
                              phoneNumber: _phoneController.text,
                              isDarkMode: themeService.isDarkModeActive(
                                context,
                              ),
                            ),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'forgot_your_password'.tr(),
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm(ThemeColors colors) {
    return Column(
      children: [
        _buildInputField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          nextFocusNode: _passwordFocusNode,
          label: 'phone_number'.tr(),
          icon: Icons.phone_iphone_rounded,
          colors: colors,
          keyboardType: TextInputType.phone,
          prefixText: ' ',
          // textAlign: TextAlign.left,
          // textDirection: TextDirection.LTR,
          maxLength: 9,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'password'.tr(),
          icon: Icons.lock_rounded,
          colors: colors,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _buildPOSForm(ThemeColors colors) {
    return Column(
      children: [
        _buildInputField(
          controller: _usernameController,
          focusNode: _usernameFocusNode,
          nextFocusNode: _passwordFocusNode,
          label: 'point_no'.tr(),
          icon: Icons.confirmation_number_rounded,
          colors: colors,
          keyboardType: TextInputType.number,
          maxLength: 7,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'password'.tr(),
          icon: Icons.security_rounded,
          colors: colors,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeColors colors,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String prefixText = '',
    TextAlign? textAlign,
    int? maxLength,
  }) {
    // final bool isRtl = themeService.locale.languageCode == 'ar';
    final bool isRtl = context.locale == Locale('ar');

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.textColor),
      textAlign: textAlign ?? (isRtl ? TextAlign.right : TextAlign.left),
      // textDirection: textDirection ?? (isRtl ? TextDirection.RTL : TextDirection.LTR),
      maxLength: maxLength,
      textInputAction:
          nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onChanged: (value) {
        if (maxLength != null && value.length == maxLength) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          } else {
            FocusScope.of(context).unfocus();
          }
        }
        _checkBiometricsForCurrentUser();
      },
      onSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          // FocusScope.of(context).unfocus();
          _handleLogin();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.hintColor),
        prefixIcon: Icon(icon, color: AppColors.accentBlue),
        prefixText: prefixText,
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: colors.hintColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
                : null,
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.accentBlue),
        ),
      ),
    );
  }

  void _showAccountsBottomSheet(ThemeColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'choose_account_follow'.tr().replaceFirst(
                      '{count}',
                      _savedAccounts.length.toString(),
                    ),
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),
                  ..._savedAccounts.map((account) {
                    final isSelected =
                        _phoneController.text == account['username'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primaryBlue
                                  : colors.borderColor,
                        ),
                      ),
                      child: ListTile(
                        onTap: () async {
                          setState(() {
                            _phoneController.text = account['username'];
                            _tabController.animateTo(
                              int.parse(account['type'] ?? '0'),
                            );
                            _selectedAccount = account;
                          });
                          await _checkBiometricsForCurrentUser(
                            autoPrompt: true,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentBlue,
                          child: Text(
                            (account['name'] ?? 'U')[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          account['name'] ?? 'مستخدم',
                          style: TextStyle(
                            color: colors.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          account['username'] ?? '',
                          style: TextStyle(color: colors.hintColor),
                        ),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryBlue,
                                )
                                : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        // Clear inputs
                        setState(() {
                          _phoneController.clear();
                          _usernameController.clear();
                          _passwordController.clear();
                          _selectedAccount = null;
                        });
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        color: AppColors.primaryBlue,
                      ),
                      label: Text(
                        'sign_in_new_account'.tr(),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildActionButtons(ThemeColors colors) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isInternetAvailable
                      ? AppColors.primaryBlue
                      : Colors.grey.shade600,
              elevation: 4,
              shadowColor: (_isInternetAvailable
                      ? AppColors.primaryBlue
                      : Colors.grey)
                  .withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              // DISABLED: Offline login button text change
              // _isInternetAvailable ? 'save_login'.tr() : 'login_offline'.tr(),
              'save_login'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        _buildBiometricButtons(colors),

        // Create Account Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'no_have_an_account'.tr(),
              style: TextStyle(
                color: colors.textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RegisterScreen(
                          isDarkMode: themeService.isDarkModeActive(context),
                        ),
                  ),
                );
              },
              child: Text(
                'sign_up'.tr(),
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBiometricButtons(ThemeColors colors) {
    if (!_canAuthenticateWithBiometrics) return const SizedBox.shrink();

    // Determine the most appropriate icon
    IconData bioIcon = Icons.fingerprint_rounded;
    String bioTooltipKey = 'bio_tooltip';

    if (_availableBiometrics.contains(BiometricType.face) ||
        _availableBiometrics.contains(BiometricType.weak)) {
      bioIcon = Icons.face_retouching_natural_rounded;
      bioTooltipKey = 'bio_face_tooltip';
    }

    final tooltipMessage =
        _savedUsername != null
            ? 'login_for_user'.tr().replaceFirst('{username}', _savedUsername!)
            : bioTooltipKey.tr();

    return Tooltip(
      message: tooltipMessage,
      child: _buildSmallBiometricBtn(
        icon: bioIcon,
        onTap: _handleBiometricAuth,
        colors: colors,
      ),
    );
  }

  Widget _buildSmallBiometricBtn({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.accentBlue, size: 28),
      ),
    );
  }

  Widget _buildFooterLinks(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'the_rights_belong_to_financial'.tr(),
          style: TextStyle(color: colors.hintColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildContactSection(ThemeColors colors) {
    return Column(
      children: [
        Text(
          'contact_us'.tr(),
          style: TextStyle(
            color: colors.textColor.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildContactItem(
              icon: Icons.chat_bubble_rounded,
              label: 'customer_service'.tr(),
              onTap: _launchWhatsApp,
            ),
            const SizedBox(width: 30),
            _buildContactItem(
              icon: Icons.location_on_rounded,
              label: 'service_points'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => LocationsViewScreen(
                          isDarkMode: themeService.isDarkModeActive(context),
                        ),
                  ),
                );
              },
            ),
            const SizedBox(width: 30),
            _buildContactItem(
              icon: Icons.phone_rounded,
              label: 'free_number'.tr(),
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: '8000002');
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = themeService.isDarkModeActive(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeColors {
  final Color bgColor,
      cardColor,
      inputColor,
      textColor,
      hintColor,
      logoBg,
      borderColor;
  ThemeColors({
    required this.bgColor,
    required this.cardColor,
    required this.inputColor,
    required this.textColor,
    required this.hintColor,
    required this.logoBg,
    required this.borderColor,
  });
}
