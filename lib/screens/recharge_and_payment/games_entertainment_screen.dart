import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../account_confirmation_screen.dart';
import '../../services/sound_service.dart';

import '../../core/app_colors.dart';
import '../../services/alzajil_service.dart';
import '../../components/security_verification_dialog.dart';
import '../../components/loading_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../helper/counvert_amunt_helper.dart';

class GamesEntertainmentScreen extends StatefulWidget {
  final bool isDarkMode;
  const GamesEntertainmentScreen({super.key, required this.isDarkMode});

  @override
  State<GamesEntertainmentScreen> createState() =>
      _GamesEntertainmentScreenState();
}

class _GamesEntertainmentScreenState extends State<GamesEntertainmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _playerIdController = TextEditingController();

  bool _isLoading = false;
  String? _selectedGame;
  String? _selectedPackageId; // Item Code / Offer ID

  final AlzajilService _alzajilService = AlzajilService();

  final List<Map<String, dynamic>> games = [
    {
      'title': 'pubg_Mobile'.tr(),
      'icon': Icons.sports_esports_rounded,
      'id': 'pubg',
      'itemCode': 54, // Updated from 55 to 54 as per new specs
      'image': 'assets/images/networks/pubg.png',
    },
    {
      'title': 'free_Fire'.tr(),
      'icon': Icons.local_fire_department_rounded,
      'id': 'freefire',
      'itemCode': 56, // Free Fire in Table 1.7
    },
    {
      'title': 'razer_Gold'.tr(),
      'icon': Icons.monetization_on_rounded,
      'id': 'razer',
      'itemCode': 57, // Razer Gold in Table 1.7
    },
    {
      'title': 'bigo_Live'.tr(),
      'icon': Icons.live_tv_rounded,
      'id': 'bigo',
      'itemCode': 45, // Mizu / Bigo
    },
  ];

  final List<Map<String, dynamic>> pubgPackages = [
    {'id': '4379', 'name': '${"package".tr()} 60 ${"Intensity".tr()}', 'price': 487, 'commission': 13},
    {'id': '4397', 'name': '${"package".tr()} 325 ${"Intensity".tr()}', 'price': 2369, 'commission': 31},
    {'id': '7385', 'name': '${"package".tr()} 385 ${"Intensity".tr()}', 'price': 2840, 'commission': 60},
    {'id': '4406', 'name': '${"package".tr()} 660 ${"Intensity".tr()}', 'price': 4726, 'commission': 74},
    {'id': '7394', 'name': '${"package".tr()} 720 ${"Intensity".tr()}', 'price': 5197, 'commission': 103},
    {'id': '7403', 'name': '${"package".tr()} 985 ${"Intensity".tr()}', 'price': 7083, 'commission': 117},
    {'id': '4424', 'name': '${"package".tr()} 1800 ${"Intensity".tr()}', 'price': 11798, 'commission': 202},
    {'id': '7412', 'name': '${"package".tr()} 2125 ${"Intensity".tr()}', 'price': 14155, 'commission': 245},
    {'id': '4442', 'name': '${"package".tr()} 3850 ${"Intensity".tr()}', 'price': 23473, 'commission': 527},
    {'id': '4460', 'name': '${"package".tr()} 8100 ${"Intensity".tr()}', 'price': 46935, 'commission': 1065},
    {'id': '4469', 'name': '${"package".tr()} 8425 ${"Intensity".tr()}', 'price': 50485, 'commission': 1115},
    {
      'id': '7349',
      'name': '${"package".tr()} 12000+4200 ${"Intensity".tr()}',
      'price': 93859,
      'commission': 2141,
    },
    {
      'id': '7358',
      'name': '${"package".tr()} 18000+6300 ${"Intensity".tr()}',
      'price': 140783,
      'commission': 3217,
    },
    {
      'id': '7367',
      'name': '${"package".tr()} 24000+8400 ${"Intensity".tr()}',
      'price': 187707,
      'commission': 4293,
    },
    {
      'id': '7376',
      'name': '${"package".tr()} 30000+10500 ${"Intensity".tr()}',
      'price': 234631,
      'commission': 5369,
    },
  ];

  String _selectedPackageName = '';
  double _selectedPackagePrice = 0;
  double _selectedPackageCommission = 0;

  @override
  void dispose() {
    _playerIdController.dispose();
    super.dispose();
  }

 Future<void> _processGameTopUp() async {
  if (!_formKey.currentState!.validate() ||
      _selectedGame == null ||
      _selectedPackageId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'الرجاء اختيار اللعبة وال${"package".tr()} وإدخال المعرف',
          style: const TextStyle(),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  // ⏳ الثغرة الأولى: انتظار فحص التحقق من الـ API
  final isVerified = await ApiService.checkVerification(
    context,
    isDarkMode: widget.isDarkMode,
    onVerifyNavigate: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountConfirmationScreen(isDarkMode: widget.isDarkMode),
      ),
    ),
  );

  // 🛑 إصلاح الثغرة الأولى: التحقق من وجود الشاشة بعد الـ await
  if (!mounted) return;
  if (!isVerified) return;

  // Build detail view for confirmation
  Widget detailsWidget = Column(
    children: [
      _buildModernDetailRow(
        'service'.tr(),
        'charging_recreational_games'.tr(),
        Icons.games_rounded,
      ),
      _buildModernDetailRow(
        'the_game'.tr(),
        _selectedGame == 'pubg' ? 'pubg_Mobile'.tr() : _selectedGame!,
        Icons.sports_esports_rounded,
      ),
      _buildModernDetailRow(
        'ال${"package".tr()}',
        _selectedPackageName,
        Icons.inventory_2_outlined,
      ),
      _buildModernDetailRow(
        'player_ID'.tr(),
        _playerIdController.text,
        Icons.person_pin_rounded,
      ),
      _buildModernDetailRow(
        'shipping_cost'.tr(),
        '${formatAmountDisplay(_selectedPackagePrice)} YER',
        Icons.monetization_on_outlined,
      ),
      if (_selectedPackageCommission > 0)
        _buildModernDetailRow(
          'commission_amount'.tr(),
          '${formatAmountDisplay(_selectedPackageCommission)} YER',
          Icons.add_moderator_rounded,
        ),
      const Divider(),
      _buildModernDetailRow(
        'total'.tr(),
        '${formatAmountDisplay(_selectedPackagePrice + _selectedPackageCommission)} YER',
        Icons.account_balance_wallet_rounded,
      ),
    ],
  );
  
  // ⏳ الثغرة الثانية: انتظار نافذة التحقق الأمني (تفاعل المستخدم قد يستغرق وقتاً)
  final verified = await SecurityVerificationDialog.show(
    context,
    isDarkMode: widget.isDarkMode,
    title: 'confirm_the_shipping_process'.tr(),
    content: detailsWidget,
  );

  // 🛑 إصلاح الثغرة الثانية: التحقق الفوري بعد إغلاق الـ Dialog
  if (!mounted) return;
  if (verified != true) return;

  setState(() => _isLoading = true);

  try {
    // Generate a unique reference number (agent identifier)
    final String uniqueRef = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(3);

    final selectedGameData = games.firstWhere(
      (g) => g['id'] == _selectedGame,
    );
    final int gameItemCode = selectedGameData['itemCode'] ?? 0;

    // ⏳ فجوة زمنية أثناء إرسال عملية الدفع للسيرفر
    final result = await _alzajilService.sendPayment(
      actionCode: 7700,
      serviceCode: 50001,
      amount: _selectedPackagePrice + _selectedPackageCommission,
      subscriberNo: "0",
      item: gameItemCode,
      offerId: _selectedPackageId,
      remarks: _selectedGame == 'pubg'
          ? 'PUBG UC ${_selectedPackageName.replaceAll(RegExp(r'[^0-9]'), '')}'
          : _selectedPackageName,
      soi: jsonEncode({
        "rid": _playerIdController.text,
      }),
      ref: uniqueRef,
    );

    // 🛑 حماية إضافية: التحقق الفوري بعد استجابة سيرفر الدفع
    if (!mounted) return;

    if (result['RC'] == 0 || result['rc'] == 0) {
      _showReceipt(result);
    } else {
      _showDialog(
        'خطأ',
        result['MSG'] ?? result['msg'] ?? 'حدث خطأ غير معروف',
      );
    }
  } catch (e) {
    if (context.mounted) {
      _showDialog('خطأ', e.toString().replaceAll('Exception:', ''));
    }
  } finally {
    if (context.mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  void _showReceipt(Map<String, dynamic> result) {
    SoundService.playSuccessSound();
    _showDialog(
      'تمت العملية بنجاح',
      'تم إرسال طلب الشحن بنجاح.\nالمبلغ الإجمالي: ${formatAmountDisplay(_selectedPackagePrice + _selectedPackageCommission)} YER\nرقم المرجع: ${result['REF'] ?? result['ref'] ?? 'N/A'}',
    );
  }

  void _showDialog(String title, String content) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor:
                widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'ok'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.adaptiveIcon(widget.isDarkMode),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.adaptiveIcon(widget.isDarkMode),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final Color cardColor =
        widget.isDarkMode ? AppColors.cardDark : Colors.white;

    // Determine current game image/color
    String? headerImage;
    IconData headerIcon = Icons.sports_esports_rounded;
    if (_selectedGame != null) {
      final selected = games.firstWhere((g) => g['id'] == _selectedGame);
      headerImage = selected['image'];
      headerIcon = selected['icon'];
    }

    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Premium Sliver Header
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.adaptiveIcon(widget.isDarkMode),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title:  Text(
                    'games_and_entertainment'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 10),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Animated Switcher for Background
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child:
                            headerImage != null
                                ? Image.asset(
                                  headerImage,
                                  key: ValueKey(headerImage),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _buildDefaultHeaderGradient(),
                                )
                                : _buildDefaultHeaderGradient(),
                      ),
                      // Overlay Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      if (headerImage == null)
                        Center(
                          child: Icon(
                            headerIcon,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.2),
                          ).animate().scale(
                            duration: const Duration(seconds: 1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      
              // 2. Main content area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Game Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'select_game'.tr(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedGame != null)
                              TextButton(
                                onPressed:
                                    () => setState(() {
                                      _selectedGame = null;
                                      _selectedPackageId = null;
                                      _playerIdController.clear();
                                    }),
                                child: Text(
                                  'reset'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              final isSelected =
                                  _selectedGame == games[index]['id'];
                              return GestureDetector(
                                onTap:
                                    () => setState(() {
                                      _selectedGame = games[index]['id'];
                                      _selectedPackageId = null;
                                    }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 95,
                                  margin: const EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.primaryBlue
                                            : cardColor,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            isSelected
                                                ? AppColors.primaryBlue
                                                    .withValues(alpha: 0.3)
                                                : Colors.black.withValues(alpha: 
                                                  0.05,
                                                ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.primaryBlue
                                              : (widget.isDarkMode
                                                  ? Colors.white10
                                                  : Colors.black12),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        games[index]['icon'],
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        games[index]['title'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : textColor,
      
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
      
                        const SizedBox(height: 30),
      
                        // Dynamic Fields based on selection
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder:
                              (child, animation) => FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child:
                              _selectedGame == null
                                  ? _buildEmptyState(textColor)
                                  : Column(
                                    key: ValueKey(_selectedGame),
                                    children: [
                                      _buildPremiumTextField(
                                        controller: _playerIdController,
                                        label: '${"player_ID".tr()} (ID)',
                                        hint: 'enter_player_ID'.tr(),
                                        icon: Icons.person_pin_rounded,
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? 'enter_player_ID'.tr()
                                                    : null,
                                      ),
                                      const SizedBox(height: 25),
                                      _buildPremiumDropdown(
                                        label: 'select_package'.tr(),
                                        value: _selectedPackageId,
                                        items:
                                            (_selectedGame == 'pubg'
                                                    ? pubgPackages
                                                    : [])
                                                .map<
                                                  DropdownMenuItem<String>
                                                >((pkg) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value:
                                                        pkg['id'].toString(),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          pkg['name']!,
                                                          style: TextStyle(
                                                            color: textColor,
                                                            fontFamily:
                                                                'Cairo',
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          ' ${formatAmountDisplay(pkg['price'].toDouble())} YER',
                                                          style: TextStyle(
                                                            color:
                                                                AppColors
                                                                    .accentBlue,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                            fontFamily:
                                                                'Cairo',
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedPackageId = val;
                                            if (_selectedGame == 'pubg') {
                                              final pkg = pubgPackages
                                                  .firstWhere(
                                                    (p) =>
                                                        p['id'].toString() ==
                                                        val,
                                                  );
                                              _selectedPackageName =
                                                  pkg['name'];
                                              _selectedPackagePrice =
                                                  pkg['price'].toDouble();
                                              _selectedPackageCommission =
                                                  (pkg['commission'] ?? 0)
                                                      .toDouble();
                                            }
                                          });
                                        },
                                        validator:
                                            (val) =>
                                                val == null
                                                    ? 'select_package'.tr()
                                                    : null,
                                      ),
                                      const SizedBox(height: 40),
                                      _buildPremiumButton(),
                                    ],
                                  ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            LoadingOverlay(
              isDarkMode: widget.isDarkMode,
              message: 'shipping_in_progress'.tr(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            '${"please_select_game".tr()} \n ${"show_package_aviled".tr()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ).animate().fadeIn(duration: const Duration(milliseconds: 600)),
    );
  }

  Widget _buildDefaultHeaderGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,

              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(
                icon,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: validator,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryBlue,
            ),
            dropdownColor:
                widget.isDarkMode ? AppColors.cardDark : Colors.white,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processGameTopUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                :  Text(
                  'confirm_shipping_now'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
