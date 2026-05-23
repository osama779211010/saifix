import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import 'pay_purchases_screen.dart';
import 'chatbot_screen.dart';
import 'recharge_and_payment_screen.dart';
import 'favorites_screen.dart';
import 'financial_transfers/all_transactions_screen.dart';
import 'financial_transfers/transfer_to_subscriber_screen.dart';
import 'pos_settings_screen.dart';
import 'pos_account_screen.dart';
import 'account_confirmation_screen.dart';
import '../models/operation_history.dart';
import '../utils/operation_type_helper.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/receipt_dialog.dart';
import '../helper/counvert_amunt_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_banner.dart';
import 'dart:async';

class POSHomeScreen extends StatefulWidget {
  const POSHomeScreen({super.key});

  @override
  State<POSHomeScreen> createState() => _POSHomeScreenState();
}

class _POSHomeScreenState extends State<POSHomeScreen> {
  bool _isLoading = false;
  final List<bool> _showBalances = [false, false, false];
  Map<String, String> _balances = {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};
  bool _isAccountConfirmed = true; // Default to true to avoid flicker
  List<OperationHistoryModel> _transactions = [];
  static int _lastWalletPage = 1;
  late final PageController _walletController = PageController(
    viewportFraction: 0.65,
    initialPage: _lastWalletPage,
  );
  int _currentWalletPage = _lastWalletPage;
  String _posName = 'نقطة المبيعات';
  String _posNumber = '';
  double _turns = 0.0;

  // Dynamic Advertisement Banners
  final PageController _bannerController = PageController();
  List<AdBanner> _adBanners = [];
  bool _isBannersLoading = true;
  Timer? _bannerTimer;

  // QR Code Screenshot Controller
  final ScreenshotController _qrScreenshotController = ScreenshotController();

  // POS Official Brand Colors (Saifi Pay)
  static const Color saifiNavy = Color(0xFF1F2D5D);

  @override
  void initState() {
    super.initState();
    _loadPOSInfo();
    _fetchData();
    _loadAds();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _loadPOSInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _posName = prefs.getString('pos_trade_name') ?? 'نقطة المبيعات';
        _posNumber = prefs.getString('pos_number') ?? '';
      });
    }
  }

  Future<void> _fetchData({bool forceRefresh = true}) async {
    setState(() => _isLoading = true);
    try {
      _loadAds();
      // Fetch balances and operations history in parallel for maximum speed
      final results = await Future.wait([
        ApiService.getBalances(forceRefresh: forceRefresh),
        ApiService.getOperationsHistory(pageSize: 5),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final history = results[1] as OperationHistoryResponse;

      if (mounted) {
        setState(() {
          _balances = {
            'YER': (balanceData['YER'] ?? 0.0).toString(),
            'USD': (balanceData['USD'] ?? 0.0).toString(),
            'SAR': (balanceData['SAR'] ?? 0.0).toString(),
          };
          _transactions = history.results;
        });

        // Also fetch user status for the verification banner
        final user = await ApiService.getMe();
        if (mounted) {
          setState(() {
            _isAccountConfirmed =
                user['is_verified'] ?? user['is_confirmed'] ?? false;
          });
        }
      }
    } catch (e) {
      customPrint('Error fetching POS data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAds() async {
    try {
      if (mounted) setState(() => _isBannersLoading = true);
      final ads = await ApiService.getAdBanners();
      if (mounted) {
        setState(() {
          _adBanners = ads;
          _isBannersLoading = false;
        });
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

  void _showMyQRCode() {
    final bool isDark = themeService.isDarkModeActive(context);
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
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Screenshot(
                        controller: _qrScreenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: isDark ? AppColors.cardDark : Colors.white,
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
                                  data: 'POS:$_posNumber',
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  embeddedImage: const AssetImage('logo_circle.png'),
                                  embeddedImageStyle: const QrEmbeddedImageStyle(
                                    size: Size(45, 45),
                                  ),
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: saifiNavy,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: saifiNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                'your_code'.tr(),
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'qr_scan_instruction'.tr(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
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
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: saifiNavy,
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
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey[100],
                                foregroundColor:
                                    isDark
                                        ? Colors.white
                                        : saifiNavy,
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
                              isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black54,
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = themeService.isDarkModeActive(context);
    final bgImage = isDark ? "back 1 .png" : "back2.png";
    final overlayColor =
        isDark
            ? AppColors.primaryBlue.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showConfirmExitDialog();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
        bottomNavigationBar: _buildBottomNav(isDark),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Directionality(
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
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(-20.0, -10.0),
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: overlayColor,
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => _fetchData(forceRefresh: true),
                  color: saifiNavy,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark),
                        const SizedBox(height: 10),
                        // Verification Banner
                        if (!_isAccountConfirmed) _buildVerificationBanner(isDark),
                        const SizedBox(height: 10),
                        _buildWalletCarousel(isDark),
                        const SizedBox(height: 10),
                        _buildCarouselIndicator(),
                        const SizedBox(height: 25),
                        _buildPromoBanner(isDark),
                        const SizedBox(height: 25),
                        _buildServiceGrid(isDark),
                        const SizedBox(height: 30),
                        _buildRecentTransactionsHeader(isDark),
                        _buildRecentTransactionsList(isDark),
                        const SizedBox(height: 100), // Bottom padding for nav
                      ],
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

  Widget _buildRoundIcon(IconData icon, {required bool isDark}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: isDark ? Colors.white : saifiNavy,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatBotScreen(
                            isDarkMode: isDark,
                            userName: _posName,
                            userPhoneNumber: _posNumber,
                          ),
                    ),
                  );
                },
                child: _buildRoundIcon(Icons.smart_toy_rounded, isDark: isDark),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showMyQRCode,
                child: _buildRoundIcon(Icons.qr_code_scanner_rounded, isDark: isDark),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'pos_welcome'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              Text(
                _posName,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : saifiNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCarousel(bool isDark) {
    final List<Map<String, dynamic>> wallets = [
      {
        'currency': 'currency_usd'.tr(),
        'code': 'USD',
        'icon': Icons.attach_money_rounded,
      },
      {
        'currency': 'currency_yer'.tr(),
        'code': 'YER',
        'icon': Icons.account_balance_rounded,
      },
      {
        'currency': 'currency_sar'.tr(),
        'code': 'SAR',
        'icon': Icons.currency_exchange_rounded,
      },
    ];

    return AnimatedBuilder(
      animation: _walletController,
      builder: (context, child) {
        double page = _lastWalletPage.toDouble();
        if (_walletController.hasClients) {
          page = _walletController.page ?? _lastWalletPage.toDouble();
        }

        return SizedBox(
          height: 145,
          child: PageView.builder(
            controller: _walletController,
            clipBehavior: Clip.none,
            onPageChanged: (idx) {
              setState(() {
                _currentWalletPage = idx;
                _lastWalletPage = idx;
              });
            },
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              double relativePosition = index - page;

              return Transform(
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..scale(1.0 - (relativePosition.abs() * 0))
                      ..translate(relativePosition * 25, 0.0)
                      ..rotateX(-0.25 * relativePosition.abs().clamp(0.0, 1.0))
                      ..rotateY(-relativePosition * 0.60),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: (1.0 - relativePosition.abs() * 0.55).clamp(
                    0.4,
                    1.0,
                  ),
                  child: _buildWalletCard(wallets[index], isDark, index),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet, bool isDark, int index) {
    final List<Color> activeGradient = [
      AppColors.primaryBlue,
      AppColors.accentBlue,
    ];
    final List<Color> inactiveGradient =
        isDark
            ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)]
            : [Colors.grey.shade400, Colors.grey.shade600];

    final List<Color> gradient =
        index == _currentWalletPage ? activeGradient : inactiveGradient;

    final String balance = _balances[wallet['code']] ?? '0.00';
    final IconData icon = wallet['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              wallet['currency'].toString().tr().replaceAll('account'.tr(), ''),
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
                            '${"available_balance".tr()} ${wallet['code']}',
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
    );
  }

  Widget _buildCarouselIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          width: _currentWalletPage == index ? 8 : 6,
          height: _currentWalletPage == index ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentWalletPage == index ? Colors.white : Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    if (_isBannersLoading && _adBanners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor:
              isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 75,
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
            color: isDark ? AppColors.cardDark : Colors.white,
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
              gradient: [saifiNavy, const Color(0xFF3B4D8D)],
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
          color: isDark ? AppColors.cardDark : Colors.white,
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
              return _buildDynamicAdSlide(ad);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAdSlide(AdBanner ad) {
    final bool isDark = themeService.isDarkModeActive(context);
    if (ad.isImage) {
      return CachedNetworkImage(
        imageUrl: ad.image,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: saifiNavy,
                ),
              ),
            ),
        errorWidget:
            (c, e, s) => const Center(
              child: Icon(
                Icons.image_not_supported_rounded,
                color: saifiNavy,
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
                saifiNavy.withValues(alpha: 0.1),
                const Color(0xFF3B4D8D).withValues(alpha: 0.1),
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
                  (context, url) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: saifiNavy,
                      ),
                    ),
                  ),
              errorWidget:
                  (c, e, s) => const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: saifiNavy,
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
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white : saifiNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ad.subtitle != null)
                  Text(
                    ad.subtitle!,
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
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
                color: saifiNavy,
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
      ],
    );
  }

  Widget _buildServiceGrid(bool isDark) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'service_pay_purchases',
        'icon': Icons.shopping_basket_rounded,
        'color': const Color(0xFF4A90E2),
        'screen':
            (BuildContext context) => PayPurchasesScreen(isDarkMode: isDark),
      },
      {
        'title': 'transfer_to_subscriber',
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFFF5A623),
        'screen':
            (BuildContext context) => TransferToSubscriberScreen(isDarkMode: isDark),
      },
      {
        'title': 'service_recharge_payment',
        'icon': Icons.bolt_rounded,
        'color': saifiNavy,
        'screen':
            (BuildContext context) =>
                RechargeAndPaymentScreen(isDarkMode: isDark),
      },
      {
        'title': 'service_operations',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFFBD10E0),
        'screen':
            (BuildContext context) => AllTransactionsScreen(isDarkMode: isDark),
      },
      {
        'title': 'favorites_title',
        'icon': Icons.favorite_rounded,
        'color': Colors.pinkAccent,
        'screen':
            (BuildContext context) => FavoritesScreen(isDarkMode: isDark),
      },
      {
        'title': 'service_settings',
        'icon': Icons.settings_suggest_rounded,
        'color': const Color(0xFF4A4A4A),
        'screen':
            (BuildContext context) => POSSettingsScreen(isDarkMode: isDark),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];
          final Color iconColor = s['color'] as Color;

          return GestureDetector(
            onTap: () async {
              // Guard sensitive POS services
              if (index != 5) {
                if (!await ApiService.checkVerification(
                  context,
                  isDarkMode: isDark,
                  onVerifyNavigate:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  AccountConfirmationScreen(isDarkMode: isDark),
                        ),
                      ),
                )) {
                  return;
                }
              }

              if (!context.mounted) return;

              if (s['screen'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: s['screen'] as Widget Function(BuildContext),
                  ),
                ).then((_) {
                  // Instant refresh of balances and transactions when coming back
                  _fetchData(forceRefresh: true);
                });
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('coming_soon'.tr())));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                      color: iconColor.withValues(alpha: 0.1),
                      boxShadow: [
                        if (isDark)
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: isDark ? Colors.white : iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (s['title'] as String).tr(),
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : AppColors.textBlack,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).animate().scale(delay: (index * 50).ms);
        },
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'recent_transactions'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : saifiNavy,
            ),
          ),
          Row(
            children: [
              GestureDetector(
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
                child: Text(
                  'view_all'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: saifiNavy));
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 50,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'empty_transactions'.tr(),
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(_transactions[index], isDark);
      },
    );
  }

  Widget _buildTransactionItem(OperationHistoryModel transaction, bool isDark) {
    final type = transaction.operationType;
    final currency = transaction.currency;
    final date = transaction.createdAt.toLocal();

    final bBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
    final bAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
    final isPositive = bAfter > bBefore;

    final icon = OperationTypeHelper.getIcon(type);
    final iconColor = isPositive ? Colors.green : Colors.red;
    final title = transaction.operationTypeDisplay;

    return GestureDetector(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.description.isNotEmpty)
                    Text(
                      transaction.description,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
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
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${intl.DateFormat('dd/MM/yyyy', 'en_US').format(date)} | ${intl.DateFormat('hh:mm a', 'en_US').format(date)}',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : '-'}${formatAmountDisplay(double.tryParse(transaction.amount) ?? 0)}',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: iconColor,
                  ),
                ),
                Text(
                  currency,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
    );
  }

  void _showTransactionDetails(OperationHistoryModel transaction) {
    final dateFormat = intl.DateFormat('yyyy/MM/dd hh:mm a', 'en_US');

    final List<ReceiptRowData> details = [];

    details.add(
      ReceiptRowData(
        label: 'referenceNumber'.tr(),
        value: transaction.referenceNumber,
      ),
    );

    details.add(
      ReceiptRowData(
        label: 'transactionType'.tr(),
        value: transaction.operationTypeDisplay,
      ),
    );

    if (transaction.fee != '0' && transaction.fee != '0.00') {
      details.add(
        ReceiptRowData(
          label: 'operation_fee'.tr(),
          value:
              '${formatAmountDisplay(double.tryParse(transaction.fee) ?? 0)} ${transaction.currency}',
        ),
      );
    }

    final balanceBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
    final balanceAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
    final isIncoming = balanceAfter > balanceBefore;

    if (transaction.relatedUserName != null &&
        transaction.relatedUserName!.isNotEmpty) {
      if (isIncoming) {
        details.add(
          ReceiptRowData(label: 'المستفيد', value: '$_posName\n$_posNumber'),
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
          ReceiptRowData(label: 'المودع', value: '$_posName\n$_posNumber'),
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
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      title: 'operation_details_title'.tr(),
      mainAmount:
          formatAmountDisplay(double.tryParse(transaction.amount) ?? 0),
      mainCurrency: transaction.currency,
      details: details,
      amountColor: isIncoming ? Colors.green : Colors.red,
    );
  }

  Widget _buildVerificationBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'verification_banner'.tr(),
              style: GoogleFonts.cairo(
                color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AccountConfirmationScreen(isDarkMode: isDark),
                  ),
                ),
            child: Text(
              'verify'.tr(),
              style: GoogleFonts.cairo(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
      color: isDark ? const Color(0xFF161C2E) : Colors.white,
      elevation: 20,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.home_rounded,
              'nav_home'.tr(),
              true,
              isDark,
              () {},
            ),
            _buildNavItem(
              Icons.history_rounded,
              'nav_history'.tr(),
              false,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AllTransactionsScreen(isDarkMode: isDark),
                  ),
                );
              },
            ),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              Icons.qr_code_scanner_rounded,
              'nav_scan'.tr(),
              false,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PayPurchasesScreen(isDarkMode: isDark),
                  ),
                );
              },
            ),
            _buildNavItem(
              Icons.person_rounded,
              'nav_account'.tr(),
              false,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => POSAccountScreen(isDarkMode: isDark),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? saifiNavy : Colors.grey.withValues(alpha: 0.6),
            size: 26,
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? saifiNavy : Colors.grey.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFab() {
    final bool isDark = themeService.isDarkModeActive(context);
    return GestureDetector(
      onTap: () async {
        setState(() => _turns += 1.0);
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayPurchasesScreen(isDarkMode: isDark),
          ),
        ).then((_) {
          _fetchData(forceRefresh: true);
        });
      },
      child: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [saifiNavy, Color(0xFF3B4D8D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: saifiNavy.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedRotation(
            turns: _turns,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Image.asset(
              isDark ? 'pr_logo.png' : 'logo_circle.png',
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
    ).animate().scale(
      delay: 500.ms,
      duration: 500.ms,
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _showConfirmExitDialog() async {
    final bool isDark = themeService.isDarkModeActive(context);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDark ? AppColors.cardDark : Colors.white,
            elevation: 10,
            shadowColor: saifiNavy.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(
                color:
                    isDark
                        ? Colors.white10
                        : saifiNavy.withValues(alpha: 0.1),
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
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : saifiNavy.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    isDark ? 'pr_logo.png' : 'logo_circle.png',
                    height: 70,
                    width: 70,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.exit_to_app_rounded,
                          size: 50,
                          color: saifiNavy,
                        ),
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                Text(
                  'exit_app'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  'msg_exitapp'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textGreyLight,
                    height: 1.5,
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
                          exit(0); // Definitive exit
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saifiNavy,
                          elevation: 4,
                          shadowColor: saifiNavy.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'ok'.tr(),
                          style: GoogleFonts.cairo(
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
                              isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                        ),
                        child: Text(
                          'cancel'.tr(),
                          style: GoogleFonts.cairo(
                            color: isDark ? Colors.white70 : Colors.black87,
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
}

// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../core/app_colors.dart';
// import '../services/api_service.dart';
// import '../services/theme_service.dart';
// import 'pay_purchases_screen.dart';
// import 'chatbot_screen.dart';
// import 'recharge_and_payment_screen.dart';
// import 'financial_transfers/transaction_details_screen.dart';
// import 'financial_transfers/all_transactions_screen.dart';
// import 'pos_settings_screen.dart';
// import 'pos_account_screen.dart';
// import 'sales_return_screen.dart';
// import 'account_confirmation_screen.dart';
// import '../models/operation_history.dart';
// import '../utils/operation_type_helper.dart';
// import 'package:intl/intl.dart' as intl;
// import '../services/session_manager.dart';
// import '../widgets/receipt_dialog.dart';

// class POSHomeScreen extends StatefulWidget {
//   const POSHomeScreen({super.key});

//   @override
//   State<POSHomeScreen> createState() => _POSHomeScreenState();
// }

// class _POSHomeScreenState extends State<POSHomeScreen> {
//   bool _isLoading = false;
//   List<bool> _showBalances = [false, false, false];
//   Map<String, String> _balances = {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};
//   bool _isAccountConfirmed = true; // Default to true to avoid flicker
//   List<OperationHistoryModel> _transactions = [];
//   static int _lastWalletPage = 1;
//   late final PageController _walletController = PageController(
//     viewportFraction: 0.65,
//     initialPage: _lastWalletPage,
//   );
//   int _currentWalletPage = _lastWalletPage;
//   String _posName = 'نقطة المبيعات';
//   String _posNumber = '';

//   // POS Official Brand Colors (Saifi Pay)
//   static const Color saifiNavy = Color(0xFF1F2D5D);
//   static const Color saifiLightBg = Color(0xFFF1F5F9);

//   @override
//   void initState() {
//     super.initState();
//     //sessionManager.startSession();
//     _loadPOSInfo();
//     _fetchData();
//   }

//   Future<void> _loadPOSInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (mounted) {
//       setState(() {
//         _posName = prefs.getString('pos_trade_name') ?? 'نقطة المبيعات';
//         _posNumber = prefs.getString('pos_number') ?? '';
//       });
//     }
//   }

//   Future<void> _fetchData({bool forceRefresh = true}) async {
//     setState(() => _isLoading = true);
//     try {
//       // Fetch balances and operations history in parallel for maximum speed
//       final results = await Future.wait([
//         ApiService.getBalances(forceRefresh: forceRefresh),
//         ApiService.getOperationsHistory(pageSize: 5),
//       ]);

//       final balanceData = results[0] as Map<String, dynamic>;
//       final history = results[1] as OperationHistoryResponse;

//       if (mounted) {
//         setState(() {
//           _balances = {
//             'YER': (balanceData['YER'] ?? 0.0).toString(),
//             'USD': (balanceData['USD'] ?? 0.0).toString(),
//             'SAR': (balanceData['SAR'] ?? 0.0).toString(),
//           };
//           _transactions = history.results;
//         });

//         // Also fetch user status for the verification banner
//         final user = await ApiService.getMe();
//         if (mounted) {
//           setState(() {
//             _isAccountConfirmed =
//                 user['is_verified'] ?? user['is_confirmed'] ?? false;
//           });
//         }
//       }
//     } catch (e) {
//       customPrint('Error fetching POS data: $e');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = themeService.isDarkModeActive(context);
//     final Color currentBg = isDark ? AppColors.scaffoldDark : saifiLightBg;

//     return Scaffold(
//       backgroundColor: currentBg,
//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: () => _fetchData(forceRefresh: true),
//           color: saifiNavy,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(isDark),
//                 const SizedBox(height: 10),
//                 // Verification Banner
//                 if (!_isAccountConfirmed) _buildVerificationBanner(isDark),
//                 const SizedBox(height: 10),
//                 _buildWalletCarousel(isDark),
//                 const SizedBox(height: 10),
//                 _buildCarouselIndicator(),
//                 const SizedBox(height: 25),
//                 _buildPromoBanner(isDark),
//                 const SizedBox(height: 25),
//                 _buildServiceGrid(isDark),
//                 const SizedBox(height: 30),
//                 _buildRecentTransactionsHeader(isDark),
//                 _buildRecentTransactionsList(isDark),
//                 const SizedBox(height: 100), // Bottom padding for nav
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNav(isDark),
//       floatingActionButton: _buildFab(),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//     );
//   }

//   Widget _buildHeader(bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (context) => ChatBotScreen(
//                             isDarkMode: isDark,
//                             userName: _posName,
//                           ),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: isDark ? saifiNavy : Colors.white,
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
//                         blurRadius: 15,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     Icons.smart_toy_rounded,
//                     color: isDark ? Colors.white : saifiNavy,
//                     size: 26,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 'welcome'.tr(),
//                 style: GoogleFonts.cairo(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : saifiNavy,
//                 ),
//               ),
//               Text(
//                 _posName,
//                 style: GoogleFonts.cairo(
//                   fontSize: 14,
//                   color: isDark ? Colors.white70 : Colors.grey[700],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWalletCarousel(bool isDark) {
//     final List<Map<String, dynamic>> wallets = [
//       {
//         'currency': 'currency_usd'.tr(),
//         'code': 'USD',
//         'icon': Icons.attach_money_rounded,
//       },
//       {
//         'currency': 'currency_yer'.tr(),
//         'code': 'YER',
//         'icon': Icons.account_balance_rounded,
//       },
//       {
//         'currency': 'currency_sar'.tr(),
//         'code': 'SAR',
//         'icon': Icons.currency_exchange_rounded,
//       },
//     ];

//     return AnimatedBuilder(
//       animation: _walletController,
//       builder: (context, child) {
//         double page = _lastWalletPage.toDouble();
//         if (_walletController.hasClients) {
//           page = _walletController.page ?? _lastWalletPage.toDouble();
//         }

//         return SizedBox(
//           height: 150,
//           child: PageView.builder(
//             controller: _walletController,
//             onPageChanged: (idx) {
//               setState(() {
//                 _currentWalletPage = idx;
//                 _lastWalletPage = idx;
//               });
//             },
//             itemCount: wallets.length,
//             itemBuilder: (context, index) {
//               double relativePosition = index - page;

//               return Transform(
//                 transform:
//                     Matrix4.identity()
//                       ..setEntry(3, 2, 0.001)
//                       ..scale(1.0 - (relativePosition.abs() * 0))
//                       ..translate(relativePosition * 25, 0.0)
//                       ..rotateX(-0.25 * relativePosition.abs().clamp(0.0, 1.0))
//                       ..rotateY(-relativePosition * 0.60),
//                 alignment: Alignment.center,
//                 child: Opacity(
//                   opacity: (1.0 - relativePosition.abs() * 0.55).clamp(
//                     0.4,
//                     1.0,
//                   ),
//                   child: _buildWalletCard(wallets[index], isDark, index),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildWalletCard(Map<String, dynamic> wallet, bool isDark, int index) {
//     final List<Color> activeGradient = [
//       AppColors.primaryBlue,
//       AppColors.accentBlue,
//     ];
//     final List<Color> inactiveGradient =
//         isDark
//             ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)]
//             : [Colors.grey.shade400, Colors.grey.shade600];

//     final List<Color> gradient =
//         index == _currentWalletPage ? activeGradient : inactiveGradient;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: gradient,
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(25),
//           boxShadow: [
//             BoxShadow(
//               color: gradient[0].withValues(alpha: 0.4),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(25),
//           child: Stack(
//             children: [
//               Positioned(
//                 top: -50,
//                 right: -50,
//                 child: Container(
//                   width: 150,
//                   height: 150,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.05),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: -30,
//                 left: -30,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.05),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),

//               // Watermark Logo (New)
//               Center(
//                 child: Opacity(
//                   opacity: 0.08,
//                   child: Image.asset(
//                     'logo_circle.png',
//                     width: 90,
//                     errorBuilder:
//                         (c, e, s) => const Icon(
//                           Icons.account_balance_rounded,
//                           size: 70,
//                           color: Colors.white,
//                         ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 22,
//                   vertical: 18,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withValues(alpha: 0.2),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Icon(
//                                 wallet['icon'] as IconData,
//                                 color: Colors.white,
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               'saifi_pay'.tr(),
//                               style: GoogleFonts.cairo(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Flexible(
//                           child: Text(
//                             _posNumber.isNotEmpty
//                                 ? '#$_posNumber'
//                                 : 'point'.tr(),
//                             style: GoogleFonts.cairo(
//                               color: Colors.white.withValues(alpha: 0.7),
//                               fontSize: 11,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     Text(
//                       wallet['currency'].toString().tr(),
//                       style: GoogleFonts.cairo(
//                         color: Colors.white.withValues(alpha: 0.9),
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           _showBalances[index]
//                               ? _balances[wallet['code']]!
//                               : 'masked_balance'.tr(),
//                           style: GoogleFonts.roboto(
//                             color: Colors.white,
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: _showBalances[index] ? 0 : 2,
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap:
//                               () => setState(
//                                 () =>
//                                     _showBalances[index] =
//                                         !_showBalances[index],
//                               ),
//                           child: Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withValues(alpha: 0.2),
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             child: Icon(
//                               _showBalances[index]
//                                   ? Icons.visibility_rounded
//                                   : Icons.visibility_off_rounded,
//                               color: Colors.white,
//                               size: 22,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCarouselIndicator() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(3, (idx) {
//         return AnimatedContainer(
//           duration: 300.ms,
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           width: _currentWalletPage == idx ? 20 : 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: _currentWalletPage == idx ? saifiNavy : Colors.grey[300],
//             borderRadius: BorderRadius.circular(4),
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildPromoBanner(bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors:
//                 isDark
//                     ? [const Color(0xFF1F2D5D), const Color(0xFF161C2E)]
//                     : [Colors.white, const Color(0xFFF1F5F9)],
//           ),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: isDark ? Colors.white10 : Colors.white),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: 15,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'promo_welcome'.tr(),
//                     style: GoogleFonts.cairo(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: saifiNavy,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     'promo_subtitle'.tr(),
//                     style: GoogleFonts.cairo(
//                       fontSize: 13,
//                       color: isDark ? Colors.white70 : Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 15),
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: saifiNavy.withValues(alpha: 0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.rocket_launch_rounded,
//                 color: saifiNavy,
//                 size: 30,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ).animate().fadeIn(delay: 400.ms).slideX();
//   }

//   Widget _buildServiceGrid(bool isDark) {
//     final List<Map<String, dynamic>> services = [
//       {
//         'title': 'service_pay_purchases',
//         'icon': Icons.shopping_basket_rounded,
//         'color': const Color(0xFF4A90E2),
//         'screen':
//             (BuildContext context) => PayPurchasesScreen(isDarkMode: isDark),
//       },
//       {
//         'title': 'service_sales_return',
//         'icon': Icons.assignment_return_rounded,
//         'color': const Color(0xFFF5A623),
//         'screen':
//             (BuildContext context) => SalesReturnScreen(isDarkMode: isDark),
//       },
//       {
//         'title': 'service_recharge_payment',
//         'icon': Icons.bolt_rounded,
//         'color': saifiNavy,
//         'screen':
//             (BuildContext context) =>
//                 RechargeAndPaymentScreen(isDarkMode: isDark),
//       },
//       {
//         'title': 'service_reports',
//         'icon': Icons.analytics_rounded,
//         'color': const Color(0xFFBD10E0),
//         'screen':
//             (BuildContext context) => AllTransactionsScreen(isDarkMode: isDark),
//       },
//       {
//         'title': 'service_settings',
//         'icon': Icons.settings_suggest_rounded,
//         'color': const Color(0xFF4A4A4A),
//         'screen':
//             (BuildContext context) => POSSettingsScreen(isDarkMode: isDark),
//       },
//     ];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 15),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           childAspectRatio: 1.4, // Matched HomeScreen
//           mainAxisSpacing: 8,
//           crossAxisSpacing: 8,
//         ),
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final s = services[index];
//           return GestureDetector(
//             onTap: () async {
//               // Guard sensitive POS services
//               if (index != 5) {
//                 // index 5 is Settings, maybe okay?
//                 if (!await ApiService.checkVerification(
//                   context,
//                   isDarkMode: isDark,
//                   onVerifyNavigate:
//                       () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (context) =>
//                                   AccountConfirmationScreen(isDarkMode: isDark),
//                         ),
//                       ),
//                 ))
//                   return;
//               }

//               if (s['screen'] != null) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: s['screen'] as Widget Function(BuildContext),
//                   ),
//                 ).then((_) {
//                   // Instant refresh of balances and transactions when coming back
//                   _fetchData(forceRefresh: true);
//                 });
//               } else {
//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(SnackBar(content: Text('coming_soon'.tr())));
//               }
//             },
//             child: Container(
//               decoration: BoxDecoration(
//                 color: isDark ? const Color(0xFF1E293B) : Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
//                     blurRadius: 6,
//                     offset: const Offset(3, 3),
//                   ),
//                   BoxShadow(
//                     color:
//                         isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
//                     blurRadius: 6,
//                     offset: const Offset(-2, -2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: (s['color'] as Color).withValues(alpha: 0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       s['icon'] as IconData,
//                       color: s['color'] as Color,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     (s['title'] as String).tr(),
//                     style: GoogleFonts.cairo(
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                       color: isDark ? Colors.white : Colors.black87,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ).animate().scale(delay: (index * 50).ms);
//         },
//       ),
//     );
//   }

//   Widget _buildRecentTransactionsHeader(bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'recent_transactions'.tr(),
//             style: GoogleFonts.cairo(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: isDark ? Colors.white : saifiNavy,
//             ),
//           ),
//           GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder:
//                       (context) => AllTransactionsScreen(isDarkMode: isDark),
//                 ),
//               );
//             },
//             child: Text(
//               'view_all'.tr(),
//               style: GoogleFonts.cairo(
//                 fontSize: 13,
//                 color: Colors.blueAccent,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentTransactionsList(bool isDark) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator(color: saifiNavy));
//     }
//     if (_transactions.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(30),
//           child: Column(
//             children: [
//               Icon(
//                 Icons.history_rounded,
//                 size: 50,
//                 color: Colors.grey.withValues(alpha: 0.5),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 'empty_transactions'.tr(),
//                 style: GoogleFonts.cairo(color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: _transactions.length,
//       itemBuilder: (context, index) {
//         return _buildTransactionItem(_transactions[index], isDark);
//       },
//     );
//   }

//   Widget _buildTransactionItem(OperationHistoryModel transaction, bool isDark) {
//     final type = transaction.operationType;
//     final currency = transaction.currency;
//     final date = transaction.createdAt.toLocal();
//     final timeFormat = intl.DateFormat('hh:mm a', 'en_US');
//     final dateFormat = intl.DateFormat('dd/MM/yyyy', 'en_US');
//     final amountFormatter = intl.NumberFormat('#,##0.00', 'en_US');

//     final bBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
//     final bAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
//     final isPositive = bAfter > bBefore;

//     final icon = OperationTypeHelper.getIcon(type);
//     final iconColor = isPositive ? Colors.green : Colors.red;
//     final title = transaction.operationTypeDisplay;

//     return GestureDetector(
//       onTap: () => _showTransactionDetails(transaction),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isDark ? AppColors.cardDark : Colors.white,
//           borderRadius: BorderRadius.circular(22),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//           border: Border.all(
//             color:
//                 isDark
//                     ? Colors.white.withValues(alpha: 0.05)
//                     : Colors.black.withValues(alpha: 0.03),
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 55,
//               height: 55,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     iconColor.withValues(alpha: 0.2),
//                     iconColor.withValues(alpha: 0.05),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               child: Icon(icon, color: iconColor, size: 26),
//             ),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.cairo(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       color: isDark ? Colors.white : AppColors.textBlack,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   if (transaction.description.isNotEmpty)
//                     Text(
//                       transaction.description,
//                       style: GoogleFonts.cairo(
//                         fontSize: 11,
//                         color: isDark ? Colors.white38 : Colors.black38,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.access_time_rounded,
//                         size: 12,
//                         color: isDark ? Colors.white38 : Colors.grey,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${dateFormat.format(date)} | ${timeFormat.format(date)}',
//                         style: GoogleFonts.roboto(
//                           fontSize: 11,
//                           color: isDark ? Colors.white38 : Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '${isPositive ? '+' : '-'}${amountFormatter.format(double.tryParse(transaction.amount) ?? 0)}',
//                   style: GoogleFonts.roboto(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: iconColor,
//                   ),
//                 ),
//                 Text(
//                   currency,
//                   style: GoogleFonts.cairo(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: isDark ? Colors.white70 : Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
//     );
//   }

//   void _showTransactionDetails(OperationHistoryModel transaction) {
//     final amountFormatter = intl.NumberFormat('#,##0.00', 'en_US');
//     final dateFormat = intl.DateFormat('yyyy/MM/dd hh:mm a', 'ar');

//     final List<ReceiptRowData> details = [];

//     details.add(
//       ReceiptRowData(
//         label: 'referenceNumber'.tr(),
//         value: transaction.referenceNumber ?? '---',
//       ),
//     );

//     details.add(
//       ReceiptRowData(
//         label: 'transactionType'.tr(),
//         value: transaction.operationTypeDisplay,
//       ),
//     );

//     if (transaction.fee != null &&
//         transaction.fee != '0' &&
//         transaction.fee != '0.00') {
//       details.add(
//         ReceiptRowData(
//           label: 'operation_fee'.tr(),
//           value:
//               '${amountFormatter.format(double.tryParse(transaction.fee) ?? 0)} ${transaction.currency}',
//         ),
//       );
//     }

//     final balanceBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
//     final balanceAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
//     final isIncoming = balanceAfter > balanceBefore;

//     if (transaction.relatedUserName != null &&
//         transaction.relatedUserName!.isNotEmpty) {
//       if (isIncoming) {
//         details.add(
//           ReceiptRowData(label: 'المستفيد', value: '$_posName\n$_posNumber'),
//         );
//         details.add(
//           ReceiptRowData(label: 'المودع', value: transaction.relatedUserName!),
//         );
//       } else {
//         details.add(
//           ReceiptRowData(
//             label: 'المستفيد',
//             value: transaction.relatedUserName!,
//           ),
//         );
//         details.add(
//           ReceiptRowData(label: 'المودع', value: '$_posName\n$_posNumber'),
//         );
//       }
//     }
//     details.add(
//       ReceiptRowData(
//         label: 'operation_date'.tr(),
//         value: dateFormat.format(transaction.createdAt.toLocal()),
//       ),
//     );

//     if (transaction.description.isNotEmpty &&
//         OperationHistoryModel.remittanceTypes.contains(
//           transaction.operationType,
//         )) {
//       details.add(
//         ReceiptRowData(
//           label: 'operation_description'.tr(),
//           value: transaction.description,
//         ),
//       );
//     }

//     ReceiptDialog.show(
//       context,
//       isDarkMode: Theme.of(context).brightness == Brightness.dark,
//       title: 'operation_details_title'.tr(),
//       mainAmount:
//           '${amountFormatter.format(double.tryParse(transaction.amount) ?? 0)}',
//       mainCurrency: transaction.currency,
//       details: details,
//       amountColor: isIncoming ? Colors.green : Colors.red,
//     );
//   }

//   Widget _buildVerificationBanner(bool isDark) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.orange.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.warning_amber_rounded,
//             color: Colors.orange,
//             size: 24,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'verification_banner'.tr(),
//               style: GoogleFonts.cairo(
//                 color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           TextButton(
//             onPressed:
//                 () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) =>
//                             AccountConfirmationScreen(isDarkMode: isDark),
//                   ),
//                 ),
//             child: Text(
//               'verify'.tr(),
//               style: GoogleFonts.cairo(
//                 color: Colors.orange,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNav(bool isDark) {
//     return BottomAppBar(
//       shape: const CircularNotchedRectangle(),
//       notchMargin: 12,
//       color: isDark ? const Color(0xFF161C2E) : Colors.white,
//       elevation: 20,
//       child: SizedBox(
//         height: 70,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _buildNavItem(
//               Icons.home_rounded,
//               'nav_home'.tr(),
//               true,
//               isDark,
//               () {},
//             ),
//             _buildNavItem(
//               Icons.history_rounded,
//               'nav_history'.tr(),
//               false,
//               isDark,
//               () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) => AllTransactionsScreen(isDarkMode: isDark),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(width: 40), // Space for FAB
//             _buildNavItem(
//               Icons.qr_code_scanner_rounded,
//               'nav_scan'.tr(),
//               false,
//               isDark,
//               () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) => PayPurchasesScreen(isDarkMode: isDark),
//                   ),
//                 );
//               },
//             ),
//             _buildNavItem(
//               Icons.person_rounded,
//               'nav_account'.tr(),
//               false,
//               isDark,
//               () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => POSAccountScreen(isDarkMode: isDark),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(
//     IconData icon,
//     String label,
//     bool isActive,
//     bool isDark,
//     VoidCallback onTap,
//   ) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             color: isActive ? saifiNavy : Colors.grey.withValues(alpha: 0.6),
//             size: 26,
//           ),
//           Text(
//             label,
//             style: GoogleFonts.cairo(
//               fontSize: 10,
//               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//               color: isActive ? saifiNavy : Colors.grey.withValues(alpha: 0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFab() {
//     final bool isDark = themeService.isDarkModeActive(context);
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => RechargeAndPaymentScreen(isDarkMode: isDark),
//           ),
//         );
//       },
//       child: Container(
//         height: 65,
//         width: 65,
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [saifiNavy, Color(0xFF3B4D8D)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: saifiNavy.withValues(alpha: 0.4),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
//       ),
//     ).animate().scale(
//       delay: 500.ms,
//       duration: 500.ms,
//       curve: Curves.easeOutBack,
//     );
//   }
// }
