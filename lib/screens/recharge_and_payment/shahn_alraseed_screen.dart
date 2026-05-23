import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../../core/app_colors.dart';
import '../../services/alzajil_service.dart';
import '../../services/api_service.dart';
import '../../components/security_confirmation_dialog.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/loading_overlay.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../widgets/receipt_dialog.dart';
import '../../components/recharge/add_favorite_dialog.dart';
import '../../services/session_manager.dart';
import '../account_confirmation_screen.dart';
import '../../services/sound_service.dart';
import '../../services/favorites_service.dart';
import '../../services/contact_service.dart';
import '../../components/favorites_bottom_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../components/error_dialog.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../components/current_balance_card.dart';
import '../../services/balance_service.dart';

class ShahnAlraseedScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? initialPhone;

  const ShahnAlraseedScreen({
    super.key,
    required this.isDarkMode,
    this.initialPhone,
  });

  @override
  State<ShahnAlraseedScreen> createState() => _ShahnAlraseedScreenState();
}

class _ShahnAlraseedScreenState extends State<ShahnAlraseedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;
  String _loadingMessage = 'shipping_in_progress'.tr();
  String? _selectedProvider;
  int? _selectedServiceCode; // e.g. 42103 for Yemen Mobile
  int _subscriberType = 0; // 0: Prepaid, 1: Billing

  final AlzajilService _alzajilService = AlzajilService();

  // S2D Integration

  // Balance & Validation
  bool _hasEnoughBalance = true;
  String _formattedAmount = '';
  String? _phoneError;
  bool _hasTransactionOccurred = false;
  String? _amountError;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchBalances();
        if (widget.initialPhone != null) {
          _phoneController.text = widget.initialPhone!;
          _autoSelectProvider(widget.initialPhone!);
          _checkIfFavorite(widget.initialPhone!);
        }
      }
    });
  }

  Future<void> _fetchBalances({bool forceRefresh = false}) async {
    await balanceService.refreshBalance(forceRefresh: forceRefresh);
    if (mounted && _amountController.text.isNotEmpty) {
      _onAmountChanged(_amountController.text);
    }
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) {
      setState(() {
        _formattedAmount = '';
        _hasEnoughBalance = true;
      });
      return;
    }
    double? amount = double.tryParse(val);
    if (amount != null) {
      double balance =
          double.tryParse(balanceService.balances['YER'] ?? '0.0') ?? 0.0;
      setState(() {
        _hasEnoughBalance = balance >= amount;
        _amountError = amount < 50 ? 'أدنى مبلغ هو 50 ريال' : null;
        _formattedAmount = formatAmountDisplay(amount);
      });
    } else {
      setState(() {
        _amountError = 'المبلغ غير صحيح';
      });
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
        _phoneController.text = phone;
        if (amount != null && amount.isNotEmpty) {
          _amountController.text = amount;
          _onAmountChanged(amount);
        }
        _autoSelectProvider(phone);
        _checkIfFavorite(phone);
      },
    );
  }

  final List<Map<String, dynamic>> items = [
    {
      'title': 'yemen_mobile_title'.tr(),
      'logoLabel': 'yemen_mobile_logo'.tr(),
      'color': const Color(0xFFB00049),
      'code': 42103,
      'prefixes': ['77', '78'],
      'imagePath': 'assets/images/networks/YemenMobile.png',
    },
    {
      'title': 'sabafon_credit_title'.tr(),
      'logoLabel': 'sabafon_logo'.tr(),
      'color': Colors.blue.shade700,
      'code': 42101,
      'prefixes': ['71'],
      'imagePath': 'assets/images/networks/sabafon.png',
    },
    {
      'title': 'you_credit_title'.tr(),
      'logoLabel': 'you_logo'.tr(),
      'color': Colors.yellow.shade700,
      'code': 42102,
      'prefixes': ['73'],
      'imagePath': 'assets/images/networks/MTN.png',
    },
    {
      'title': 'why_credit_title'.tr(),
      'logoLabel': 'why_logo'.tr(),
      'color': Colors.purple.shade700,
      'code': 42104,
      'prefixes': ['70'],
      'imagePath': 'assets/images/networks/Why.png',
    },
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatExpiryDate(String rawDate) {
    if (rawDate.length == 14) {
      try {
        final year = rawDate.substring(0, 4);
        final month = rawDate.substring(4, 6);
        final day = rawDate.substring(6, 8);
        int hourVal = int.parse(rawDate.substring(8, 10));
        final minute = rawDate.substring(10, 12);
        final second = rawDate.substring(12, 14);

        String period = 'AM';
        if (hourVal >= 12) {
          period = 'PM';
          if (hourVal > 12) hourVal -= 12;
        }
        if (hourVal == 0) hourVal = 12;

        return '$year-$month-$day $hourVal:$minute:$second $period';
      } catch (e) {
        return rawDate;
      }
    }
    return rawDate;
  }

  Future<void> _loadS2DOffers() async {
    // UI selection now directly affects provider/offer logic if needed
  }
  Future<void> _checkBalance() async {
    if (_selectedServiceCode == null || _phoneController.text.length != 9) {
      ErrorDialog.show(context, message: 'please_enter_number_first'.tr());
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingMessage = 'checking_balance'.tr();
    });
    try {
      int ac = (_selectedServiceCode == 42103) ? 4006 : 4001;
      final result = await _alzajilService.checkBalance(
        serviceCode: _selectedServiceCode!,
        subscriberNo: _phoneController.text,
        actionCode: ac,
      );
      if (mounted) {
        if (result['RC'] == 0) {
          _showBalanceDetails(result);
        } else {
          _showErrorDialog(result['MSG'] ?? 'balance_check_failed'.tr());
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      sessionManager.isOperationInProgress = false;
    }
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

        setState(() {
          _phoneController.text = phone;
        });

        _autoSelectProvider(phone);
      } else {
        if (mounted) {
          ErrorDialog.show(
            context,
            message: 'لا يحتوي جهة الاتصال على رقم هاتف',
          );
        }
      }
    }
  }

  /*
  Widget _buildSubscriberTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              label: 'prepaid_label'.tr(),
              isSelected: _subscriberType == 0,
              onTap: () {
                setState(() => _subscriberType = 0);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeButton(
              label: 'postpaid_label'.tr(),
              isSelected: _subscriberType == 1,
              onTap: () {
                setState(() => _subscriberType = 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue
                  : (widget.isDarkMode
                      ? AppColors.cardDark
                      : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected
                      ? Colors.white
                      : (widget.isDarkMode ? Colors.white70 : Colors.black87),
              fontWeight: FontWeight.bold,

              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
*/

  void _showBalanceDetails(Map<String, dynamic> result) {
    customPrint("DEBUG_BALANCE_RAW: $result");
    List<Map<String, String>> details = [];
    String balance = (result['BAL'] ?? result['bal'] ?? '0.00').toString();
    String loan =
        (result['LOAN'] ??
                result['CREDIT'] ??
                result['Loan'] ??
                result['Credit'] ??
                result['loan'] ??
                result['credit'] ??
                result['loanAmount'] ??
                '0')
            .toString();
    if (loan.toLowerCase() == "null") loan = "0";

    dynamic rawSd = result['SD'] ?? result['sd'];
    dynamic decodedSd;
    if (rawSd != null) {
      try {
        if (rawSd is String) {
          String trimmed = rawSd.trim();
          if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            decodedSd = jsonDecode(trimmed);
          }
        } else {
          decodedSd = rawSd;
        }
      } catch (_) {
        /* ignore JSON parse errors */
      }
    }
    if (decodedSd is Map && (loan == "0" || loan == "0.00")) {
      var sdLoan = decodedSd['CREDIT'] ?? decodedSd['LOAN'];
      if (sdLoan != null) loan = sdLoan.toString();
    }
    var mtValue = result['MT'] ?? result['mt'];
    if (decodedSd is Map) {
      mtValue =
          decodedSd['MT'] ??
          decodedSd['mt'] ??
          decodedSd['Mt'] ??
          decodedSd['subscriber_type'] ??
          mtValue;
    }

    String lineType =
        (mtValue.toString() == "0" || mtValue.toString() == "1")
            ? "دفع مسبق"
            : "فوترة";

    // Restore detailed parsing for packages and expiry
    if (decodedSd != null) {
      if (decodedSd is Map && (loan == "0" || loan == "0.00")) {
        var sdLoan =
            decodedSd['CREDIT'] ??
            decodedSd['LOAN'] ??
            decodedSd['Credit'] ??
            decodedSd['Loan'] ??
            decodedSd['credit'] ??
            decodedSd['loan'] ??
            decodedSd['loanAmount'] ??
            decodedSd['LoanAmount'];
        if (sdLoan != null) loan = sdLoan.toString();
      }
      if (loan.toLowerCase() == "null") loan = "0";

      if (decodedSd is List) {
        for (var offer in decodedSd) {
          if (offer is Map) {
            details.add({
              'label':
                  (offer['offer_name'] ?? offer['Name'] ?? 'باقة').toString(),
              'value': _formatExpiryDate(
                (offer['ExpDate'] ??
                        offer['ExpiryDate'] ??
                        offer['Expiry'] ??
                        '')
                    .toString(),
              ),
              'prefix': 'تاريخ انتهاء ',
            });
          }
        }
      } else if (decodedSd is Map) {
        if (decodedSd['Balance'] != null || decodedSd['balance'] != null) {
          balance =
              (decodedSd['Balance'] ?? decodedSd['balance'] ?? balance)
                  .toString();
        }
        var offersList = decodedSd['Offers'] ?? decodedSd['offers'];
        if (offersList is String) {
          try {
            offersList = jsonDecode(offersList);
          } catch (_) {
            /* ignore JSON parse errors */
          }
        }
        if (offersList is List && offersList.isNotEmpty) {
          final lastOffer = offersList.last;
          if (lastOffer is Map) {
            details.add({
              'label': 'نوع الباقة',
              'value': (lastOffer['offer_name'] ?? 'باقة').toString(),
            });
            details.add({
              'label': 'تاريخ انتهاء الباقة',
              'value': _formatExpiryDate(
                (lastOffer['ExpDate'] ?? lastOffer['exp_date'] ?? '')
                    .toString(),
              ),
            });
          }
        } else if (decodedSd['Package'] != null) {
          details.add({
            'label': 'الباقة',
            'value': decodedSd['Package'].toString(),
          });
          details.add({
            'label': 'تاريخ الانتهاء',
            'value': _formatExpiryDate(
              (decodedSd['ExpiryDate'] ?? decodedSd['Expiry'] ?? '').toString(),
            ),
          });
        }
      }
    } else if (rawSd is String && rawSd.contains(',')) {
      List<String> parts = rawSd.split(',');
      if (parts.isNotEmpty) {
        String name = parts[0].trim();
        if (name.isNotEmpty && name != "null") {
          details.add({'label': 'اسم المشترك', 'value': name});
        }
      }
      if (parts.length >= 2) {
        details.add({'label': 'تاريخ انتهاء الخط', 'value': parts[1].trim()});
      }
      if ((balance == "0.00" || balance == "0") && parts.length >= 3) {
        balance = parts[2].trim();
      }
    }

    // Synchronized Logic with SadaadBaqatScreen:
    // 1. Extract MT Value robustly
    var mtValueFromRes = result['MT'] ?? result['mt'];
    if (decodedSd is Map) {
      mtValueFromRes =
          decodedSd['MT'] ??
          decodedSd['mt'] ??
          decodedSd['Mt'] ??
          decodedSd['subscriber_type'] ??
          mtValueFromRes;
    }

    // 2. If Postpaid (MT=2), show the credit value as the main balance, then force loan to 0
    if (mtValueFromRes.toString() == '2') {
      if (loan != "0" && loan != "0.00") {
        balance = loan;
      } else {
        balance =
            (result['CREDIT'] ??
                    result['credit'] ??
                    result['Credit'] ??
                    balance)
                .toString();
      }
      loan = "0";
    }

    // Hide Loan row for Postpaid (MT=2) as per requirement
    bool hideLoan = (mtValueFromRes.toString() == '2');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = widget.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBalanceRow('remaining_balance'.tr(), balance, isBold: true),
              _buildBalanceRow('line_type'.tr(), lineType),
              if (!hideLoan) _buildBalanceRow('loan'.tr(), loan),
              ...details.map(
                (d) => _buildBalanceRow(
                  (d['prefix'] ?? '') + d['label']!,
                  d['value']!,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'close'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceRow(String label, String value, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,

              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processRecharge() async {
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

    if (!_formKey.currentState!.validate()) return;
    if (_phoneController.text.length != 9) return;
    if (!_hasEnoughBalance || _amountError != null) return;

    sessionManager.isOperationInProgress = true;

    String recipientName = _phoneController.text;

    recipientName = contactService.getContactName(_phoneController.text);

    TransactionDetailsBottomSheet.show(
      context,
      isDarkMode: widget.isDarkMode,
      amount: formatAmountDisplay(double.tryParse(_amountController.text) ?? 0),
      currency: 'YER',
      transactionType: 'recharge_balance'.tr(),
      networkName: _selectedProvider ?? "",
      recipientName: recipientName,
      recipientId: _phoneController.text,
      onExecute: () async {
        final result = await SecurityConfirmationDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
        );
        if (!mounted) return;

        if (result != null) {
          _executeRecharge(result is String ? result : null);
        }
      },
    );
  }

  Future<void> _executeRecharge(String? password) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'shipping_in_progress'.tr();
    });

    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String uniqueRef = timestamp.substring(timestamp.length - 10);
    // Logic for subscriber type:
    // Yemen Mobile: 0 = Prepaid, 1 = Postpaid (though often 1 or 2 is used)
    // GSM (Sabafon, YOU, Y): 1 = Prepaid, 2 = Postpaid
    int apiSubscriberType = (_subscriberType == 0) ? 1 : 2;
    if (_selectedServiceCode == 42103 && _subscriberType == 0) {
      apiSubscriberType = 0; // Only Yemen Mobile Prepaid uses 0 in Alzajil
    }

    int? item;
    // Set item = 42 for Sabafon Prepaid (Open Units)
    if (_selectedServiceCode == 42101 && _subscriberType == 0) {
      item = 42;
    }

    double inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    double finalAmount = inputAmount;

    // Special logic for Sabafon Prepaid (Item 42)
    // Convert YER to Units (1 Unit = 12.1 YER)
    if (item == 42) {
      int unitsToSend = (inputAmount / 12.1).round();
      finalAmount = unitsToSend.toDouble();
    }

    try {
      final result = await _alzajilService.sendPayment(
        actionCode: 7100,
        serviceCode: _selectedServiceCode!,
        amount: finalAmount, // Send converted UNITS

        subscriberNo: _phoneController.text,
        subscriberType: apiSubscriberType,
        item: item,
        offerId: "0",
        ref: uniqueRef,
        remarks: 'Recharge ${_amountController.text}',
      );
      if (!mounted) return;

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['RC'] == 0) {
          _hasTransactionOccurred = true;
          String ref = result['REF'] ?? uniqueRef;
          double amt = double.tryParse(_amountController.text) ?? 0.0;

          // Show receipt immediately
          SoundService.playSuccessSound();
          if (mounted) {
            await ReceiptDialog.show(
              context,
              isDarkMode: widget.isDarkMode,
              title: 'payment_receipt'.tr(),
              mainAmount: formatAmountDisplay(amt),
              mainCurrency: 'YER',
              details: [
                ReceiptRowData(
                  label: 'system_prefix'.tr(),
                  value: 'saifi_pay_system'.tr(),
                ),
                ReceiptRowData(
                  label: 'provider_label'.tr(),
                  value: _selectedProvider ?? '',
                ),
                ReceiptRowData(
                  label: 'phone_number'.tr(),
                  value: _phoneController.text,
                ),
                ReceiptRowData(
                  label: 'reference_label'.tr(),
                  value: ref,
                  isCopyable: true,
                ),
              ],
              shareText:
                  '✅ إيصال شحن رصيد - صيفي باي\nالمبلغ: ${formatAmountDisplay(amt)} YER\nالمرجع: $ref',
              onClose: () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
            );
          }

          // Refresh balance in background
          _fetchBalances(forceRefresh: true);
        } else {
          _showErrorDialog(result['MSG'] ?? 'فشل الشحن');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    } finally {
      sessionManager.isOperationInProgress = false;
    }
  }

  void _onProviderTap(String title, int code, {bool keepPhone = false}) {
    setState(() {
      _selectedProvider = title;
      _selectedServiceCode = code;
    });
    if (!keepPhone) _phoneController.clear();
    _loadS2DOffers();
  }

  Widget _buildSelectedProviderBanner() {
    if (_selectedServiceCode == null) return const SizedBox.shrink();
    final provider = items.firstWhere(
      (p) => p['code'] == _selectedServiceCode,
      orElse: () => items.first,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: provider['color'].withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: provider['color'].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              provider['imagePath'],
              height: 24,
              width: 24,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) =>
                      Icon(Icons.cell_wifi, size: 20, color: provider['color']),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            provider['title'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    ErrorDialog.show(context, message: msg);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // color: widget.isDarkMode ? AppColors.scaffoldDark : Colors.transparent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isDarkMode ? 0.3 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed:
                    () => Navigator.pop(context, _hasTransactionOccurred),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor:
                      widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                'recharge_balance'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48), // Spacer
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, _hasTransactionOccurred);
      },
      child: Scaffold(
        backgroundColor:
            widget.isDarkMode
                ? AppColors.scaffoldDark
                : const Color(0xFFF8F9FE),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader()
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 10,
                                bottom: 8,
                              ),
                              child: Text(
                                "phone_number".tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.adaptiveIcon(
                                    widget.isDarkMode,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              widget.isDarkMode
                                                  ? AppColors.cardDark
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color:
                                                _phoneError != null
                                                    ? Colors.red.withValues(
                                                      alpha: 0.5,
                                                    )
                                                    : Colors.transparent,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha:
                                                    widget.isDarkMode
                                                        ? 0.2
                                                        : 0.03,
                                              ),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          textAlign: TextAlign.start,
                                          textDirection: ui.TextDirection.ltr,
                                          style: TextStyle(
                                            color:
                                                widget.isDarkMode
                                                    ? Colors.white
                                                    : AppColors.textBlack,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            letterSpacing: 2,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '7XXXXXXXX',
                                            hintStyle: TextStyle(
                                              color:
                                                  widget.isDarkMode
                                                      ? Colors.white24
                                                      : Colors.black12,
                                              letterSpacing: 2,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.phone_android_rounded,
                                              color: AppColors.adaptiveIcon(
                                                widget.isDarkMode,
                                              ),
                                              size: 20,
                                            ),
                                            suffixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                    _isFavorite
                                                        ? Icons.favorite_rounded
                                                        : Icons
                                                            .favorite_border_rounded,
                                                    color:
                                                        AppColors.secondaryBlue,
                                                    size: 20,
                                                  ),
                                                  onPressed:
                                                      _phoneController
                                                              .text
                                                              .isEmpty
                                                          ? _showFavoritesDialog
                                                          : _toggleFavorite,
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                    Icons.contacts_rounded,
                                                    color:
                                                        AppColors.primaryBlue,
                                                    size: 20,
                                                  ),
                                                  onPressed: _pickContact,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 16,
                                                ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'مطلوب';
                                            }
                                            if (value.length < 9) {
                                              return 'يجب أن يكون الرقم 9 أرقام';
                                            }
                                            return null;
                                          },
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(9),
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          onChanged: (val) {
                                            _checkIfFavorite(val);
                                            setState(() {
                                              if (val.length < 9 &&
                                                  val.isNotEmpty) {
                                                _phoneError =
                                                    'must_be_9_digits'.tr();
                                              } else {
                                                _phoneError = null;
                                              }
                                            });
                                            if (val.length >= 2) {
                                              String prefix = val.substring(
                                                0,
                                                2,
                                              );
                                              bool found = false;
                                              for (var provider in items) {
                                                if (provider['prefixes']
                                                    .contains(prefix)) {
                                                  if (_selectedServiceCode !=
                                                      provider['code']) {
                                                    _onProviderTap(
                                                      provider['title'],
                                                      provider['code'],
                                                      keepPhone: true,
                                                    );
                                                  }
                                                  if (prefix == '71') {
                                                    setState(() {
                                                      _subscriberType = 0;
                                                    });
                                                  } else if (prefix == '73' ||
                                                      prefix == '70') {
                                                    setState(() {
                                                      _subscriberType = 1;
                                                    });
                                                  }
                                                  found = true;
                                                  break;
                                                }
                                              }
                                              if (!found &&
                                                  _selectedServiceCode !=
                                                      null) {
                                                setState(() {
                                                  _selectedServiceCode = null;
                                                  _selectedProvider = null;
                                                });
                                              }
                                            } else if (val.isEmpty &&
                                                _selectedServiceCode != null) {
                                              setState(() {
                                                _selectedServiceCode = null;
                                                _selectedProvider = null;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fade(duration: 400.ms, delay: 100.ms)
                                .slideY(begin: 0.1, end: 0),

                            if (_phoneError != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  right: 12,
                                ),
                                child: Text(
                                  _phoneError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            _buildSelectedProviderBanner(),

                            if (_selectedServiceCode != null) ...[
                              const SizedBox(height: 5),
                              const SizedBox(height: 10),

                              // if (!_hideSubscriberType)
                              //   _buildSubscriberTypeSelector()
                              //       .animate()
                              //       .fade(duration: 400.ms, delay: 300.ms)
                              //       .slideY(begin: 0.1, end: 0),
                              const SizedBox(height: 15),

                              // Amount Input Section
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 10,
                                  bottom: 8,
                                ),
                                child: Text(
                                  'recharge_amount_label'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      widget.isDarkMode
                                          ? AppColors.cardDark
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                        (_amountError != null ||
                                                !_hasEnoughBalance)
                                            ? Colors.red.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: widget.isDarkMode ? 0.2 : 0.03,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                      controller: _amountController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'^[0.]'),
                                        ),
                                      ],
                                      onChanged: _onAmountChanged,
                                      style: TextStyle(
                                        color:
                                            widget.isDarkMode
                                                ? Colors.white
                                                : AppColors.textBlack,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        prefixIcon: Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: AppColors.adaptiveIcon(
                                            widget.isDarkMode,
                                          ),
                                          size: 20,
                                        ),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 15,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'YER',
                                                style: TextStyle(
                                                  color: AppColors.adaptiveIcon(
                                                    widget.isDarkMode,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'مطلوب';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null) {
                                          return 'المبلغ غير صحيح';
                                        }

                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fade(duration: 400.ms, delay: 400.ms)
                                    .slideY(begin: 0.1, end: 0),
                              ),

                              if (_formattedAmount.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.adaptiveIcon(
                                                  widget.isDarkMode,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'المبلغ: $_formattedAmount YER',
                                                style: TextStyle(
                                                  color: AppColors.adaptiveIcon(
                                                    widget.isDarkMode,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          if (!_hasEnoughBalance)
                                            Flexible(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.red,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'insufficientBalance'
                                                          .tr(),
                                                      style: const TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 5,
                                        ),
                                        child: Text(
                                          '${formatAmountToArabicWords(double.tryParse(_amountController.text) ?? 0.0)} ريال يمني',
                                          style: TextStyle(
                                            color:
                                                widget.isDarkMode
                                                    ? Colors.white60
                                                    : Colors.black54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                    children: [
                                      !(_phoneController.text.startsWith(
                                                '77',
                                              ) ||
                                              _phoneController.text.startsWith(
                                                '78',
                                              ))
                                          ? SizedBox()
                                          : Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  _isLoading ||
                                                          _phoneController
                                                                  .text
                                                                  .length !=
                                                              9 ||
                                                          !(_phoneController
                                                                  .text
                                                                  .startsWith(
                                                                    '77',
                                                                  ) ||
                                                              _phoneController
                                                                  .text
                                                                  .startsWith(
                                                                    '78',
                                                                  ))
                                                      ? null
                                                      : _checkBalance,
                                              // icon: Icon(
                                              //   Icons.info_outline_rounded,
                                              //   size: 18,
                                              //   color:
                                              //       widget.isDarkMode
                                              //           ? Colors.white
                                              //           : AppColors.primaryBlue,
                                              // ),
                                              label: Text(
                                                'balance_inquiry'.tr(),
                                                style: TextStyle(
                                                  color:
                                                      widget.isDarkMode
                                                          ? Colors.white
                                                          : AppColors
                                                              .primaryBlue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    widget.isDarkMode
                                                        ? Colors.white
                                                        : AppColors.primaryBlue,
                                                fixedSize:
                                                    const Size.fromHeight(50),
                                                side: BorderSide(
                                                  color:
                                                      widget.isDarkMode
                                                          ? Colors.white24
                                                          : AppColors
                                                              .primaryBlue,
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                            ),
                                          ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors:
                                                  _isLoading ||
                                                          !_hasEnoughBalance ||
                                                          _amountError !=
                                                              null ||
                                                          _phoneController
                                                                  .text
                                                                  .length !=
                                                              9
                                                      ? [
                                                        Colors.grey,
                                                        Colors.grey.shade400,
                                                      ]
                                                      : [
                                                        AppColors.primaryBlue,
                                                        AppColors.primaryBlue
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow:
                                                _isLoading ||
                                                        !_hasEnoughBalance ||
                                                        _amountError != null ||
                                                        _phoneController
                                                                .text
                                                                .length !=
                                                            9
                                                    ? null
                                                    : [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF3B82F6,
                                                        ).withValues(
                                                          alpha: 0.3,
                                                        ),
                                                        blurRadius: 10,
                                                        offset: const Offset(
                                                          0,
                                                          5,
                                                        ),
                                                      ),
                                                    ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading || !_hasEnoughBalance
                                                    ? null
                                                    : _processRecharge,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              fixedSize: const Size.fromHeight(
                                                50,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                            ),
                                            child:
                                                _isLoading
                                                    ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : Text(
                                                      'recharge_now'.tr(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,

                                                        shadows: [
                                                          Shadow(
                                                            color:
                                                                AppColors.adaptiveIcon(
                                                                  widget
                                                                      .isDarkMode,
                                                                ).withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  )
                                  .animate()
                                  .fade(duration: 400.ms, delay: 500.ms)
                                  .slideY(begin: 0.1, end: 0),
                            ],
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
                message: _loadingMessage,
              ),
          ],
        ),
      ),
    );
  }

  void _autoSelectProvider(String phone) {
    if (phone.length < 2) return;

    // Based on prefixes
    int? code;
    String? name;

    if (phone.startsWith('77') || phone.startsWith('78')) {
      code = 42103; // Yemen Mobile
      name = 'يمن موبايل';
    } else if (phone.startsWith('71')) {
      code = 42101; // Sabafon
      name = 'سبأفون';
    } else if (phone.startsWith('73')) {
      code = 42102; // YOU
      name = 'يو';
    } else if (phone.startsWith('70')) {
      code = 42104; // Y
      name = 'واي';
    }

    if (name != null) {
      _onProviderTap(name, code!, keepPhone: true);
    }
  }
}
