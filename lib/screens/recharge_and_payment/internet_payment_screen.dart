import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saifix/components/current_balance_card.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../../core/app_colors.dart';
import '../../services/alzajil_service.dart';
import '../../services/api_service.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/security_verification_dialog.dart';
import '../../components/loading_overlay.dart';
import '../account_confirmation_screen.dart';
import '../../services/sound_service.dart';
import '../../services/favorites_service.dart';
import '../../components/error_dialog.dart';
import '../../widgets/receipt_dialog.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../components/recharge/add_favorite_dialog.dart';
import '../../components/favorites_bottom_sheet.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../services/balance_service.dart';
import '../../services/contact_service.dart';

class InternetPaymentScreen extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final int serviceCode;
  final int itemCode;

  const InternetPaymentScreen({
    super.key,
    required this.isDarkMode,
    this.title = 'تسديد انترنت ADSL',
    this.serviceCode = 42111,
    this.itemCode = 1,
  });

  @override
  State<InternetPaymentScreen> createState() => _InternetPaymentScreenState();
}

class _InternetPaymentScreenState extends State<InternetPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final AlzajilService _alzajilService = AlzajilService();

  bool _isLoading = false;
  String? _inquiryRef;
  bool _isFavorite = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        balanceService.refreshBalance();
        _checkIfFavorite(_phoneController.text);
      }
    });
  }

  Future<void> _checkBalance() async {
    if (_phoneController.text.isEmpty) {
      ErrorDialog.show(context, message: 'الرجاء إدخال رقم الهاتف أولاً');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _alzajilService.checkBalance(
        serviceCode: widget.serviceCode,
        subscriberNo: _phoneController.text,
        actionCode: 4006,
      );

      if (mounted) {
        if (result['RC'] == 0) {
          setState(
            () =>
                _inquiryRef =
                    result['REF']?.toString() ?? result['ref']?.toString(),
          );
          _showBalanceDetails(result);
        } else {
          ErrorDialog.show(context, message: result['MSG'] ?? 'فشل الاستعلام');
        }
      }
    } catch (e) {
      if (mounted) ErrorDialog.show(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

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

    String recipientName = contactService.getContactName(_phoneController.text);

    if (!mounted) return;
    TransactionDetailsBottomSheet.show(
      context,
      isDarkMode: widget.isDarkMode,
      amount: formatAmountDisplay(double.tryParse(_amountController.text) ?? 0),
      currency: 'YER',
      transactionType: widget.title,
      recipientName: recipientName,
      recipientId: _phoneController.text,
      onExecute: () async {
        final auth = await SecurityVerificationDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
        );
        if (auth) _executePayment();
      },
    );
  }

  Future<void> _executePayment() async {
    setState(() => _isLoading = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String fallbackRef = timestamp.substring(timestamp.length - 10);

    try {
      // ⏳ فجوة زمنية (Async Gap) أثناء انتظار السيرفر
      final result = await _alzajilService.sendPayment(
        actionCode: 7100,
        serviceCode: widget.serviceCode,
        amount: amount,
        subscriberNo: _phoneController.text,
        subscriberType: 1,
        ref: _inquiryRef ?? fallbackRef,
        item: widget.itemCode,
      );

      // 🛑 حماية مبكرة: إذا أغلق المستخدم الشاشة أثناء الطلب، توقف فوراً
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['RC'] == 0 || result['RC'] == '0') {
        SoundService.playSuccessSound();
        final ref = result['REF'] ?? result['ref'] ?? fallbackRef;

        // ✅ أصبح استدعاء الـ ReceiptDialog آمناً تلقائياً ولا يحتاج لشرط إضافي هنا
        await ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'إيصال ${widget.title}',
          mainAmount: formatAmountDisplay(amount),
          mainCurrency: 'YER',
          details: [
            ReceiptRowData(label: 'الخدمة', value: widget.title),
            ReceiptRowData(label: 'رقم المشترك', value: _phoneController.text),
            ReceiptRowData(
              label: 'المرجع',
              value: ref.toString(),
              isCopyable: true,
            ),
          ],
          shareText: '✅ إيصال ${widget.title} - صيفي باي\nالمرجع: $ref',
          onClose: () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          },
        );

        _phoneController.clear();
        _amountController.clear();
        _inquiryRef = null;
        balanceService.refreshBalance();
      } else {
        // ✅ آمن الآن لأننا قمنا بالتحقق الفوري بعد الـ await في الأعلى
        ErrorDialog.show(
          context,
          message: result['MSG'] ?? 'فشل تنفيذ العملية',
        );
      }
    } catch (e) {
      // 🛑 حماية كتلة الـ catch: في حال حدوث خطأ شبكة أو استثناء
      if (!mounted) return;

      setState(() => _isLoading = false);
      ErrorDialog.show(context, message: e.toString()); // ✅ آمن الآن
    }
  }

  Future<void> _checkIfFavorite(String id) async {
    if (id.isEmpty) {
      if (mounted) setState(() => _isFavorite = false);
      return;
    }
    final fav = await favoritesService.isFavorite(id, FavoriteType.recharge);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_phoneController.text.isEmpty) return;

    if (_isFavorite) {
      await favoritesService.removeFavorite(
        _phoneController.text,
        FavoriteType.recharge,
      );
      _checkIfFavorite(_phoneController.text);
    } else {
      AddFavoriteDialog.show(
        context,
        isDarkMode: widget.isDarkMode,
        initialType: FavoriteType.recharge,
        initialId: _phoneController.text,
        initialAmount: _amountController.text,
        onAdded: () {
          _checkIfFavorite(_phoneController.text);
        },
      );
    }
  }

  void _showFavoritesDialog() {
    FavoritesBottomSheet.show(
      context,
      type: FavoriteType.recharge,
      isDarkMode: widget.isDarkMode,
      onSelected: (phone, name, amount) {
        setState(() {
          _phoneController.text = phone;
          if (amount != null && amount.isNotEmpty) {
            _amountController.text = amount;
          }
        });
        _checkIfFavorite(phone);
      },
    );
  }

  void _showBalanceDetails(Map<String, dynamic> result) {
    String balance = (result['BAL'] ?? result['bal'] ?? '0.00').toString();
    Map<String, dynamic>? detailedData;
    String? remain;
    String? baqaAmt;
    String? expDate;
    String? subName;

    try {
      dynamic sd = result['SD'] ?? result['sd'];
      if (sd != null) {
        if (sd is String) {
          detailedData = jsonDecode(sd);
        } else if (sd is Map<String, dynamic>) {
          detailedData = sd;
        }
      }

      if (detailedData != null) {
        balance =
            (detailedData['Balance'] ??
                    detailedData['remain'] ??
                    detailedData['REMAIN'] ??
                    detailedData['BillAmt'] ??
                    balance)
                .toString();
        remain =
            (detailedData['remain'] ??
                    detailedData['REMAIN'] ??
                    detailedData['Balance'])
                ?.toString();
        baqaAmt =
            (detailedData['BaqaAmt'] ?? detailedData['Amount'])?.toString();
        expDate =
            (detailedData['ExpDate'] ??
                    detailedData['EXPDATE'] ??
                    detailedData['ExpiryDate'])
                ?.toString();
        subName =
            (detailedData['SubName'] ??
                    detailedData['Name'] ??
                    detailedData['SubscriberName'])
                ?.toString();
      }
    } catch (e) {
      customPrint("Error parsing SD data: $e");
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = widget.isDarkMode;
        final bool isBill = widget.serviceCode == 42106;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.scaffoldDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBill
                    ? 'fixed_phone_details'.tr()
                    : 'internet_subscription_details'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildBalanceRow(
                'subscriber_number_label'.tr(),
                _phoneController.text,
              ),
              if (subName != null && subName.isNotEmpty)
                _buildBalanceRow('subscriber_name_label'.tr(), subName),

              if (remain != null)
                _buildBalanceRow(
                  isBill
                      ? 'amount_due_label'.tr()
                      : 'remaining_balance_label'.tr(),
                  '$remain ${'currency_short'.tr()}',
                  isBold: true,
                )
              else
                _buildBalanceRow(
                  isBill
                      ? 'amount_due_label'.tr()
                      : 'remaining_balance_label'.tr(),
                  '${formatAmountDisplay(double.tryParse(balance) ?? 0.0)} ${'currency_short'.tr()}',
                  isBold: true,
                ),

              if (baqaAmt != null)
                _buildBalanceRow(
                  'package_price_label'.tr(),
                  '$baqaAmt ${'currency_short'.tr()}',
                ),

              if (!isBill && expDate != null && expDate != 'N/A')
                _buildBalanceRow('expiry_date_label'.tr(), expDate),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'close'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceRow(String label, String value, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
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
                _buildPremiumHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CurrentBalanceCard(
                            isDarkMode: widget.isDarkMode,
                            forceCurrency: 'YER',
                          ),
                          const SizedBox(height: 20),
                          _buildServiceInfoCard(),
                          const SizedBox(height: 20),
                          _buildPhoneInput(),
                          if (_phoneError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, right: 12),
                              child: Text(
                                _phoneError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          _buildAmountInput(),
                          _buildAmountWords(),
                          const SizedBox(height: 30),
                          _buildSubmitButton(),
                          const SizedBox(height: 20),
                          _buildCheckBalanceButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            LoadingOverlay(
              isDarkMode: widget.isDarkMode,
              message: 'جاري المعالجة...',
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
              color: AppColors.primaryBlue.withValues(
                alpha: widget.isDarkMode ? 0.05 : 0.03,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              size: 20,
            ),
          ),
          Text(
            widget.title,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Widget _buildWalletBalanceCard() {
  //   return CurrentBalanceCard(
  //     isDarkMode: widget.isDarkMode,
  //     forceCurrency: 'YER',
  //   );
  // }

  Widget _buildServiceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'payment_service_label'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Text(
                'ADSL / Fiber / Fixed Phone',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: 'subscriber_number'.tr(),
        hintText: 'أدخل رقم الهاتف الأرضي',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        filled: true,
        fillColor:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
        prefixIcon: Icon(
          Icons.phone_rounded,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed:
                  _phoneController.text.isEmpty
                      ? _showFavoritesDialog
                      : _toggleFavorite,
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: AppColors.secondaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _pickContact,
              icon: const Icon(
                Icons.contacts_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(8),
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (val) {
        if (val == null || val.isEmpty) return 'enter_phone_number'.tr();
        if (val.length != 8 || !val.startsWith('0')) {
          return 'adsl_must_be_8_digits'.tr();
        }
        return null;
      },
      onChanged: (val) {
        _checkIfFavorite(val);
        setState(() {
          if (val.isEmpty) {
            _phoneError = null;
          } else if (val.length != 8 || !val.startsWith('0')) {
            _phoneError = 'adsl_must_be_8_digits'.tr();
          } else {
            _phoneError = null;
          }
        });
      },
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      onChanged: (val) => setState(() {}),
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: 'amount'.tr(),
        hintText: '0.00',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        filled: true,
        fillColor:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
        prefixIcon: Icon(
          Icons.monetization_on_rounded,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        suffixText: 'YER',
        suffixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'^[0.]')),
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (val) {
        if (val == null || val.isEmpty) return 'enter_amount'.tr();
        if ((double.tryParse(val) ?? 0) <= 0) return 'invalid_amount'.tr();
        return null;
      },
    );
  }

  Widget _buildAmountWords() {
    if (_amountController.text.isEmpty) return const SizedBox.shrink();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 10),
      child: Text(
        '${formatAmountToArabicWords(amount)} ريال يمني',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white60 : Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'pay_now'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckBalanceButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _checkBalance,
        icon: const Icon(Icons.search_rounded, size: 18),
        label: const Text(
          'استعلام عن الرصيد',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      contactService.preLoadContacts(force: true);
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      var full = contact;
      if (contact.phones.isEmpty) {
        final fetched = await FlutterContacts.getContact(
          contact.id,
          withProperties: true,
        );
        if (fetched != null) full = fetched;
      }
      if (full.phones.isNotEmpty) {
        String raw = full.phones.first.number;
        String phone = raw.replaceAll(RegExp(r'\D'), '');
        if (phone.startsWith('967')) phone = phone.substring(3);
        if (phone.length > 9) phone = phone.substring(phone.length - 9);
        setState(() => _phoneController.text = phone);
        _checkIfFavorite(phone);
      }
    }
  }
}
