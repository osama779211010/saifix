import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/security_confirmation_dialog.dart';
import '../../components/error_dialog.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart' as intl;
import '../account_confirmation_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/sound_service.dart';
import '../../widgets/receipt_dialog.dart';

import '../../helper/custom_print_helper.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../components/current_balance_card.dart';
import '../../services/balance_service.dart';
import '../../helper/arabic_numbers_helper.dart';

class TransferBetweenAccountsScreen extends StatefulWidget {
  final bool isDarkMode;

  const TransferBetweenAccountsScreen({super.key, required this.isDarkMode});

  @override
  State<TransferBetweenAccountsScreen> createState() =>
      _TransferBetweenAccountsScreenState();
}

class _TransferBetweenAccountsScreenState
    extends State<TransferBetweenAccountsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _amountInWords = '';

  // State
  String _fromCurrency = 'YER';
  String _toCurrency = 'USD';
  List<dynamic> _rates = [];
  double _currentRate = 0.0;
  bool _isLoading = false;
  String _conversionResult = '';

  Map<String, dynamic> _balances = {
    'YER': '0.00',
    'USD': '0.00',
    'SAR': '0.00',
  };
  bool _hasEnoughBalance = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  String _getCurrencyDisplay(String code) {
    if (code == 'YER') return 'ر.ي';
    if (code == 'USD') return 'دولار';
    if (code == 'SAR') return 'ر.س';
    return code;
  }

  Future<void> _fetchCounts() async {
    try {
      final rates = await ApiService.getExchangeRates();
      await balanceService.refreshBalance();
      final userData = await ApiService.getMe();

      customPrint('🔍 بيانات المستخدم في صرافة: $userData');

      if (mounted) {
        setState(() {
          _rates = rates;

          // استخدام نفس منطق الصفحة الرئيسية
          if (userData['wallets'] != null) {
            final wallets = userData['wallets'];
            _balances = {
              'YER': (wallets['YER'] ?? 0.0).toString(),
              'USD': (wallets['USD'] ?? 0.0).toString(),
              'SAR': (wallets['SAR'] ?? 0.0).toString(),
            };
            customPrint('✅ الأرصدة من userData.wallets: $_balances');
          } else {
            customPrint('⚠️ wallets غير موجودة، استخدام getBalances...');
            _balances = {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};
          }

          _updateRate();
        });
      }
    } catch (e) {
      customPrint('❌ خطأ في جلب البيانات: $e');
      if (mounted) {
        setState(() {
          _balances = {'YER': '0.00', 'USD': '0.00', 'SAR': '0.00'};
        });
      }
    }
  }

  void _updateRate() {
    _conversionResult = '';

    if (_fromCurrency == _toCurrency) {
      _currentRate = 0.0;
      if (_amountController.text.isNotEmpty) {
        _onAmountChanged(_amountController.text);
      }
      return;
    }

    // Logic to find rate:
    // 1. Check Direct (From -> To)
    var rateObj = _rates.firstWhere(
      (r) =>
          r['from_currency'] == _fromCurrency &&
          r['to_currency'] == _toCurrency,
      orElse: () => null,
    );

    if (rateObj != null) {
      double buyRate = double.parse(rateObj['buy_rate'].toString());
      double sellRate = double.parse(rateObj['sell_rate'].toString());
      // If buy_rate is 1.00, use sell_rate instead (it's the actual rate)
      if (buyRate == 1.0 && sellRate > 1.0) {
        _currentRate = 1.0 / sellRate;
      } else {
        _currentRate = buyRate;
      }
    } else {
      // 2. Check Reverse (To -> From) and use sell_rate for inverse calculation
      var reverseRateObj = _rates.firstWhere(
        (r) =>
            r['from_currency'] == _toCurrency &&
            r['to_currency'] == _fromCurrency,
        orElse: () => null,
      );

      if (reverseRateObj != null) {
        double reverseBuyRate = double.parse(
          reverseRateObj['buy_rate'].toString(),
        );
        double reverseSellRate = double.parse(
          reverseRateObj['sell_rate'].toString(),
        );
        // If reverse buy_rate is 1.00, use sell_rate directly
        if (reverseBuyRate == 1.0 && reverseSellRate > 1.0) {
          _currentRate = reverseSellRate;
        } else if (reverseBuyRate > 0) {
          _currentRate = 1.0 / reverseBuyRate;
        } else {
          _currentRate = 0.0;
        }
      } else {
        _currentRate = 0.0; // Unknown
      }
    }

    // Recalculate if amount exists
    if (_amountController.text.isNotEmpty) {
      _onAmountChanged(_amountController.text);
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _updateRate();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleExchange() async {
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

    if (_amountController.text.isEmpty) {
      ErrorDialog.show(context, message: 'يرجى إدخال المبلغ'.tr());
      return;
    }

    if (!_hasEnoughBalance) {
      _showInsufficientFundsDialog();
      return;
    }

    final user = await ApiService.getCachedUser();
    final senderName = user?['full_name'] ?? 'N/A';
    final senderId = user?['username'] ?? user?['phone_number'] ?? 'N/A';

    // إظهار تفاصيل المصارفة
    TransactionDetailsBottomSheet.show(
      // ignore: use_build_context_synchronously
      context,
      isDarkMode: widget.isDarkMode,
      amount: _amountController.text,
      currency: _fromCurrency,
      transactionType: 'exchangeBetweenAccounts'.tr(),
      exchangeRate:
          '1 ${_getCurrencyDisplay(_fromCurrency)} = ${_currentRate.toStringAsFixed(4)} ${_getCurrencyDisplay(_toCurrency)}',
      receiveAmount: _conversionResult.replaceAll('≈ ', ''),
      recipientName: '',
      recipientId: '',
      senderName: senderName,
      senderId: senderId,
      onExecute: () async {
        final result = await SecurityConfirmationDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
        );
        if (!mounted) return;

        if (result != null) {
          _executeExchange(result is String ? result : null);
        }
      },
    );
  }

  Future<void> _executeExchange(String? password) async {
    setState(() => _isLoading = true);

    try {
      double amount = double.parse(_amountController.text);

      final responseData = await ApiService.convertCurrency(
        _fromCurrency,
        _toCurrency,
        amount,
        password: password,
      );

      final String refNumber =
          responseData['data']['reference_number'] ?? 'N/A';
      final double amountTo =
          double.tryParse(
            responseData['data']['amount_received']?.toString() ?? '',
          ) ??
          0.0;

      await _fetchCounts();

      final targetBalance =
          double.tryParse(_balances[_toCurrency]?.toString() ?? '0') ?? 0.0;

      await NotificationService.showNotification(
        id: 2,
        title: 'notification_exchange_success_title'.tr(),
        body: 'notification_exchange_success_body'.tr(
          args: [
            _getCurrencyDisplay(_fromCurrency),
            _getCurrencyDisplay(_toCurrency),
            targetBalance.toString(),
          ],
        ),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog(refNumber, amount, amountTo, targetBalance);
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

  Future<void> _showSuccessDialog(
    String refNumber,
    double amountFrom,
    double amountTo,
    double currentBalance,
  ) async {
    // تشغيل صوت النجاح (Apple Pay style)
    SoundService.playSuccessSound();

    await ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'ايصال العملية',
      mainAmount: formatAmountDisplay(amountTo),
      mainCurrency: _toCurrency,
      details: [
        ReceiptRowData(label: 'رقم المرجع', value: refNumber, isCopyable: true),
        ReceiptRowData(label: 'العملية', value: 'مصارفة عملة'),
        ReceiptRowData(
          label: 'المبلغ المحول',
          value: '${formatAmountDisplay(amountFrom)} $_fromCurrency',
        ),
        ReceiptRowData(
          label: 'سعر الصرف',
          value:
              '1 ${_getCurrencyDisplay(_fromCurrency)} = ${_currentRate.toStringAsFixed(4)} ${_getCurrencyDisplay(_toCurrency)}',
        ),
        ReceiptRowData(
          label: 'تاريخ العملية',
          value: intl.DateFormat(
            'yyyy-MM-dd (hh:mm a)',
            'en_US',
          ).format(DateTime.now()),
        ),
      ],
      shareText:
          '✅ إيصال تحويل بين الحسابات - نظام صيفي باي\n\n'
          'المبلغ المحول: ${formatAmountDisplay(amountFrom)} $_fromCurrency\n'
          'المبلغ المستلم: ${formatAmountDisplay(amountTo)} $_toCurrency\n'
          'الرقم المرجع: $refNumber\n',
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor:
                Colors.transparent, // Background handled by container
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 50,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'insufficient_balance_title'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'يرجى التأكد من توفر رصيد كافي في محفظة $_fromCurrency لإتمام العملية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'ok'.tr(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _onAmountChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _amountInWords = '';
        _conversionResult = '';
      });
      return;
    }

    double? amount = double.tryParse(value);
    if (amount != null) {
      double balance =
          double.tryParse(_balances[_fromCurrency].toString()) ?? 0.0;
      bool enough = balance >= amount;

      setState(() {
        _amountInWords =
            '${formatAmountToArabicWords(amount)} ${_fromCurrency == 'YER' ? 'ريال يمني' : (_fromCurrency == 'USD' ? 'دولار' : 'ريال سعودي')}';
        _hasEnoughBalance = enough;

        if (_currentRate > 0) {
          double result = amount * _currentRate;
          _conversionResult =
              '≈ ${result.toStringAsFixed(2)} ${_getCurrencyDisplay(_toCurrency)}';
        }
      });
    } else {
      setState(() {
        _amountInWords = '';
        _hasEnoughBalance = false;
        _conversionResult = '';
      });
    }
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
                _buildPremiumHeader()
                    .animate()
                    .fade(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        CurrentBalanceCard(isDarkMode: widget.isDarkMode),
                        const SizedBox(height: 10),
                        // Currency Selection Card
                        Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    widget.isDarkMode
                                        ? AppColors.cardDark
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: widget.isDarkMode ? 0.3 : 0.05,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // FROM
                                  _buildPremiumDropdownField(
                                    label: 'label_from_account'.tr(),
                                    value: _fromCurrency,
                                    balance: _balances[_fromCurrency],
                                    icon: Icons.outbound_rounded,
                                    iconColor: Colors.orange,
                                    onChanged: (val) {
                                      setState(() {
                                        _fromCurrency = val!;
                                        _updateRate();
                                      });
                                    },
                                  ),

                                  // SWAP BUTTON
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Divider(
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white10
                                                  : Colors.black12,
                                        ),
                                        InkWell(
                                              onTap: _swapCurrencies,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryBlue,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .primaryBlue
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.swap_vert_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            )
                                            .animate(
                                              onPlay:
                                                  (controller) => controller
                                                      .repeat(reverse: true),
                                            )
                                            .scale(
                                              begin: const Offset(1, 1),
                                              end: const Offset(1.05, 1.05),
                                              duration: 2.seconds,
                                            ),
                                      ],
                                    ),
                                  ),

                                  // TO
                                  _buildPremiumDropdownField(
                                    label: 'label_to_account'.tr(),
                                    value: _toCurrency,
                                    balance: _balances[_toCurrency],
                                    icon: Icons.move_to_inbox_rounded,
                                    iconColor: Colors.green,
                                    onChanged: (val) {
                                      setState(() {
                                        _toCurrency = val!;
                                        _updateRate();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fade(duration: 400.ms, delay: 100.ms)
                            .slideX(begin: 0.1, end: 0),

                        // Balance Hint
                        const SizedBox(height: 8),

                        const SizedBox(height: 8),

                        // Rate Display
                        if (_fromCurrency == _toCurrency)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'عذراً لا تستطيع اختيار نفس العملة',
                                    style: GoogleFonts.cairo(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().shake(),
                        const SizedBox(height: 12),

                        // Amount field
                        _buildPremiumAmountField()
                            .animate()
                            .fade(duration: 400.ms, delay: 300.ms)
                            .slideX(begin: 0.1, end: 0),

                        const SizedBox(height: 40),

                        // Submit
                        _buildSubmitButton()
                            .animate()
                            .fade(duration: 400.ms, delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.adaptiveIcon(
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
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
              color: AppColors.adaptiveIcon(
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
            'exchange_transfer_title'.tr(),
            style: GoogleFonts.cairo(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDropdownField({
    required String label,
    required String value,
    required String? balance,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            /* if (balance != null)
              Text(
                '${"availableBalance".tr()}: $balance $value',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ), */
          ],
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    dropdownColor:
                        widget.isDarkMode ? AppColors.cardDark : Colors.white,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.adaptiveIcon(widget.isDarkMode),
                    ),
                    items:
                        ['YER', 'USD', 'SAR']
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  _getCurrencyDisplay(c),
                                  style: GoogleFonts.cairo(
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 8),
          child: Text(
            'amount_to_convert_label'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDarkMode ? 0.3 : 0.05,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              ArabicToEnglishNumbersFormatter(),
              FilteringTextInputFormatter.deny(RegExp(r'^0')),
            ],
            onChanged: _onAmountChanged,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
              prefixIcon: Icon(
                Icons.monetization_on_rounded,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        if (_amountInWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Text(
              _amountInWords,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_conversionResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.compare_arrows_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  _conversionResult,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit =
        !_isLoading &&
        _amountController.text.isNotEmpty &&
        _hasEnoughBalance &&
        _currentRate > 0 &&
        _fromCurrency != _toCurrency;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: canSubmit ? AppColors.primaryGradient : null,
        color: canSubmit ? null : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        boxShadow:
            canSubmit
                ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton(
        onPressed: canSubmit ? _handleExchange : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : Text(
                  !_hasEnoughBalance
                      ? 'insufficient_balance_label'.tr()
                      : 'review_confirm_button'.tr(),
                  //? 'insufficient_balance_label'.tr() : 'review_confirm_button'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
