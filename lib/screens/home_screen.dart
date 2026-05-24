import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:saifix/services/contact_service.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:saifix/screens/change_password_screen.dart';
import 'package:saifix/widgets/search_reference_number_dialog.dart';
import 'package:saifix/components/loading_overlay.dart';
import 'package:saifix/core/app_colors.dart';
import 'financial_transfers/transfer_to_subscriber_screen.dart';
import 'financial_transfers_screen.dart'; // شاشة التحويلات المالية
import 'saifi_screen.dart'; // شاشة صيفي مستقلة
import 'cash_withdrawal_screen.dart'; // شاشة سحب نقدي مستقلة
import 'pay_purchases_screen.dart'; // شاشة دفع المشتريات مستقلة
import 'saifi_transfer_screen.dart'; // شاشة صيفي كاش مستقلة
import 'recharge_and_payment_screen.dart'; // شاشة الشحن والسداد مستقلة
import 'recharge_and_payment/games_entertainment_screen.dart'; // شاشة الألعاب والترفيه
import 'financial_transfers/transfer_between_accounts_screen.dart';
import 'financial_transfers/select_local_network_screen.dart';
import 'financial_transfers/local_transfer_status_cancel_screen.dart';
import 'social_media_screen.dart';
import 'privacy_security_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saifix/services/api_service.dart';
import 'package:saifix/services/notification_service.dart';
import 'package:saifix/services/session_manager.dart';
import 'dart:async';
import 'financial_transfers/receive_transfer_request_screen.dart';
import 'account_confirmation_screen.dart';
import 'financial_transfers/all_transactions_screen.dart';
import 'dart:math' as math;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'device_management_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/theme_service.dart';
import 'auth/login_screen.dart';
import 'business_register_screen.dart';
import '../components/qr_scanner_screen.dart';
import 'locations_view_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'custom_search_screen.dart';
import 'chatbot_screen.dart';
import 'currency_transactions_screen.dart';
import '../models/ad_banner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'notifications_screen.dart';
import '../models/operation_history.dart';
import '../utils/operation_type_helper.dart';
import '../widgets/receipt_dialog.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'favorites_screen.dart';
import '../services/balance_service.dart';
import '../helper/counvert_amunt_helper.dart';
import 'terms_conditions_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool isInitiallyVerified;
  const HomeScreen({
    super.key,
    this.isDarkMode = false,
    this.isInitiallyVerified = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // New Image Picker State
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  final ScreenshotController _qrScreenshotController = ScreenshotController();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _profileImageBytes = bytes;
        });
        await _saveProfileImage(bytes);
      }
    }
  }

  Future<void> _saveProfileImage(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/profile_image.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      customPrint('✅ Profile image saved to: $path');
    } catch (e) {
      customPrint('❌ Error saving profile image: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/profile_image.png';
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _profileImageBytes = bytes;
          });
          customPrint('✅ Profile image loaded from: $path');
        }
      }
    } catch (e) {
      customPrint('❌ Error loading profile image: $e');
    }
  }

  static int _lastCardPage = 1;
  int _currentIndex = _lastCardPage;
  bool _isMenuOpen = false;
  bool _isLoading = false;
  final List<bool> _showBalances = [
    false,
    false,
    false,
  ]; // State for hiding money per card (default to hidden)
  late PageController _pageController;
  final ValueNotifier<double> _pageOffsetNotifier = ValueNotifier(1.0);
  int _selectedTab = 0; // 0 for Home, 1 for Wallet

  bool _isAccountConfirmed = false;
  bool _isKycPending = false;
  bool _isRejected = false;
  String? _rejectionReason;
  bool _hasShownRejectionDialog = false;
  String _firstName = "";
  String _fullName = "";
  String _username = "";
  String _altNumber = "";

  // Real Balances from API
  Map<String, String> _balances = {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};

  // Notifications State
  Timer? _notificationTimer;
  Timer? _bannerTimer;
  Timer? _dataRefreshTimer;
  bool _hasUnreadNotifications = false;

  late PageController _bannerController;
  bool _isBannersLoading = true;
  List<AdBanner> _adBanners = [];

  // Transactions State
  List<OperationHistoryModel> _transactions = [];
  final String _historyFilter = 'all'; // 'all', 'sent', 'received'

  // Customization State
  List<int?> _customizedServiceIndices = [null, null, null];
  List<Map<String, dynamic>> get allServices => [
    {
      'title': 'switch_shared_account'.tr(),
      'icon': Icons.person_add_alt_1_rounded,
    },
    {'title': 'my_app_name'.tr(), 'icon': Icons.send_rounded},
    {
      'title': 'cash_withdrawal_request'.tr(),
      'icon': Icons.account_balance_wallet_rounded,
    },
    {'title': 'payment_for_purchases'.tr(), 'icon': Icons.shopping_bag_rounded},
    // {
    //   'title': 'banks_and_portfolios'.tr(),
    //   'icon': Icons.account_balance_rounded,
    // },
    {
      'title': 'receiving_a_network_transfer'.tr(),
      'icon': Icons.downloading_rounded,
    },
    {'title': 'transfer_status'.tr(), 'icon': Icons.fact_check_rounded},
    {'title': 'send_a_local_money_transfer'.tr(), 'icon': Icons.outbox_rounded},
    {
      'title': 'cancel_transfer'.tr(),
      'icon': Icons.cancel_schedule_send_rounded,
    },
    {
      'title': 'transfer_between_my_accounts'.tr(),
      'icon': Icons.swap_horiz_rounded,
    },
    {'title': 'shipping_and_payment'.tr(), 'icon': Icons.bolt_rounded},
    // {'title': 'purchase_code'.tr(), 'icon': Icons.qr_code_2_rounded},
    {'title': 'net_cards'.tr(), 'icon': Icons.wifi_tethering_rounded},
    {'title': 'games'.tr(), 'icon': Icons.videogame_asset_rounded},
    // {'title': 'applications'.tr(), 'icon': Icons.favorite_rounded},
    // {'title': 'donations'.tr(), 'icon': Icons.volunteer_activism_rounded},
    // {'title': 'national_payment'.tr(), 'icon': Icons.account_balance_rounded},
    {'title': 'service_points'.tr(), 'icon': Icons.location_on_rounded},
    // {'title': 'saifix'.tr(), 'icon': Icons.group_work_rounded},
    // {
    //   'title': 'dynamic_interfaces'.tr(),
    //   'icon': Icons.dashboard_customize_rounded,
    // },
  ];

  @override
  void initState() {
    super.initState();
    // Adjusted viewportFraction for horizontal display showing side card edges
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: _lastCardPage,
    );
    //sessionManager.startSession();
    _bannerController = PageController();
    _pageOffsetNotifier.value = _lastCardPage.toDouble();

    _isAccountConfirmed = widget.isInitiallyVerified;

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        _pageOffsetNotifier.value =
            _pageController.page ?? _lastCardPage.toDouble();
      }
    });

    _fetchData(showLoading: false);
    _startNotificationPolling();
    _startAutoTimers();
    _loadCustomization();
    _loadProfileImage();
    _loadAds();
    contactService.preLoadContacts();
    // _initVoiceCommands();
  }

  // void _initVoiceCommands() {
  //   voiceCommandService.latestCommand.addListener(_handleVoiceCommand);
  // }

  // void _handleVoiceCommand() {
  //   final result = voiceCommandService.latestCommand.value;
  //   if (result == null) return;

  //   if (result.intent == VoiceIntent.navigateTransfers) {
  //     if (mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (context) =>
  //                   FinancialTransfersScreen(isDarkMode: widget.isDarkMode),
  //         ),
  //       );
  //     }
  //   } else if (result.intent == VoiceIntent.navigateTransferToSubscriber) {
  //     if (mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (context) =>
  //                   TransferToSubscriberScreen(isDarkMode: widget.isDarkMode),
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  void dispose() {
    // voiceCommandService.latestCommand.removeListener(_handleVoiceCommand);
    _notificationTimer?.cancel();
    _bannerTimer?.cancel();
    _dataRefreshTimer?.cancel();
    _pageController.dispose();
    _pageOffsetNotifier.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('customized_services');
    if (stored != null && stored.length == 3) {
      setState(() {
        _customizedServiceIndices =
            stored.map((s) => s == 'null' ? null : int.tryParse(s)).toList();
      });
    }
  }

  Future<void> _saveCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'customized_services',
      _customizedServiceIndices.map((i) => i.toString()).toList(),
    );
  }

  void _showServicePicker(int slotIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'choose_service_to_install'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.primaryBlue,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: allServices.length + 1,
                    itemBuilder: (context, index) {
                      if (index == allServices.length) {
                        // Clear option
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _customizedServiceIndices[slotIndex] = null;
                            });
                            _saveCustomization();
                            Navigator.pop(context);
                          },
                          child: _buildPickerItem(
                            'remove'.tr(),
                            Icons.delete_outline_rounded,
                            Colors.red,
                          ),
                        );
                      }

                      final service = allServices[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _customizedServiceIndices[slotIndex] = index;
                          });
                          _saveCustomization();
                          Navigator.pop(context);
                        },
                        child: _buildPickerItem(
                          service['title'],
                          service['icon'],
                          AppColors.accentBlue,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPickerItem(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _startAutoTimers() {
    _startBannerTimer();

    // _dataRefreshTimer removed as per user request to only refresh on operation
  }

  void _startNotificationPolling() {
    _fetchNotifications(); // Initial fetch only, no periodic polling
  }

  Future<void> _fetchNotifications() async {
    final notifications = await ApiService.getNotifications();
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = notifications.any(
          (n) => n['is_read'] == false,
        );
      });

      // Check for new broadcast notifications
      final prefs = await SharedPreferences.getInstance();
      final lastSeenId = prefs.getInt('last_broadcast_id') ?? -1;

      if (notifications.isNotEmpty) {
        final latest = notifications.first;
        final int currentId = latest['id'] ?? -1;
        final bool isRead = latest['is_read'] ?? true;

        if (currentId > lastSeenId && !isRead) {
          NotificationService.showNotification(
            id: currentId,
            title: latest['title'] ?? 'إشعار جديد',
            body: latest['message'] ?? '',
          );
          await prefs.setInt('last_broadcast_id', currentId);
        }
      }
    }
  }

  Future<void> _fetchData({
    bool showLoading = true,
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    // Load cached data immediately for responsiveness, unless forcing refresh
    if (!forceRefresh) {
      final cachedUser = await ApiService.getCachedUser();
      final cachedBalances = await ApiService.getCachedBalances();

      if (mounted && (cachedUser != null || cachedBalances.isNotEmpty)) {
        setState(() {
          if (cachedUser != null) {
            _firstName = cachedUser['first_name'] ?? "";
            _username = cachedUser['username'] ?? "";
            _altNumber = (cachedUser['wallet_id'] ?? "").toString();
            _fullName =
                cachedUser['full_name'] ??
                "${cachedUser['first_name'] ?? ''} ${cachedUser['second_name'] ?? ''} ${cachedUser['third_name'] ?? ''} ${cachedUser['last_name'] ?? ''}"
                    .trim();
            _isAccountConfirmed = cachedUser['is_verified'] ?? false;
            _isKycPending = (cachedUser['id_number'] != null &&
                cachedUser['id_number'].toString().isNotEmpty);
            _isRejected = cachedUser['is_rejected'] ?? false;
            _rejectionReason = cachedUser['rejection_reason'];
          }
          _balances = {
            'YER': cachedBalances['YER']?.toString() ?? '0.00',
            'USD': cachedBalances['USD']?.toString() ?? '0.00',
            'SAR': cachedBalances['SAR']?.toString() ?? '0.00',
          };
        });
        customPrint('✅ تم تحميل البيانات المخزنة: $_balances');
        _showRejectionDialogIfNeeded();
      }
    }

    if (showLoading) setState(() => _isLoading = true);
    try {
      customPrint('🔄 جلب البيانات (تحديث: $forceRefresh)...');

      final balanceData = await ApiService.getBalances(
        forceRefresh: forceRefresh,
      );
      customPrint('💰 الأرصدة: $balanceData');

      final userData = await ApiService.getMe(forceRefresh: forceRefresh);
      customPrint('👤 بيانات المستخدم: $userData');

      if (mounted) {
        setState(() {
          // جلب الأرصدة
          if (userData['wallets'] != null) {
            final wallets = userData['wallets'];
            _balances = {
              'YER': (wallets['YER'] ?? 0.0).toString(),
              'USD': (wallets['USD'] ?? 0.0).toString(),
              'SAR': (wallets['SAR'] ?? 0.0).toString(),
            };
          } else {
            _balances = {
              'YER': (balanceData['YER'] ?? 0.0).toString(),
              'USD': (balanceData['USD'] ?? 0.0).toString(),
              'SAR': (balanceData['SAR'] ?? 0.0).toString(),
            };
          }

          // تحديث البيانات فقط إذا لم يكن هناك خطأ (مثل انتهاء الجلسة)
          if (!userData.containsKey('error')) {
            _isAccountConfirmed = userData['is_verified'] ?? false;
            // إخفاء البانر إذا كان المستخدم قد أرسل بياناته بالفعل (رقم الهوية موجود) ولكنه لم يتم التحقق منه بعد
            _isKycPending =
                (userData['id_number'] != null &&
                    userData['id_number'].toString().isNotEmpty);
            _isRejected = userData['is_rejected'] ?? false;
            _rejectionReason = userData['rejection_reason'];

            _firstName = userData['first_name'] ?? "";
            _username = userData['username'] ?? "";
            // استخدام wallet_id بدلاً من alternative_phone
            _altNumber = (userData['wallet_id'] ?? "").toString();
            _fullName =
                userData['full_name'] ??
                "${userData['first_name'] ?? ''} ${userData['second_name'] ?? ''} ${userData['third_name'] ?? ''} ${userData['last_name'] ?? ''}"
                    .trim();
          }
        });

        customPrint(' تم تحديث الحالة - الأرصدة: $_balances');
        customPrint(' الاسم الكامل: $_fullName');
        customPrint(
          ' حالة التوثيق: $_isAccountConfirmed, حالة الانتظار: $_isKycPending',
        );
      }

      _showRejectionDialogIfNeeded();

      // Fetch Transactions using Operations History API
      final historyResponse = await ApiService.getOperationsHistory(
        pageSize: 20,
      );
      final transactions = historyResponse.results;
      customPrint('📊 العمليات: ${transactions.length} عملية');

      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      customPrint('❌ خطأ في جلب البيانات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال بالخادم: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAds() async {
    try {
      setState(() => _isBannersLoading = true);
      final ads = await ApiService.getAdBanners();
      if (mounted) {
        setState(() {
          _adBanners = ads;
          _isBannersLoading = false;
        });
        // Restart banner timer with correct count
        _bannerTimer?.cancel();
        _startBannerTimer();
      }
    } catch (e) {
      customPrint('Error loading ads: $e');
    }
  }

  void _startBannerTimer() {
    final adCount = _adBanners.isEmpty ? 1 : _adBanners.length;
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        int nextPage = (_bannerController.page?.toInt() ?? 0) + 1;
        if (nextPage >= adCount) nextPage = 0;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'good_morning'.tr();
    } else {
      return 'good_evening'.tr();
    }
  }

  void _showNotificationsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NotificationsScreen(isDarkMode: widget.isDarkMode),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _hasUnreadNotifications = false);
      }
    });
  }

  void _navigateToConfirmation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AccountConfirmationScreen(
                  isDarkMode: widget.isDarkMode,
                  rejectionReason: _rejectionReason,
                ),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        _isAccountConfirmed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'account_successfully_verified'.tr(),
            style: TextStyle(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgImage = isDark ? "back1.png" : "back2.png";
    final overlayColor =
        isDark
            ? AppColors.primaryBlue.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectedTab != 0) {
          setState(() {
            _selectedTab = 0;
          });
        } else {
          _showConfirmExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNavigationBar(),
        body: Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Stack(
              children: [
                // Animated Background Image (Ken Burns Effect) - Optimized with RepaintBoundary
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Image.asset(
                          bgImage,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const SizedBox(),
                        )
                        .animate(
                          onPlay:
                              (controller) => controller.repeat(reverse: true),
                        )
                        .scale(
                          duration: 20.seconds,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.easeInOut,
                        )
                        .move(
                          duration: 20.seconds,
                          begin: const Offset(-10, -10),
                          end: const Offset(10, 10),
                          curve: Curves.easeInOut,
                        ),
                  ),
                ),
                Positioned.fill(child: Container(color: overlayColor)),

                SafeArea(
                  child: Column(
                    children: [
                      _buildFixedHeader(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _fetchData(showLoading: false),
                          color: AppColors.primaryBlue,
                          backgroundColor:
                              isDark ? AppColors.cardDark : Colors.white,
                          child: IndexedStack(
                            index: _selectedTab,
                            children: [
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: _buildHomeContent(),
                              ),
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: _buildWalletContent(),
                              ),
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: _buildHistoryContent(),
                              ),
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: _buildProfileContent(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading) _buildLoadingOverlay(),
                if (_isMenuOpen) _buildMenuOverlay(),

                // Voice Assistant Button
                // Positioned(
                //   bottom: 100,
                //   right: 20,
                //   child: VoiceAssistantButton(isDarkMode: isDark),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: LoadingOverlay(
        isDarkMode: widget.isDarkMode,
        message: 'loading_data'.tr(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isAccountConfirmed) _buildConfirmationBanner(),
        const SizedBox(height: 8), // Aggressively reduced
        _build3DCardSwiper(),
        const SizedBox(height: 0), // Removed gap entirely
        _buildPromotionBanner(),
        const SizedBox(height: 8), // Aggressively reduced
        _buildServicesGrid(),
        const SizedBox(height: 8), // Aggressively reduced
        _buildRecentTransactions(limit: 5),
        const SizedBox(height: 8), // Aggressively reduced
      ],
    );
  }

  void _showRejectionDialogIfNeeded() {
    if (!_isRejected || _hasShownRejectionDialog) return;
    _hasShownRejectionDialog = true;

    // Trigger dialog after build completes to avoid calling showDialog during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.7), // تعتيم الخلفية كما في الصورة
        builder: (BuildContext context) {
          final isDark = widget.isDarkMode;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textStyleColor = isDark ? Colors.white : const Color(0xFF4A4A4A);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 80), // دفعها لأسفل قليلاً تحت شريط الحالة
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // البطاقة البيضاء للرسالة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            (_rejectionReason != null && _rejectionReason!.isNotEmpty)
                                ? _rejectionReason!
                                : 'عذراً، بياناتك لا تطابق الهوية المرفوعة. يرجى إعادة رفع الهوية الصحيحة أو زيارة أقرب فرع لتفعيل حسابك.',
                            style: TextStyle(
                              color: textStyleColor,
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft, // في اليسار كما هو بالصورة العربية
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _navigateToConfirmation();
                              },
                              child: const Text(
                                'تحديث بياناتك',
                                style: TextStyle(
                                  color: Color(0xFFE53935), // أحمر للتحديث كما في الصورة
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // زر الإغلاق العائم في الأعلى على اليسار خارج البطاقة كما في الصورة
                    Positioned(
                      top: -55,
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildConfirmationBanner() {
    final bool isRejected = _isRejected;
    final bool isPending = _isKycPending && !isRejected;

    String message;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (isRejected) {
      message = 'تم رفض طلبك اضغط للتحديث';
      bgColor = const ui.Color.fromARGB(255, 248, 194, 194); // أحمر داكن عند الرفض
      textColor = Colors.red; // أحمر فاتح للكتابة
      icon = Icons.warning_amber_rounded;
    } else if (isPending) {
      message = 'طلبك تحت المراجعة';
      bgColor = const Color(0xFF251A00); // ذهبي فاخر عند المراجعة
      textColor = const Color(0xFFFBBF24);
      icon = Icons.hourglass_top_rounded;
    } else {
      message = 'click_here_confirm_your_wallet'.tr();
      bgColor = const ui.Color.fromARGB(255, 248, 194, 194); // أحمر عادي
      textColor = Colors.red;
      icon = Icons.info_outline_rounded;
    }

    return GestureDetector(
      onTap: _navigateToConfirmation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withValues(alpha: 0.3)
          ),
          boxShadow: [
            BoxShadow(
              color: textColor.withValues(alpha: 0.1), 
              blurRadius: 10
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 20,
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .fade(duration: 1000.ms, begin: 0.5, end: 1.0),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_back_ios_rounded,
              color: textColor.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        // Customization Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'service_allocation'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: List.generate(3, (index) {
                  final serviceIndex = _customizedServiceIndices[index];
                  final service =
                      serviceIndex != null ? allServices[serviceIndex] : null;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (service != null) {
                          _handleServiceNavigation(service['title']);
                        } else {
                          _showServicePicker(index);
                        }
                      },
                      onLongPress: () => _showServicePicker(index),
                      child: Container(
                        height: 95,
                        margin: EdgeInsets.only(left: index == 2 ? 0 : 12),
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                service != null
                                    ? AppColors.accentBlue.withValues(alpha: 0.4)
                                    : (widget.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05)),
                            width: service != null ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 
                                widget.isDarkMode ? 0.2 : 0.05,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                            if (service != null && widget.isDarkMode)
                              BoxShadow(
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: -2,
                              ),
                          ],
                        ),
                        child:
                            service != null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accentBlue.withValues(alpha: 
                                          0.1,
                                        ),
                                        boxShadow: [
                                          if (widget.isDarkMode)
                                            BoxShadow(
                                              color: AppColors.accentBlue
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                        ],
                                      ),
                                      child: Icon(
                                        service['icon'],
                                        color: AppColors.adaptiveIcon(
                                          widget.isDarkMode,
                                        ),
                                        size: 22,
                                      ),
                                    ),
                                    // Verification Banner
                                    if (!_isAccountConfirmed && !_isKycPending)
                                      _buildVerificationBanner(),

                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        service['title'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                                : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentBlue.withValues(alpha: 
                                      0.05,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: AppColors.accentBlue.withValues(alpha: 
                                      0.5,
                                    ),
                                    size: 24,
                                  ),
                                ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // All Services Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'all_services'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildAllServicesGrid(),
            ],
          ),
        ),

        // Recent Transactions Section REMOVED as per user request
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _handleServiceNavigation(String title) async {
    // Browsing Allowed Policy: We no longer block entry to screens.
    // Security guards are now implemented inside the execution buttons of the child screens.

    if (title == 'switch_shared_account'.tr()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  TransferToSubscriberScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result == true) _fetchData(forceRefresh: true);
    } else if (title == 'saifi_cash'.tr()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SaifiTransferScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result == true) _fetchData(forceRefresh: true);
    } else if (title == 'transfer_between_my_accounts'.tr()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  TransferBetweenAccountsScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result == true) _fetchData(forceRefresh: true);
    } else if (title == 'send_a_local_money_transfer'.tr()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  SelectLocalNetworkScreen(isDarkMode: widget.isDarkMode),
        ),
      );
    } else if (title == 'transfer_status'.tr()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LocalTransferStatusCancelScreen(
                isDarkMode: widget.isDarkMode,
                title: 'transferStatus'.tr(),
                icon: Icons.fact_check_rounded,
              ),
        ),
      );
    } else if (title == 'cancel_transfer'.tr()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LocalTransferStatusCancelScreen(
                isDarkMode: widget.isDarkMode,
                title: 'cancel_transfer_title'.tr(),
                icon: Icons.cancel_schedule_send_rounded,
                rules: [
                  'cancel_transfer_rule_1'.tr(),
                  'cancel_transfer_rule_2'.tr(),
                ],
              ),
        ),
      );
    } else if (title == 'receiving_a_network_transfer'.tr()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ReceiveTransferRequestScreen(isDarkMode: widget.isDarkMode),
        ),
      );
    }else if (title == 'cash_withdrawal_request'.tr()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CashWithdrawalScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result == true) _fetchData(forceRefresh: true);
    } else if (title == 'payment_for_purchases'.tr()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PayPurchasesScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result == true) _fetchData(forceRefresh: true);
    } else if (title == 'shipping_and_payment'.tr()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  RechargeAndPaymentScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result == true) _fetchData(forceRefresh: true);
    } else if (title == 'service_points'.tr()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LocationsViewScreen(isDarkMode: widget.isDarkMode),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${"service_will_activated".tr()} $title ${"soon".tr()}',
            style: const TextStyle(),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildAllServicesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allServices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _handleServiceNavigation(allServices[index]['title']),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 
                    widget.isDarkMode ? 0.4 : 0.08,
                  ),
                  blurRadius: 6,
                  offset: const Offset(3, 3),
                ),
                BoxShadow(
                  color:
                      widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                  blurRadius: 6,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    boxShadow: [
                      if (widget.isDarkMode)
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Icon(
                    allServices[index]['icon'] as IconData,
                    color: AppColors.adaptiveIcon(widget.isDarkMode),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  allServices[index]['title'] as String,
                  style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ).animate().scale(delay: (index * 20).ms, duration: 200.ms);
      },
    );
  }

  Widget _buildRecentTransactions({int? limit}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'service_operations'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AllTransactionsScreen(
                            isDarkMode: widget.isDarkMode,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 20),
                label: Text(
                  'latest_operations'.tr(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTransactionsList(limit: limit),
      ],
    );
  }

  Widget _buildTransactionsList({int? limit}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Apply Filter based on transaction direction (inferred from balance change)
    List<OperationHistoryModel> filteredTransactions = _transactions;
    if (_historyFilter == 'sent') {
      filteredTransactions =
          _transactions.where((t) {
            final bBefore = double.tryParse(t.balanceBefore) ?? 0.0;
            final bAfter = double.tryParse(t.balanceAfter) ?? 0.0;
            return bAfter < bBefore;
          }).toList();
    } else if (_historyFilter == 'received') {
      filteredTransactions =
          _transactions.where((t) {
            final bBefore = double.tryParse(t.balanceBefore) ?? 0.0;
            final bAfter = double.tryParse(t.balanceAfter) ?? 0.0;
            return bAfter > bBefore;
          }).toList();
    }

    final recentTransactions =
        limit != null
            ? filteredTransactions.take(limit).toList()
            : filteredTransactions;

    if (recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 60,
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              const SizedBox(height: 15),
              Text(
                'no_latest_operations'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children:
          recentTransactions.map((t) => _buildTransactionItem(t)).toList(),
    );
  }

  void _showOperationDetails(OperationHistoryModel transaction) {
    final dateFormat = intl.DateFormat('dd/MM/yyyy HH:mm', 'en_US');

    List<ReceiptRowData> details = [];
    if (transaction.referenceNumber.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: transaction.getReferenceLabelKey().tr(),
          value: transaction.referenceNumber,
          isCopyable: true,
        ),
      );
    }
    details.add(
      ReceiptRowData(
        label: 'transactionType'.tr(),
        value: transaction.operationTypeDisplay,
      ),
    );
    // details.add(
    //   ReceiptRowData(
    //     label: 'operation_amount'.tr(),
    //     value:
    //         '${amountFormatter.format(double.tryParse(transaction.amount) ?? 0)} ${transaction.currency}',
    //     isCopyable: true,
    //   ),
    // );
    if (transaction.fee != '0' && transaction.fee.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: 'operation_fee'.tr(),
          value:
              '${formatAmountDisplay(double.tryParse(transaction.fee) ?? 0)} ${transaction.currency}',
        ),
      );
    }
    // if (transaction.balanceBefore.isNotEmpty &&
    //     transaction.balanceBefore != '0') {
    //   details.add(
    //     ReceiptRowData(
    //       label: 'operation_balance_before'.tr(),
    //       value:
    //           '${amountFormatter.format(double.tryParse(transaction.balanceBefore) ?? 0)} ${transaction.currency}',
    //     ),
    //   );
    // }
    // if (transaction.balanceAfter.isNotEmpty &&
    //     transaction.balanceAfter != '0') {
    //   details.add(
    //     ReceiptRowData(
    //       label: 'operation_balance_after'.tr(),
    //       value:
    //           '${amountFormatter.format(double.tryParse(transaction.balanceAfter) ?? 0)} ${transaction.currency}',
    //     ),
    //   );
    // }
    final balanceBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
    final balanceAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
    final isIncoming = balanceAfter > balanceBefore;

    if (transaction.relatedUserName != null &&
        transaction.relatedUserName!.isNotEmpty) {
      if (isIncoming) {
        details.add(
          ReceiptRowData(label: 'المستفيد', value: '$_fullName\n$_username'),
        );
        details.add(
          ReceiptRowData(label: 'المودع', value: transaction.relatedUserName!),
        );
      } else {
        details.add(
          ReceiptRowData(
            label: 'المستفيد',
            value: transaction.relatedUserName!,
          ),
        );
        details.add(
          ReceiptRowData(label: 'المودع', value: '$_fullName\n$_username'),
        );
      }
    }
    details.add(
      ReceiptRowData(
        label: 'operation_date'.tr(),
        value: dateFormat.format(transaction.createdAt.toLocal()),
      ),
    );
    if (transaction.description.isNotEmpty &&
        OperationHistoryModel.remittanceTypes.contains(
          transaction.operationType,
        )) {
      details.add(
        ReceiptRowData(
          label: 'operation_description'.tr(),
          value: transaction.description,
        ),
      );
    }

    ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'operation_details_title'.tr(),
      mainAmount:
          formatAmountDisplay(double.tryParse(transaction.amount) ?? 0),
      mainCurrency: transaction.currency,
      details: details,
      amountColor: isIncoming ? Colors.green : Colors.red,
    );
  }

  Widget _buildTransactionItem(OperationHistoryModel transaction) {
    final type = transaction.operationType;
    final currency = transaction.currency;
    final date = transaction.createdAt.toLocal();
    final timeFormat = intl.DateFormat('hh:mm a', 'en_US');
    final dateFormat = intl.DateFormat('dd/MM/yyyy', 'en_US');

    final bBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
    final bAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
    final isPositive = bAfter > bBefore;

    final icon = OperationTypeHelper.getIcon(type);
    final iconColor = isPositive ? Colors.green : Colors.red;
    final title = transaction.operationTypeDisplay;

    String getCurrencyAr(String code) {
      if (code == 'YER') return 'yer'.tr();
      if (code == 'USD') return 'usd'.tr();
      if (code == 'SAR') return 'sar'.tr();
      return code;
    }

    final currencyAr = getCurrencyAr(currency);

    return GestureDetector(
      onTap: () => _showOperationDetails(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            // Styled Icon Container
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 15),

            // Transaction Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.description.isNotEmpty)
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            widget.isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(date)} | ${timeFormat.format(date)}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              widget.isDarkMode ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? "+" : "-"}${formatAmountDisplay(double.tryParse(transaction.amount) ?? 0)}',
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  currencyAr,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white54 : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHistoryContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildLargeHistoryButton(
                title: 'latest_operations'.tr(),
                subtitle: 'all_previous_conversions'.tr(),
                icon: Icons.history_rounded,
                color: AppColors.primaryBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AllTransactionsScreen(isDarkMode: isDark),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildLargeHistoryButton(
                title: 'accountStatement'.tr(),
                subtitle: 'accountStatementSubtitle'.tr(),
                icon: Icons.description_rounded,
                color: AppColors.accentBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AllTransactionsScreen(
                            isDarkMode: isDark,
                            isOpenFilter: true,
                            title: 'accountStatement'.tr(),
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildLargeHistoryButton(
                title: 'custom_search'.tr(),
                subtitle: 'search_for_transactions_date_or_amount'.tr(),
                icon: Icons.manage_search_rounded,
                color: const Color(0xFF009688),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomSearchScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              _buildLargeHistoryButton(
                title: 'بحث بالرقم المرجعي',
                subtitle: 'البحث عن عملية معينة بالرقم المرجعي',
                icon: Icons.manage_search_rounded,
                color: const Color(0xFF009688),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder:
                        (_) => TransactionReferenceDialog(
                          isDarkMode: widget.isDarkMode,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLargeHistoryButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const SizedBox(height: 15),
        // Profile Image
        Center(
          child: GestureDetector(
            onTap: () async {
              if (!await ApiService.checkVerification(
                context,
                isDarkMode: widget.isDarkMode,
                onVerifyNavigate:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AccountConfirmationScreen(
                              isDarkMode: widget.isDarkMode,
                            ),
                      ),
                    ),
              )) {
                return;
              }
              _pickImage();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.cardDark,
                backgroundImage:
                    _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                child:
                    _profileImageBytes == null
                        ? const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 60,
                        )
                        : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _fullName.isNotEmpty ? _fullName : 'full_name'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_username.isNotEmpty)
          Text(
            _username,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textGreyLight,
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 1),

        // Account Info Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showMyQRCode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Removed Spacer to prevent RenderBox error in Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'user_name'.tr(),
                      style: TextStyle(
                        color:
                            isDark
                                ? Colors.white54
                                : AppColors.textBlack.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _username.isNotEmpty ? _username : '---',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Container(
                  height: 30,
                  width: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'alternative_number'.tr(),
                      style: TextStyle(
                        color:
                            isDark
                                ? Colors.white54
                                : AppColors.textBlack.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      (_altNumber.isNotEmpty ? _altNumber : '---'),
                      // _isAccountConfirmed
                      //     ? (_altNumber.isNotEmpty ? _altNumber : '---')
                      //     : '********',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Settings List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildProfileItem(
                'update_application_data'.tr(),
                Icons.cloud_download_rounded,
                hasArrow: false,
                onTap: () {
                  _fetchData();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('done'.tr())));
                },
              ),
              _buildProfileItem(
                'device_management'.tr(),
                Icons.phonelink_setup_rounded,
                hasArrow: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              DeviceManagementScreen(isDarkMode: isDark),
                    ),
                  );
                },
              ),
              _buildProfileItem(
                'updating_ID_data'.tr(),
                Icons.badge_rounded,
                hasArrow: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AccountConfirmationScreen(
                            isDarkMode: isDark,
                            isUpdating: true,
                          ),
                    ),
                  );
                },
              ),
              // ==========================================
              // إدارة المفضلة والاقتراحات - قائمة منسدلة
              // ==========================================
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.cardDark.withValues(alpha: 0.5)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    visualDensity: const VisualDensity(vertical: -4),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Icon(
                      Icons.contact_phone_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.primaryBlue.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    title: Text(
                      'manage_favorites_and_suggestions'.tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      // إدارة المفضلة
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.favorite_rounded,
                        title: 'manage_favorites'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      FavoritesScreen(isDarkMode: isDark),
                            ),
                          );
                        },
                      ),
                      // إدارة الاقتراحات
                      // _buildSupportSubItem(
                      //   isDark: isDark,
                      //   icon: Icons.contact_phone_rounded,
                      //   title: 'manage_suggestions'.tr(),
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder:
                      //             (context) => ChatBotScreen(
                      //               isDarkMode: isDark,
                      //               userName: _firstName,
                      //               userPhoneNumber: _username,
                      //             ),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // ==========================================
              // الخصوصية والأمان - قائمة منسدلة
              // ==========================================
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.cardDark.withValues(alpha: 0.5)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    visualDensity: const VisualDensity(vertical: -4),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Icon(
                      Icons.security_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.primaryBlue.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    title: Text(
                      'privacy_and_security'.tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      // تغيير كلمة المرور
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.lock_outline_rounded,
                        title: 'change_password'.tr(),
                        onTap: () async {
                          if (!await ApiService.checkVerification(
                            context,
                            isDarkMode: widget.isDarkMode,
                            onVerifyNavigate:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AccountConfirmationScreen(
                                          isDarkMode: widget.isDarkMode,
                                        ),
                                  ),
                                ),
                          )) {
                            return;
                          }
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChangePasswordScreen(
                                    isDarkMode: widget.isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),
                      // مدة الجلسة
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.timer_rounded,
                        title: 'session_duration'.tr(),
                        onTap: _showSessionTimeoutDialog,
                      ),
                      // المزيد من الإعدادات
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.settings_rounded,
                        title: 'security_settings'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PrivacySecurityScreen(isDarkMode: isDark),
                            ),
                          );
                        },
                      ),
                      // الشروط والأحكام
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.description_rounded,
                        title: 'terms_and_conditions_title'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      TermsConditionsScreen(isDarkMode: isDark),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // إعدادات إضافية - قائمة منسدلة
              // ==========================================
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.cardDark.withValues(alpha: 0.5)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    visualDensity: const VisualDensity(vertical: -4),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Icon(
                      Icons.settings_suggest_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.primaryBlue.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    title: Text(
                      'additional_settings'.tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.store_rounded,
                        title: 'application_to_join_as_atrader_or_agent'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BusinessRegisterScreen(
                                    isDarkMode: isDark,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // ==========================================
              // المساعدة والدعم - قائمة منسدلة
              // ==========================================
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.cardDark.withValues(alpha: 0.5)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    visualDensity: const VisualDensity(vertical: -4),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Icon(
                      Icons.headset_mic_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.primaryBlue.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    title: Text(
                      'help_and_support'.tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      // الرقم المجاني
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.phone_rounded,
                        iconColor: Colors.green,
                        title: 'free_number'.tr(),
                        subtitle: '8000002',
                        onTap: () async {
                          final Uri phoneUri = Uri(
                            scheme: 'tel',
                            path: '8000002',
                          );
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          }
                        },
                      ),
                      // خدمة العملاء واتساب
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.chat_bubble_rounded,
                        iconColor: AppColors.accentBlue,
                        title: 'customer_service'.tr(),
                        subtitle: 'whatsapp'.tr(),
                        onTap: _launchWhatsApp,
                      ),
                      // مواقع التواصل
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.favorite_rounded,
                        iconColor: const ui.Color.fromARGB(255, 128, 0, 42),
                        title: 'social_media'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      SocialMediaScreen(isDarkMode: isDark),
                            ),
                          );
                        },
                      ),
                      // نقاط الخدمة
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.location_on_rounded,
                        iconColor: Colors.orange,
                        title: 'service_points'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      LocationsViewScreen(isDarkMode: isDark),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // ==========================================
              // تخصيص التطبيق - قائمة منسدلة
              // ==========================================
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.cardDark.withValues(alpha: 0.5)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    visualDensity: const VisualDensity(vertical: -4),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Icon(
                      Icons.palette_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.primaryBlue.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    title: Text(
                      'app_customization'.tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      // اللغة
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.language_rounded,
                        title: 'language'.tr(),
                        onTap: _showLanguagePicker,
                      ),
                      // مظهر التطبيق
                      _buildSupportSubItem(
                        isDark: isDark,
                        icon: Icons.dark_mode_rounded,
                        title: 'app_appearance'.tr(),
                        onTap: _showThemePicker,
                      ),
                      // مدة الجلسة
                      // _buildSupportSubItem(
                      //   isDark: isDark,
                      //   icon: Icons.timer_rounded,
                      //   title: 'session_duration'.tr(),
                      //   onTap: _showSessionTimeoutDialog,
                      // ),
                    ],
                  ),
                ),
              ),

              _buildProfileItem(
                'saifa_app_shared'.tr(),
                Icons.share_rounded,
                hasArrow: false,
                onTap: _shareApp,
              ),
              _buildProfileItem(
                'wallet_cancellation_request'.tr(),
                Icons.cancel_outlined,
                hasArrow: false,
                onTap: _showWalletClosureDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton(
            onPressed: () {
              _showConfirmExitDialog(isLogout: true);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.logout_rounded, color: AppColors.accentBlue),
                const SizedBox(width: 15),
                Text(
                  'logout'.tr(),
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'V 0.3.9.3',
          style: TextStyle(
            color:
                isDark
                    ? Colors.white24
                    : AppColors.textGreyLight.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(),
      ],
    );
  }

  void _showWalletClosureDialog() {
    String selectedReason = 'SECURITY';
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor:
                      widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'طلب إلغاء المحفظة',
                        style: TextStyle(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'يرجى اختيار سبب الإلغاء',
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                widget.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white10
                                      : Colors.black12,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedReason,
                              isExpanded: true,
                              dropdownColor:
                                  widget.isDarkMode
                                      ? AppColors.cardDark
                                      : Colors.white,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'FINANCIAL',
                                  child: Text('أسباب مالية'),
                                ),
                                DropdownMenuItem(
                                  value: 'SECURITY',
                                  child: Text('أسباب أمنية'),
                                ),
                                DropdownMenuItem(
                                  value: 'ALTERNATIVE',
                                  child: Text('وجود بديل'),
                                ),
                                DropdownMenuItem(
                                  value: 'POOR_SERVICE',
                                  child: Text('سوء الخدمة'),
                                ),
                                DropdownMenuItem(
                                  value: 'OTHER',
                                  child: Text('أسباب أخرى'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedReason = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          style: TextStyle(
                            color:
                                widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ملاحظات إضافية (اختياري)',
                            hintStyle: TextStyle(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white38
                                      : Colors.black38,
                            ),
                            filled: true,
                            fillColor:
                                widget.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isSubmitting ? null : () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color:
                              widget.isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSubmitting
                              ? null
                              : () async {
                                setDialogState(() => isSubmitting = true);
                                try {
                                  await ApiService.requestWalletClosure(
                                    reason: selectedReason,
                                    notes: notesController.text,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم إرسال طلب الإلغاء بنجاح',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setDialogState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('حدث خطأ: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'تأكيد',
                                style: const TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
          ),
    );
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
            const SnackBar(content: Text('تطبيق واتساب غير مثبت')),
          );
        }
      }
    } catch (e) {
      customPrint('Error launching WhatsApp: $e');
      // Attempt web launch as last resort if catch happens
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب')));
        }
      }
    }
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'customize_the_appearance'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                'light_mode'.tr(),
                Icons.light_mode_rounded,
                ThemeMode.light,
              ),
              _buildThemeOption(
                'dark_mode'.tr(),
                Icons.dark_mode_rounded,
                ThemeMode.dark,
              ),
              _buildThemeOption(
                'automatic_system'.tr(),
                Icons.brightness_auto_rounded,
                ThemeMode.system,
              ),
              const SizedBox(height: 25),
              Text(
                'accent_color'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildAccentColorRow(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccentColorRow() {
    final List<Color> colors = [
      const Color(0xFF173BA2), // الأزرق الأصلي
      const Color(0xFF00C853), // الأخضر
      const Color(0xFFFF6F00), // البرتقالي
      const Color(0xFFD32F2F), // الأحمر
      const Color(0xFFE91E63), // الزهري
      const Color(0xFF673AB7), // البنفسجي
      const Color(0xFF00ACC1), // الفيروزي
      const Color(0xFFFDD835), // الأصفر
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            colors.map((color) {
              bool isSelected = themeService.accentColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => themeService.setAccentColor(color),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                            : null,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, ThemeMode mode) {
    bool isSelected = themeService.themeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accentBlue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : AppColors.textBlack,

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
        // We might need to handle rebuilding flags if local state depends on widget.isDarkMode
      },
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: 'استخدم تطبيق محفظة صيفي باي لتسهيل معاملاتك المالية! حمل التطبيق الآن: [رابط التطبيق هنا]',
        subject: 'تطبيق محفظة صيفي باي',
      ),
    );
  }

  Widget _buildFixedHeader() {
    if (_selectedTab == 3) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // تحديد محتوى الرأس بناءً على التبويب المختار
    Widget headerContent;
    if (_selectedTab == 0 || _selectedTab == 1) {
      headerContent = _buildHeader();
    } else {
      String title = '';
      // if (_selectedTab == 1) title = 'wallet'.tr();
      if (_selectedTab == 2) title = 'other'.tr();
      headerContent = _buildSecondaryHeader(title);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          // Row of Arrows Pattern behind the header
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.08,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  8,
                  (index) => Transform.rotate(
                    angle: math.pi / 4, // Diagonal
                    child: Icon(
                      Icons.double_arrow_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
          headerContent,
        ],
      ),
    );
  }

  Widget _buildSecondaryHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedTab = 0),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : AppColors.textBlack,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_language'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(
                'العربية',
                Icons.language_rounded,
                const Locale('ar'),
              ),
              _buildLanguageOption(
                'English',
                Icons.language_rounded,
                const Locale('en'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String title, IconData icon, Locale locale) {
    final bool isSelected = context.locale == locale;
    return GestureDetector(
      onTap: () async {
        await context.setLocale(locale);
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : (widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected
                        ? AppColors.primaryBlue
                        : (widget.isDarkMode ? Colors.white : Colors.black87),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    String title,
    IconData icon, {
    bool hasArrow = false,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.cardDark.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  iconColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.primaryBlue.withValues(alpha: 0.6)),
              size: 20,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textBlack,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (hasArrow)
              Icon(
                Icons.keyboard_arrow_left_rounded,
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
              ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر داخل قائمة المساعدة والدعم المنسدلة
  Widget _buildSupportSubItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.cardDark.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  iconColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.primaryBlue.withValues(alpha: 0.6)),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textBlack,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // اكتشاف اتجاه اللغة (افتراض: 'ar' للعربية)
    final locale = Localizations.localeOf(context);
    final bool isRtl = locale.languageCode.toLowerCase().startsWith('ar');

    // أي عناصر نريد عرضها على "الجهة الأيقونات" و "جهة الترحيب"
    final Widget iconsRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChatBotScreen(
                      isDarkMode: widget.isDarkMode,
                      userName: _firstName.isNotEmpty ? _firstName : "نجم صيفي",
                      userPhoneNumber: _username,
                    ),
              ),
            );
          },
          child: _buildRoundIcon(
            Icons.smart_toy_rounded,
            isNotification: false,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showNotificationsDialog,
          child: _buildRoundIcon(
            Icons.notifications_none_rounded,
            isNotification: true,
            showBadge: _hasUnreadNotifications,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showMyQRCode,
          child: _buildRoundIcon(
            Icons.qr_code_scanner_rounded,
            isNotification: false,
          ),
        ),
      ],
    );

    final Widget greetingColumn = Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          _getGreeting(),
          textDirection: isRtl ? ui.TextDirection.ltr : ui.TextDirection.rtl,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _firstName.isNotEmpty ? _firstName : 'welecom_back'.tr(),
          textDirection: isRtl ? ui.TextDirection.ltr : ui.TextDirection.rtl,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    // نرتب عناصر الـ Row بحسب اتجاه اللغة: إذا RTL نضع الترحيب على اليمين (أولاً) ثم الأيقونات
    final List<Widget> mainRowChildren =
        isRtl ? [iconsRow, greetingColumn] : [greetingColumn, iconsRow];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mainRowChildren,
          ),

          const SizedBox(height: 8),

          // Centered Refresh Hint with Arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                textDirection:
                    isRtl ? ui.TextDirection.ltr : ui.TextDirection.rtl,
              ),
              const SizedBox(width: 4),
              Text(
                'swipe_down_to_refresh'.tr(),
                textDirection:
                    isRtl ? ui.TextDirection.ltr : ui.TextDirection.rtl,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                textDirection:
                    isRtl ? ui.TextDirection.ltr : ui.TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Widget _buildHeader() {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 10),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         // Main Header Row
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             // Left Side: Icons
  //             Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 GestureDetector(
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder:
  //                             (context) => ChatBotScreen(
  //                               isDarkMode: widget.isDarkMode,
  //                               userName:
  //                                   _firstName.isNotEmpty
  //                                       ? _firstName
  //                                       : "نجم صيفي",
  //                               userPhoneNumber: _username,
  //                             ),
  //                       ),
  //                     );
  //                   },
  //                   child: _buildRoundIcon(
  //                     Icons.smart_toy_rounded,
  //                     isNotification: false,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 GestureDetector(
  //                   onTap: _showNotificationsDialog,
  //                   child: _buildRoundIcon(
  //                     Icons.notifications_none_rounded,
  //                     isNotification: true,
  //                     showBadge: _hasUnreadNotifications,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 GestureDetector(
  //                   onTap: _showMyQRCode,
  //                   child: _buildRoundIcon(
  //                     Icons.qr_code_scanner_rounded,
  //                     isNotification: false,
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             // Right Side: Greeting
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Text(
  //                   _getGreeting(),
  //                   style: TextStyle(
  //                     color: isDark ? Colors.white : AppColors.textBlack,
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 Text(
  //                   _firstName.isNotEmpty ? _firstName : 'welecom_back'.tr(),
  //                   style: TextStyle(
  //                     color: isDark ? AppColors.textWhite : AppColors.textBlack,
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 8),

  //         // Centered Refresh Hint with Arrows
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               Icons.keyboard_arrow_down_rounded,
  //               size: 16,
  //               color: widget.isDarkMode ? Colors.white38 : Colors.black38,
  //             ),
  //             const SizedBox(width: 4),
  //             Text(
  //               'swipe_down_to_refresh'.tr(),
  //               style: TextStyle(
  //                 color: widget.isDarkMode ? Colors.white38 : Colors.black38,
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(width: 4),
  //             Icon(
  //               Icons.keyboard_arrow_down_rounded,
  //               size: 16,
  //               color: widget.isDarkMode ? Colors.white38 : Colors.black38,
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRoundIcon(
    IconData icon, {
    required bool isNotification,
    bool showBadge = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
            ],
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : AppColors.primaryBlue,
            size: 24,
          ),
        ),
        if (isNotification && showBadge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.glowBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.scaffoldDark : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Premium Horizontal Card Swiper
  Widget _build3DCardSwiper() {
    final List<Map<String, dynamic>> cards = [
      {
        'title': 'us_Dollar_account'.tr(),
        'balance': _balances['USD'] ?? '0.00',
        'currency': 'USD',
        'icon': Icons.attach_money_rounded,
      },
      {
        'title': 'yer_account'.tr(),
        'balance': _balances['YER'] ?? '0.00',
        'currency': 'YER',
        'icon': Icons.account_balance_rounded,
      },
      {
        'title': 'sar_account'.tr(),
        'balance': _balances['SAR'] ?? '0.00',
        'currency': 'SAR',
        'icon': Icons.currency_exchange_rounded,
      },
    ];

    return Column(
      children: [
        RepaintBoundary(
          child: SizedBox(
            height:
                145, // Reduced from 160/175 to eliminate internal gap completely
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: cards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _lastCardPage = index;
                });
                // Sync with global balance service
                final String currency = cards[index]['currency'];
                balanceService.setCurrency(currency);
              },
              itemBuilder: (context, index) {
                return ValueListenableBuilder<double>(
                  valueListenable: _pageOffsetNotifier,
                  builder: (context, pageOffset, child) {
                    double relativePosition = index - pageOffset;

                    return Transform(
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..scale(1.0 - (relativePosition.abs() * 0))
                            ..translate(relativePosition * 25, 0.0)
                            ..rotateX(
                              -0.25 * relativePosition.abs().clamp(0.0, 1.0),
                            )
                            ..rotateY(-relativePosition * 0.60),
                      alignment: Alignment.center,
                      child: _buildWalletCard(index, cards[index]),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Dots Indicator like in the image
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            cards.length,
            (index) => Container(
              width: _currentIndex == index ? 8 : 6,
              height: _currentIndex == index ? 8 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? Colors.white : Colors.white24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(int index, Map<String, dynamic> card) {
    final String title = card['title'];
    final String balance = card['balance'];
    final String currency = card['currency'];
    final List<Color> activeGradient = [
      AppColors.primaryBlue,
      AppColors.accentBlue,
    ];
    final List<Color> inactiveGradient =
        widget.isDarkMode
            ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)]
            : [Colors.grey.shade400, Colors.grey.shade600];

    final List<Color> gradient =
        index == _currentIndex ? activeGradient : inactiveGradient;
    final IconData icon = card['icon'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CurrencyTransactionsScreen(
                  isDarkMode: widget.isDarkMode,
                  currency: currency,
                  initialBalance: balance,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'logo_circle.png',
                    width: 90,
                    errorBuilder:
                        (c, e, s) => const Icon(
                          Icons.account_balance_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'account'.tr(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                title.replaceAll('account'.tr(), ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _showBalances[index]
                                ? TweenAnimationBuilder<double>(
                                  key: ValueKey(
                                    'balance_anim_${index}_$balance',
                                  ),
                                  tween: Tween(
                                    begin: 0.0,
                                    end: double.tryParse(balance) ?? 0.0,
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutExpo,
                                  builder: (context, value, child) {
                                    return RepaintBoundary(
                                      child: Text(
                                        formatAmountDisplay(value),
                                        textDirection: ui.TextDirection.ltr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.06,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Text(
                                  '******',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.06,
                                    letterSpacing: 4,
                                  ),
                                ),
                            Text(
                              '${"available_balance".tr()}$currency',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.025,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap:
                              () => setState(
                                () =>
                                    _showBalances[index] =
                                        !_showBalances[index],
                              ),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showBalances[index]
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionBanner() {
    if (_isBannersLoading && _adBanners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Shimmer.fromColors(
          baseColor: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor:
              widget.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    if (_adBanners.isEmpty) {
      // Default Saifi Cash Ad
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildBannerSlide(
              gradient: [AppColors.primaryBlue, AppColors.accentBlue],
              title: 'al_Saifi_exchange_company'.tr(),
              subtitle: 'company_everywhere'.tr(),
              useLogo: true,
              imagePath: 'assets/images/ad.png',
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _adBanners.length,
            itemBuilder: (context, index) {
              final ad = _adBanners[index];
              //customPrint("===========ad banner ${ad.image}");
              return _buildDynamicAdSlide(ad);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAdSlide(AdBanner ad) {
    if (ad.isImage) {
      return CachedNetworkImage(
        imageUrl: ad.image,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        errorWidget:
            (c, e, s) => Center(
              child: Icon(
                Icons.image_not_supported_rounded,
                color: AppColors.primaryBlue,
                size: 45,
              ),
            ),
      );
    }

    return Row(
      children: [
        Container(
          width: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withValues(alpha: 0.1),
                AppColors.accentBlue.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: CachedNetworkImage(
              imageUrl: ad.image,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder:
                  (context, url) => Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
              errorWidget:
                  (c, e, s) => Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: AppColors.primaryBlue,
                      size: 45,
                    ),
                  ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ad.title,
                  style: TextStyle(
                    color:
                        widget.isDarkMode
                            ? Colors.white
                            : AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ad.subtitle != null)
                  Text(
                    ad.subtitle!,
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.white70
                              : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSlide({
    required List<Color> gradient,
    IconData? icon,
    required String title,
    required String subtitle,
    bool useLogo = false,
    String? imagePath,
  }) {
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (c, e, s) => Center(
              child: Icon(
                icon ?? Icons.image_not_supported_rounded,
                color: AppColors.primaryBlue,
                size: 45,
              ),
            ),
      );
    }

    return Row(
      children: [
        Container(
          width: 120,
          decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child:
                  useLogo
                      ? Image.asset(
                        'pr_logo.png',
                        errorBuilder:
                            (c, e, s) => Icon(
                              icon ?? Icons.account_balance,
                              color: Colors.white,
                              size: 45,
                            ),
                      )
                      : Icon(icon ?? Icons.info, color: Colors.white, size: 45),
            ),
          ),
        ),
        /*
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.accentBlue, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        widget.isDarkMode
                            ? AppColors.textGreyDark
                            : AppColors.textGreyLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        */
      ],
    );
  }

  Widget _buildServicesGrid() {
    // تعريف الخدمات مع 'id' ثابت لاستخدامه في الـ switch
    final services = [
      {
        'id': 'money_transfers',
        'title': 'money_transfers'.tr(),
        'icon': Icons.swap_horiz_rounded,
      },
      {
        'id': 'saifi_cash',
        'title': 'saifi_cash'.tr(),
        'icon': Icons.send_rounded,
      },
      {
        'id': 'shipping_and_payment',
        'title': 'shipping_and_payment'.tr(),
        'icon': Icons.bolt_rounded,
      },
      // // {
      //   'id': 'buy_online',
      //   'title': 'buy_online'.tr(),
      //   'icon': Icons.shopping_cart_rounded,
      // },
      {
        'id': 'payment_for_purchases',
        'title': 'payment_for_purchases'.tr(),
        'icon': Icons.local_mall_rounded,
      },
      {
        'id': 'cash_withdrawal',
        'title': 'cash_withdrawal'.tr(),
        'icon': Icons.atm_rounded,
      },
      // {
      //   'id': 'payments',
      //   'title': 'payments'.tr(),
      //   'icon': Icons.payments_rounded,
      // },
      {
        'id': 'entertainment_services',
        'title': 'entertainment_services'.tr(),
        'icon': Icons.games_rounded,
      },
      // {
      //   'id': 'saifix',
      //   'title': 'saifix'.tr(),
      //   'icon': Icons.group_work_rounded,
      // },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final service = services[index];

          return GestureDetector(
            onTap: () {
              // استخدام الـ id للتبديل بين الصفحات
              final String serviceId = service['id'] as String;

              Widget? targetScreen;

              switch (serviceId) {
                case 'money_transfers':
                  targetScreen = FinancialTransfersScreen(
                    isDarkMode: widget.isDarkMode,
                  );
                  break;
                case 'cash_withdrawal':
                  targetScreen = CashWithdrawalScreen(
                    isDarkMode: widget.isDarkMode,
                  );
                  break;
                case 'payment_for_purchases':
                  targetScreen = PayPurchasesScreen(
                    isDarkMode: widget.isDarkMode,
                  );
                  break;
                case 'entertainment_services':
                  targetScreen = GamesEntertainmentScreen(
                    isDarkMode: widget.isDarkMode,
                  );
                  break;

                case 'saifi_cash':
                  targetScreen = SaifiTransferScreen(
                    isDarkMode: widget.isDarkMode,
                  );
                  break;

                case 'saifix':
                  targetScreen = SaifiScreen(isDarkMode: widget.isDarkMode);
                  break;
                case 'shipping_and_payment':
                  targetScreen = RechargeAndPaymentScreen(
                    isDarkMode: widget.isDarkMode,
                  );
                  break;
              }

              if (targetScreen != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => targetScreen!),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 
                      widget.isDarkMode ? 0.2 : 0.02,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      boxShadow: [
                        if (widget.isDarkMode)
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: AppColors.adaptiveIcon(widget.isDarkMode),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service['title'] as String,
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // Widget _buildServicesGrid() {
  //   final services = [
  //     {'title': 'money_transfers'.tr(), 'icon': Icons.swap_horiz_rounded},
  //     {'title': 'saifi_cash'.tr(), 'icon': Icons.send_rounded},
  //     {'title': 'shipping_and_payment'.tr(), 'icon': Icons.bolt_rounded},

  //     {'title': 'buy_online'.tr(), 'icon': Icons.shopping_cart_rounded},
  //     {'title': 'payment_for_purchases'.tr(), 'icon': Icons.local_mall_rounded},
  //     {'title': 'cash_withdrawal'.tr(), 'icon': Icons.atm_rounded},

  //     {'title': 'payments'.tr(), 'icon': Icons.payments_rounded},
  //     {'title': 'entertainment_services'.tr(), 'icon': Icons.games_rounded},
  //     {'title': 'saifix'.tr(), 'icon': Icons.group_work_rounded},
  //   ];

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 6),
  //     child: GridView.builder(
  //       shrinkWrap: true,
  //       padding: EdgeInsets.zero,
  //       physics: const NeverScrollableScrollPhysics(),
  //       itemCount: services.length,
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: 3,
  //         mainAxisSpacing: 8,
  //         crossAxisSpacing: 8,
  //         childAspectRatio: 1.4,
  //       ),
  //       itemBuilder: (context, index) {
  //         final service = services[index];

  //         return GestureDetector(
  //           onTap: () {
  //             final title = service['title'] as String;
  //             if (title == 'money_transfers'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) => FinancialTransfersScreen(
  //                         isDarkMode: widget.isDarkMode,
  //                       ),
  //                 ),
  //               );
  //             } else if (title == 'cash_withdrawal'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) =>
  //                           CashWithdrawalScreen(isDarkMode: widget.isDarkMode),
  //                 ),
  //               );
  //             } else if (title == 'payment_for_purchases'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) =>
  //                           PayPurchasesScreen(isDarkMode: widget.isDarkMode),
  //                 ),
  //               );
  //             } else if (title == 'entertainment_services'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) => GamesEntertainmentScreen(
  //                         isDarkMode: widget.isDarkMode,
  //                       ),
  //                 ),
  //               );
  //             } else if (title == 'payments'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) =>
  //                           PaymentsScreen(isDarkMode: widget.isDarkMode),
  //                 ),
  //               );
  //             } else if (title == 'saifi_cash'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) =>
  //                           SaifiTransferScreen(isDarkMode: widget.isDarkMode),
  //                 ),
  //               );
  //             } else if (title == 'buy_online'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) =>
  //                           OnlineShoppingScreen(isDarkMode: widget.isDarkMode),
  //                 ),
  //               );
  //             } else if (title.trim() == 'saifix'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) => SaifiScreen(isDarkMode: widget.isDarkMode),
  //                 ),
  //               );
  //             } else if (title == 'shipping_and_payment'.tr()) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) => RechargeAndPaymentScreen(
  //                         isDarkMode: widget.isDarkMode,
  //                       ),
  //                 ),
  //               );
  //             }
  //           },
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color:
  //                   widget.isDarkMode
  //                       ? Colors.white.withValues(alpha: 0.05)
  //                       : Colors.white,
  //               borderRadius: BorderRadius.circular(12),
  //               border: Border.all(
  //                 color:
  //                     widget.isDarkMode
  //                         ? Colors.white.withValues(alpha: 0.1)
  //                         : Colors.black.withValues(alpha: 0.05),
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withValues(alpha: 
  //                     widget.isDarkMode ? 0.2 : 0.02,
  //                   ),
  //                   blurRadius: 10,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(10),
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     color: AppColors.accentBlue.withValues(alpha: 0.1),
  //                     boxShadow: [
  //                       if (widget.isDarkMode)
  //                         BoxShadow(
  //                           color: AppColors.accentBlue.withValues(alpha: 0.2),
  //                           blurRadius: 8,
  //                           spreadRadius: 1,
  //                         ),
  //                     ],
  //                   ),
  //                   child: Icon(
  //                     service['icon'] as IconData,
  //                     color: AppColors.adaptiveIcon(widget.isDarkMode),
  //                     size: 20,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 6),
  //                 Text(
  //                   service['title'] as String,
  //                   style: TextStyle(
  //                     color:
  //                         widget.isDarkMode
  //                             ? Colors.white
  //                             : AppColors.textBlack,
  //                     fontSize: 11,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? AppColors.cardDark.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color:
              widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'home'.tr(), 0),
                _buildNavItem(
                  Icons.account_balance_wallet_rounded,
                  'wallet'.tr(),
                  1,
                ),
                const SizedBox(width: 20),
                _buildNavItem(Icons.receipt_long_rounded, 'report'.tr(), 2),
                _buildNavItem(Icons.person_2_rounded, 'accont'.tr(), 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMyQRCode() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 45, 20, 20),
                  decoration: BoxDecoration(
                    color:
                        widget.isDarkMode ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Screenshot(
                        controller: _qrScreenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color:
                              widget.isDarkMode
                                  ? AppColors.cardDark
                                  : Colors.white,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: _altNumber,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  embeddedImage: const AssetImage(
                                    'logo_circle.png',
                                  ),
                                  embeddedImageStyle:
                                      const QrEmbeddedImageStyle(
                                        size: Size(45, 45),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                'your_code'.tr(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white
                                          : AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'qr_scan_instruction'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white60
                                          : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _saveQRCode();
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 20,
                              ),
                              label: Text(
                                'save'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _shareQRCode();
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.share_rounded, size: 20),
                              label: Text(
                                'share'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey[100],
                                foregroundColor:
                                    widget.isDarkMode
                                        ? Colors.white
                                        : AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color:
                              widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveQRCode() async {
    try {
      final image = await _qrScreenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_code.png').create();
        await file.writeAsBytes(image);
        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('success'.tr()),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      customPrint('Error saving QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareQRCode() async {
    try {
      final image = await _qrScreenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_code.png').create();
        await file.writeAsBytes(image);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'my_qr_code'.tr()),
        );
      }
    } catch (e) {
      customPrint('Error sharing QR code: $e');
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? AppColors.accentBlue.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      isActive
                          ? AppColors.accentBlue
                          : (widget.isDarkMode
                              ? Colors.white54
                              : Colors.black45),
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color:
                      isActive
                          ? AppColors.accentBlue
                          : (widget.isDarkMode
                              ? Colors.white54
                              : Colors.black45),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors:
              _isMenuOpen
                  ? [AppColors.accentBlue, AppColors.primaryBlue]
                  : [AppColors.accentBlue, AppColors.glowBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: (_isMenuOpen ? AppColors.primaryBlue : AppColors.glowBlue)
                .withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          turns: _isMenuOpen ? 0.125 : 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            child:
                _isMenuOpen
                    ? const Icon(Icons.add, color: Colors.white, size: 32)
                    : Image.asset(
                      widget.isDarkMode ? 'pr_logo.png' : 'logo_circle.png',
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _isMenuOpen = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Stack(
            children: [
              Positioned(
                bottom: 95,
                left: 50,
                right: 50,
                child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode
                                ? AppColors.cardDark
                                : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                _buildMenuItem(
                                  'scan_the_code'.tr(),
                                  Icons.qr_code_2_rounded,
                                  onTap: () async {
                                    setState(() => _isMenuOpen = false);
                                    final result = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => QRScannerScreen(
                                              isDarkMode: widget.isDarkMode,
                                            ),
                                      ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      if (mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    TransferToSubscriberScreen(
                                                      isDarkMode:
                                                          widget.isDarkMode,
                                                      initialPhone: result,
                                                    ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                VerticalDivider(
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white10
                                          : Colors.black12,
                                  thickness: 1,
                                  width: 20,
                                  indent: 10,
                                  endIndent: 10,
                                ),
                                _buildMenuItem(
                                  'payment_to_merchant'.tr(),
                                  Icons.store_rounded,
                                  onTap: () {
                                    setState(() => _isMenuOpen = false);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PayPurchasesScreen(
                                              isDarkMode: widget.isDarkMode,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color:
                                widget.isDarkMode
                                    ? Colors.white10
                                    : Colors.black12,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                _buildMenuItem(
                                  'favorites'.tr(),
                                  Icons.favorite_border_rounded,
                                  onTap: () {
                                    setState(() => _isMenuOpen = false);
                                    // LoginDialog.show(
                                    //   context,
                                    //   isDarkMode: false,
                                    // );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => FavoritesScreen(
                                              isDarkMode: widget.isDarkMode,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                VerticalDivider(
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white10
                                          : Colors.black12,
                                  thickness: 1,
                                  width: 20,
                                  indent: 10,
                                  endIndent: 10,
                                ),
                                _buildMenuItem(
                                  'service_points'.tr(),
                                  Icons.location_on_rounded,
                                  onTap: () {
                                    setState(() => _isMenuOpen = false);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => LocationsViewScreen(
                                              isDarkMode: widget.isDarkMode,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      alignment: Alignment.bottomCenter,
                    )
                    .fade(duration: const Duration(milliseconds: 200))
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accentBlue, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionTimeoutDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int currentTimeout = await sessionManager.getSessionTimeout();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'مدة الجلسة'
                        : 'Session Timeout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...[3, 5, 7, 10].map((mins) {
                    final String title =
                        mins == 5
                            ? (context.locale.languageCode == 'ar'
                                ? 'افتراضي (5 دقائق)'
                                : 'Default (5 mins)')
                            : (context.locale.languageCode == 'ar'
                                ? '$mins دقائق'
                                : '$mins mins');
                    return RadioListTile<int>(
                      title: Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textBlack,
                        ),
                      ),
                      value: mins,
                      groupValue: currentTimeout,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        if (val != null) {
                          sessionManager.setSessionTimeout(val);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.locale.languageCode == 'ar'
                                    ? 'تم تغيير مدة الجلسة إلى $mins دقائق'
                                    : 'Session timeout changed to $mins mins',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showConfirmExitDialog({bool isLogout = false}) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                widget.isDarkMode ? AppColors.cardDark : Colors.white,
            elevation: 10,
            shadowColor: AppColors.primaryBlue.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(
                color:
                    widget.isDarkMode
                        ? Colors.white10
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with subtle glow effect
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        widget.isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.primaryBlue.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    widget.isDarkMode ? 'pr_logo.png' : 'logo_circle.png',
                    height: 70,
                    width: 70,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          isLogout
                              ? Icons.logout_rounded
                              : Icons.exit_to_app_rounded,
                          size: 50,
                          color: AppColors.primaryBlue,
                        ),
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                Text(
                  isLogout ? 'logout'.tr() : 'exit_app'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  isLogout ? 'msg_logout'.tr() : 'msg_exitapp'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        widget.isDarkMode
                            ? Colors.white70
                            : AppColors.textGreyLight,
                    height: 1.5,
                    // Ensure font consistency
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          if (isLogout) {
                            _performLogout();
                          } else {
                            exit(0); // Definitive exit
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryBlue, // Identity Color
                          elevation: 4,
                          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          isLogout ? 'ok'.tr() : 'ok'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor:
                              widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                        ),
                        child: Text(
                          'cancel'.tr(),
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _performLogout() async {
    sessionManager.stopSession();
    ApiService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildVerificationBanner() {
    if (_isAccountConfirmed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: AppColors.accentBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'account_is_not_verified'.tr(),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'account_verified'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AccountConfirmationScreen(
                        isDarkMode: widget.isDarkMode,
                      ),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'توثيق',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
