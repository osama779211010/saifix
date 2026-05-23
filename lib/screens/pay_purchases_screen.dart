import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/custom_print_helper.dart';
import '../core/app_colors.dart';
import 'package:flutter/services.dart';
import '../helper/arabic_numbers_helper.dart';
import '../services/api_service.dart';
import '../components/qr_scanner_screen.dart';
import '../components/transaction_details_bottom_sheet.dart';
import '../components/security_confirmation_dialog.dart';
import '../components/error_dialog.dart';
import 'financial_transfers/transfer_to_subscriber_screen.dart';
import 'package:intl/intl.dart' as intl;
import 'account_confirmation_screen.dart';
import '../services/sound_service.dart';
import '../services/favorites_service.dart';
import '../components/favorites_bottom_sheet.dart';
import '../widgets/receipt_dialog.dart';
import '../components/recharge/add_favorite_dialog.dart';
import '../helper/counvert_amunt_helper.dart';
import '../components/loading_overlay.dart';
import '../components/current_balance_card.dart';
import '../services/balance_service.dart';

class PayPurchasesScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? initialPOSNumber;

  const PayPurchasesScreen({
    super.key,
    required this.isDarkMode,
    this.initialPOSNumber,
  });

  @override
  State<PayPurchasesScreen> createState() => _PayPurchasesScreenState();
}

class _PayPurchasesScreenState extends State<PayPurchasesScreen> {
  final TextEditingController _posNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMethod = 'my_app_name'.tr();
  String? _selectedOtherWallet;
  bool _isLoading = false;
  Map<String, dynamic>? _posPoint;
  bool _isSearching = false;
  String? _searchError;
  bool _isFavorite = false;
  String _currency = 'YER';
  List<Map<String, dynamic>> _recentPOS = [];
  List<Map<String, dynamic>> _filteredPOS = [];

  final List<Map<String, String>> _otherWallets = [
    {'name': 'jaib'.tr(), 'logo': 'assets/images/networks/jeeb.png'},
    {'name': 'jawali'.tr(), 'logo': 'assets/images/networks/jawali.jpg'},
    {'name': 'one_cash'.tr(), 'logo': 'assets/images/networks/one_cash.png'},
    {'name': 'flousak'.tr(), 'logo': 'assets/images/networks/flosak.png'},
    {
      'name': 'mobile_money'.tr(),
      'logo': 'assets/images/networks/mobile_money.png',
    },
    {'name': 'cash'.tr(), 'logo': 'assets/images/networks/cash.png'},
    {'name': 'saba_cash'.tr(), 'logo': 'assets/images/networks/saba_cash.png'},
    {'name': 'mpay'.tr(), 'logo': 'assets/images/networks/mpay.png'},
    {'name': 'shamel_money'.tr(), 'logo': 'assets/images/networks/shamel.png'},
    {'name': 'easy'.tr(), 'logo': 'assets/images/networks/easy.png'},
  ];

  @override
  void initState() {
    super.initState();
    _currency = balanceService.selectedCurrency;
    balanceService.addListener(_onBalanceServiceChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchBalances();
        _loadRecentPOS();
        if (widget.initialPOSNumber != null) {
          _posNumberController.text = widget.initialPOSNumber!;
          _onPOSNumberChanged(widget.initialPOSNumber!);
        }
      }
    });
  }

  void _onBalanceServiceChanged() {
    if (mounted) {
      setState(() {
        _currency = balanceService.selectedCurrency;
      });
    }
  }

  @override
  void dispose() {
    balanceService.removeListener(_onBalanceServiceChanged);
    _posNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalances() async {
    await balanceService.refreshBalance();
  }

  void _onPOSNumberChanged(String val, {bool isSelection = false}) {
    final cleanVal = val.replaceAll(RegExp(r'\D'), '');

    // مسح بيانات النقطة السابقة عند حدوث أي تغيير في الرقم
    if (_posPoint != null || _searchError != null) {
      setState(() {
        _posPoint = null;
        _searchError = null;
      });
    }

    if (cleanVal.isEmpty || isSelection) {
      setState(() => _filteredPOS = []);
    } else {
      setState(() {
        _filteredPOS =
            _recentPOS.where((pos) {
              final number = pos['pos_number'].toString();
              final name = pos['trade_name'].toString().toLowerCase();
              return number.contains(cleanVal) ||
                  name.contains(cleanVal.toLowerCase());
            }).toList();
      });
    }
  }

  Future<void> _performManualSearch() async {
    final cleanVal = _posNumberController.text.replaceAll(RegExp(r'\D'), '');
    if (cleanVal.isEmpty) return;

    if (cleanVal.length == 9) {
      _showRedirectToP2PDialog(cleanVal);
      return;
    }

    if (cleanVal.length < 5) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _posPoint = null;
    });

    try {
      final point = await ApiService.getPOSPoint(cleanVal);
      if (mounted) {
        setState(() {
          _posPoint = point;
          if (point == null) {
            _searchError = 'نقطة المبيعات غير موجودة';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: 'حدث خطأ أثناء البحث');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadRecentPOS() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('recent_pos_points');
      if (data != null && mounted) {
        setState(() {
          _recentPOS = List<Map<String, dynamic>>.from(jsonDecode(data));
        });
      }
    } catch (e) {
      customPrint('Error loading recent POS: $e');
    }
  }

  Future<void> _saveToRecentPOS(Map<String, dynamic> pos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newPOS = {
        'pos_number': pos['pos_number'],
        'trade_name': pos['trade_name'],
        'last_used': DateTime.now().toIso8601String(),
      };

      _recentPOS.removeWhere((p) => p['pos_number'] == pos['pos_number']);
      _recentPOS.insert(0, newPOS);

      if (_recentPOS.length > 10) {
        _recentPOS = _recentPOS.sublist(0, 10);
      }

      await prefs.setString('recent_pos_points', jsonEncode(_recentPOS));
      if (mounted) setState(() {});
    } catch (e) {
      customPrint('Error saving to recent POS: $e');
    }
  }

  Future<void> _checkIfFavorite(String id) async {
    if (id.isEmpty) {
      if (mounted) setState(() => _isFavorite = false);
      return;
    }
    final fav = await favoritesService.isFavorite(id, FavoriteType.payment);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_posNumberController.text.isEmpty) return;

    if (_isFavorite) {
      await favoritesService.removeFavorite(
        _posNumberController.text,
        FavoriteType.payment,
      );
      _checkIfFavorite(_posNumberController.text);
    } else {
      AddFavoriteDialog.show(
        context,
        isDarkMode: widget.isDarkMode,
        initialType: FavoriteType.payment,
        initialId: _posNumberController.text,
        initialAmount: _amountController.text,
        onAdded: () {
          _checkIfFavorite(_posNumberController.text);
        },
      );
    }
  }

  void _showFavorites() {
    FavoritesBottomSheet.show(
      context,
      type: FavoriteType.payment,
      isDarkMode: widget.isDarkMode,
      onSelected: (phone, name, amount) {
        _posNumberController.text = phone;
        _onPOSNumberChanged(phone);
      },
    );
  }

  void _showRedirectToP2PDialog(String phone) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = widget.isDarkMode;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Styled Logo Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue.withValues(alpha: 0.15),
                        AppColors.primaryBlue.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      isDark ? 'pr_logo.png' : 'logo_circle.png',
                      height: 38,
                      width: 38,
                      errorBuilder:
                          (c, e, s) => const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dialog Title
                Text(
                  'subscriber_number'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Message Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'not_a_point_of_sale_number'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor:
                              isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                        child: Text(
                          'cancel'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm Redirection Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => TransferToSubscriberScreen(
                                      isDarkMode: widget.isDarkMode,
                                      initialPhone: phone,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'move_now'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
      },
    );
  }

  void _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(isDarkMode: widget.isDarkMode),
      ),
    );

    if (result != null && mounted) {
      // توقع صيغة POS:1234567 أو رقم مباشر
      String cleanResult = result.trim();
      if (cleanResult.startsWith('POS:')) {
        cleanResult = cleanResult.substring(4);
      }

      _posNumberController.text = cleanResult;
      _onPOSNumberChanged(cleanResult);
    }
  }

  Future<void> _handlePayment() async {
    if (_posNumberController.text.isEmpty || _amountController.text.isEmpty) {
      ErrorDialog.show(context, message: 'fill_all_fields'.tr());
      return;
    }

    if (_posPoint == null) {
      await _performManualSearch();
      if (!mounted) return;
      if (_posPoint == null) return;
    }

    if (!await ApiService.checkVerification(
      context,
      isDarkMode: widget.isDarkMode,
      onVerifyNavigate:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AccountConfirmationScreen(isDarkMode: widget.isDarkMode),
            ),
          ),
    )) {
      return;
    }

    if (!mounted) return;

    // تقييد السداد لنقاط صيفي فقط في شاشة المشتريات
    if (_selectedPaymentMethod == 'e-wallets'.tr()) {
      ErrorDialog.show(context, message: 'msg_error_pay_on_saifa_only'.tr());
      return;
    }

    if (_posPoint == null) {
      ErrorDialog.show(
        context,
        message: 'يرجى إدخال رقم نقطة المبيعات أولاً'.tr(),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ErrorDialog.show(context, message: 'يرجى إدخال المبلغ'.tr());
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ErrorDialog.show(context, message: 'يرجى إدخال مبلغ صحيح'.tr());
      return;
    }

    // إظهار تفاصيل العملية
    if (!mounted) return;
    TransactionDetailsBottomSheet.show(
      context,
      isDarkMode: widget.isDarkMode,
      amount: formatAmountDisplay(double.tryParse(_amountController.text) ?? 0),
      currency: _currency,
      transactionType: 'payment_for_purchases'.tr(),
      recipientName: _posPoint!['trade_name'],
      recipientId: _posPoint!['pos_number'],
      onExecute: () async {
        final result = await SecurityConfirmationDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
        );

        if (result != null) {
          _executePayment(result is String ? result : null, amount);
        }
      },
    );
  }

  Future<void> _executePayment(String? password, double amount) async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.transferP2P(
        _posNumberController.text,
        _currency,
        amount,
        description:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        password: password,
      );

      if (mounted) {
        if (_posPoint != null) {
          _saveToRecentPOS(_posPoint!);
        }
        setState(() => _isLoading = false);
        _showSuccessReceipt(result['reference_number'] ?? 'N/A', amount);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _showSuccessReceipt(String ref, double amount) {
    // تشغيل صوت النجاح (Apple Pay style)
    SoundService.playSuccessSound();

    final details = [
      ReceiptRowData(
        label: 'price'.tr(),
        value: '${formatAmountDisplay(amount)} $_currency',
      ),
      ReceiptRowData(label: 'the_store'.tr(), value: _posPoint!['trade_name']),
      ReceiptRowData(label: 'point_no'.tr(), value: _posPoint!['pos_number']),
      ReceiptRowData(
        label: 'referenceNumber'.tr(),
        value: ref,
        isCopyable: true,
      ),
      ReceiptRowData(
        label: 'dateLabel'.tr(),
        value: intl.DateFormat(
          'dd/MM/yyyy HH:mm',
          'en_US',
        ).format(DateTime.now()),
      ),
    ];

    final shareText =
        '✅ ${"purchase_payment_receipt".tr()} - ${"my_app_name".tr()} \n\n'
        '${"price".tr()}: ${formatAmountDisplay(amount)} $_currency\n'
        '${"the_store".tr()}: ${_posPoint!['trade_name']}\n'
        '${"referenceNumber".tr()}: $ref\n';

    ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'purchase_payment_receipt'.tr(),
      mainAmount: formatAmountDisplay(amount),
      mainCurrency: _currency,
      details: details,
      shareText: shareText,
    ).then((_) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'payment_for_purchases'.tr(),
                  () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        // 1. Balance Card (Current reference)
                        CurrentBalanceCard(isDarkMode: widget.isDarkMode),

                        const SizedBox(height: 25),

                        // 2. POS Number Input (Moved to Top for better identification)
                        _buildModernInput(
                          label: "point_no".tr(),
                          hint: 'enter_point_no'.tr(),
                          controller: _posNumberController,
                          onChanged: _onPOSNumberChanged,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.storefront_rounded,
                          inputFormatters: [ArabicToEnglishNumbersFormatter()],
                          suffixWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color:
                                      _isFavorite
                                          ? AppColors.secondaryBlue
                                          : AppColors.accentBlue,
                                  size: 20,
                                ),
                                onPressed:
                                    _posNumberController.text.isEmpty
                                        ? _showFavorites
                                        : _toggleFavorite,
                                tooltip: 'add_to_favorites'.tr(),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.accentBlue,
                                  size: 18,
                                ),
                                onPressed: _scanQr,
                              ),
                            ],
                          ),
                        ),
                        if (_filteredPOS.isNotEmpty)
                          _buildFilteredSuggestions(),

                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(),
                          ),

                        // Merchant name card hidden as requested before continuing
                        if (_searchError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _searchError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const SizedBox(height: 25),

                        // 3. Amount Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                widget.isDarkMode
                                    ? AppColors.cardDark
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white10
                                      : Colors.grey.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [const SizedBox(width: 10)]),
                              const SizedBox(height: 15),
                              _buildModernInput(
                                label: 'price'.tr(),
                                hint: '0.00',
                                controller: _amountController,
                                onChanged: (val) => setState(() {}),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixIcon: Icons.money_rounded,
                                inputFormatters: [
                                  ArabicToEnglishNumbersFormatter(),
                                ],
                              ),
                              if (_amountController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 10,
                                  ),
                                  child: Text(
                                    '${formatAmountToArabicWords(double.tryParse(_amountController.text) ?? 0.0)} ${_currency == 'YER' ? 'ريال يمني' : (_currency == 'USD' ? 'دولار' : 'ريال سعودي')}',
                                    style: TextStyle(
                                      color:
                                          widget.isDarkMode
                                              ? Colors.white60
                                              : Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              _buildModernInput(
                                label: 'notes'.tr(),
                                hint: 'optionalNotes'.tr(),
                                controller: _notesController,
                                prefixIcon: Icons.note_add_outlined,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 4. Payment Method Choice
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 8,
                              ),
                              child: Text(
                                'payment_method'.tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,

                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color:
                                    widget.isDarkMode
                                        ? AppColors.cardDark
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSegmentButton(
                                      'my_app_name'.tr(),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSegmentButton(
                                      'e-wallets'.tr(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // 5. Point / Wallet Detail (Electronic Wallets)
                        if (_selectedPaymentMethod == 'e-wallets'.tr()) ...[
                          _buildOtherWalletsGrid(),
                          const SizedBox(height: 20),
                        ],

                        const SizedBox(height: 30),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _posNumberController.text.isEmpty ||
                                        _isLoading ||
                                        _isSearching
                                    ? null
                                    : _handlePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isLoading || _isSearching
                                    ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _isSearching
                                              ? 'جاري التحقق...'
                                              : 'payment_purchases_is_in_progress'
                                                  .tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    )
                                    : Text(
                                      'verify_payment'.tr(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            LoadingOverlay(
              isDarkMode: widget.isDarkMode,
              message: 'payment_purchases_is_in_progress'.tr(),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  size: 18,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String title) {
    final bool isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (widget.isDarkMode
                        ? Colors.white54
                        : Colors.grey.shade600),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required String hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    bool isDropdown = false,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    Widget? suffixWidget,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: AppColors.accentBlue, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  readOnly: isDropdown,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (suffixWidget != null) ...[
                const SizedBox(width: 10),
                suffixWidget,
              ] else if (suffixIcon != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(
                    suffixIcon,
                    color: AppColors.accentBlue,
                    size: 20,
                  ),
                ),
              ] else if (isDropdown) ...[
                const SizedBox(width: 10),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherWalletsGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                '${"point_type".tr()} (${"e-wallets".tr()})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _otherWallets.length,
            itemBuilder: (context, index) {
              final wallet = _otherWallets[index];
              final bool isSelected = _selectedOtherWallet == wallet['name'];
              return GestureDetector(
                onTap:
                    () => setState(() => _selectedOtherWallet = wallet['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.12)
                            : (widget.isDarkMode
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : (widget.isDarkMode
                                  ? Colors.white10
                                  : Colors.transparent),
                      width: 1.5,
                    ),
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
                            if (widget.isDarkMode && isSelected)
                              BoxShadow(
                                color: AppColors.accentBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child:
                            wallet['logo'] != null
                                ? Image.asset(
                                  wallet['logo']!,
                                  height: 25,
                                  width: 25,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.wallet_rounded,
                                        size: 20,
                                        color:
                                            isSelected
                                                ? AppColors.primaryBlue
                                                : AppColors.adaptiveIcon(
                                                  widget.isDarkMode,
                                                ),
                                      ),
                                )
                                : Icon(
                                  Icons.wallet_rounded,
                                  size: 20,
                                  color:
                                      isSelected
                                          ? AppColors.primaryBlue
                                          : AppColors.adaptiveIcon(
                                            widget.isDarkMode,
                                          ),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wallet['name']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected
                                  ? AppColors.primaryBlue
                                  : (widget.isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _filteredPOS.length,
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
        itemBuilder: (context, index) {
          final pos = _filteredPOS[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                (pos['trade_name'] ?? 'P')[0],
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              pos['trade_name'] ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              pos['pos_number'].toString(),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            onTap: () {
              setState(() {
                _posNumberController.text = pos['pos_number'].toString();
                _filteredPOS = [];
              });
              _onPOSNumberChanged(
                pos['pos_number'].toString(),
                isSelection: true,
              );
              // Hide keyboard on selection
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }
}
