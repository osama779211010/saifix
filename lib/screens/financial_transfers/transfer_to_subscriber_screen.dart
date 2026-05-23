import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/app_colors.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/api_service.dart';
import '../../components/loading_overlay.dart';
import '../../services/notification_service.dart';
import '../../components/qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/session_manager.dart';
import '../pay_purchases_screen.dart';
import '../../widgets/receipt_dialog.dart';
import '../account_confirmation_screen.dart';
import '../../services/contact_service.dart';
import '../../services/sound_service.dart';
import '../../services/favorites_service.dart';
import '../../components/favorites_bottom_sheet.dart';
import '../../components/recharge/add_favorite_dialog.dart';
import '../../components/error_dialog.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/security_confirmation_dialog.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../components/current_balance_card.dart';
import '../../services/balance_service.dart';
import '../../helper/arabic_numbers_helper.dart';

class TransferToSubscriberScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? initialPhone;
  const TransferToSubscriberScreen({
    super.key,
    required this.isDarkMode,
    this.initialPhone,
  });

  @override
  State<TransferToSubscriberScreen> createState() =>
      _TransferToSubscriberScreenState();
}

class _TransferToSubscriberScreenState
    extends State<TransferToSubscriberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _currency = 'YER';
  bool _isLoading = false;
  Map<String, dynamic>? _recipient;
  final bool _isSearching = false;
  bool _isSearchingById = false;
  String? _searchError;
  Timer? _searchTimer;
  bool _hasEnoughBalance = true;
  String _formattedAmount = '';
  String? _amountError;
  List<Map<String, dynamic>> _filteredSubscribers = [];
  Map<String, dynamic>? _currentUser;

  bool _isFavorite = false;
  List<Map<String, dynamic>> _recentSubscribers = [];

  @override
  void initState() {
    super.initState();
    _fetchBalances();
    _loadRecentSubscribers();
    _fetchUserData();
    balanceService.addListener(_onBalanceServiceChanged);
    if (widget.initialPhone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setPhoneAndLookup(widget.initialPhone!);
      });
    }
    // _initVoiceCommands();
  }

  void _onBalanceServiceChanged() {
    if (mounted) {
      setState(() {
        _currency = balanceService.selectedCurrency;
      });
      // Also re-validate amount if it was entered
      if (_amountController.text.isNotEmpty) {
        _onAmountChanged(_amountController.text);
      }
    }
  }

  @override
  void dispose() {
    balanceService.removeListener(_onBalanceServiceChanged);
    _searchTimer?.cancel();
    // voiceCommandService.latestCommand.removeListener(_handleVoiceCommand);
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setPhoneAndLookup(String raw) {
    String phone = raw.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('967')) phone = phone.substring(3);
    if (phone.length > 9) phone = phone.substring(phone.length - 9);
    _phoneController.text = phone;
    _onPhoneChanged(phone);
  }

  Future<void> _fetchBalances() async {
    await balanceService.refreshBalance();
  }

  Future<void> _loadRecentSubscribers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('recent_subscribers');
      if (data != null && mounted) {
        setState(() {
          _recentSubscribers = List<Map<String, dynamic>>.from(
            jsonDecode(data),
          );
        });
      }
    } catch (e) {
      customPrint('Error loading recent subscribers: $e');
    }
  }

  Future<void> _saveToRecent(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newUser = {
        'username': user['username'],
        'full_name':
            user['full_name'] ?? user['first_name'] ?? user['username'],
        'wallet_id': user['wallet_id'],
        'last_used': DateTime.now().toIso8601String(),
      };

      // Remove existing to avoid duplicates and move to top
      _recentSubscribers.removeWhere(
        (item) => item['username'] == newUser['username'],
      );
      _recentSubscribers.insert(0, newUser);

      // Keep only 10
      if (_recentSubscribers.length > 10) {
        _recentSubscribers = _recentSubscribers.sublist(0, 10);
      }

      await prefs.setString(
        'recent_subscribers',
        jsonEncode(_recentSubscribers),
      );
      if (mounted) setState(() {});
    } catch (e) {
      customPrint('Error saving recent subscriber: $e');
    }
  }

  void _onPhoneChanged(String val, {bool isSelection = false}) {
    final cleanVal = val.replaceAll(RegExp(r'\D'), '');

    setState(() {
      _recipient = null;
      _searchError = null;

      if (cleanVal.isNotEmpty && cleanVal.length < 7) {
        _searchError = 'رقم الموبايل او الرقم البديل غير صحيح';
      }

      if (val.isEmpty || isSelection) {
        _filteredSubscribers = [];
      } else {
        _filteredSubscribers =
            _recentSubscribers.where((sub) {
              final phone = sub['username']?.toString() ?? '';
              final name = sub['full_name']?.toString() ?? '';
              return phone.contains(val) ||
                  name.toLowerCase().contains(val.toLowerCase());
            }).toList();
      }
    });

    _searchTimer?.cancel();
    _checkIfFavorite(cleanVal);
  }

  Future<void> _performManualSearch() async {
    final cleanVal = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (cleanVal.length < 7) {
      setState(() => _searchError = 'invalid_phone_or_id'.tr());
      return;
    }

    // التحقق من التحويل للنفس قبل الاستعلام من الباك اند
    if (_currentUser != null) {
      final myPhone =
          (_currentUser!['username'] ?? _currentUser!['phone_number'] ?? "")
              .toString();
      final myWalletId = (_currentUser!['wallet_id'] ?? "").toString();

      if ((myPhone.isNotEmpty && myPhone == cleanVal) ||
          (myWalletId.isNotEmpty && myWalletId == cleanVal)) {
        if (mounted) {
          ErrorDialog.show(
            context,
            message: 'لا يمكنك التحويل إلى حسابك الشخصي',
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _searchError = null;
      _recipient = null;
    });

    try {
      // 1. Check for POS first
      final posPoint = await ApiService.getPOSPoint(cleanVal);
      if (posPoint != null && mounted) {
        setState(() => _isLoading = false);
        _showPOSRedirect(cleanVal, posPoint['trade_name']);
        return;
      }

      // 2. Search for User
      final user = await ApiService.searchUserByPhone(cleanVal);
      if (mounted) {
        setState(() {
          _recipient = user;
          _isSearchingById = cleanVal.length != 9;
          if (user == null) {
            _searchError = 'المستخدم غير موجود';
            if (mounted) {
              ErrorDialog.show(context, message: 'المستخدم غير موجود');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: 'حدث خطأ أثناء البحث');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfFavorite(String id) async {
    if (id.isEmpty) {
      if (mounted) setState(() => _isFavorite = false);
      return;
    }
    final fav = await favoritesService.isFavorite(id, FavoriteType.subscriber);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_phoneController.text.isEmpty) return;

    if (_isFavorite) {
      await favoritesService.removeFavorite(
        _phoneController.text,
        FavoriteType.wallet,
      );
      _checkIfFavorite(_phoneController.text);
    } else {
      AddFavoriteDialog.show(
        context,
        isDarkMode: widget.isDarkMode,
        initialType: FavoriteType.wallet,
        initialId: _phoneController.text,
        initialAmount: _amountController.text,
        onAdded: () {
          _checkIfFavorite(_phoneController.text);
        },
      );
    }
  }

  void _showFavorites() {
    FavoritesBottomSheet.show(
      context,
      type: FavoriteType.wallet,
      isDarkMode: widget.isDarkMode,
      onSelected: (phone, name, amount) {
        _setPhoneAndLookup(phone);
        if (amount != null && amount.isNotEmpty) {
          _amountController.text = amount;
          _onAmountChanged(amount);
        }
      },
    );
  }

  // Helper to keep code clean
  void _showPOSRedirect(String cleanVal, String tradeName) async {
    if (!mounted) return;
    bool? confirm = await showDialog<bool>(
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
                color: isDark
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
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dialog Title
                Text(
                  'pos_pay_title'.tr(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'pos_redirect_prefix'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tradeName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        height: 1,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'pos_redirect_question'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade800,
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
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
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
                              color: AppColors.primaryBlue.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
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
                            'yes_redirect'.tr(),
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

    if (confirm == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PayPurchasesScreen(
                isDarkMode: widget.isDarkMode,
                initialPOSNumber: cleanVal,
              ),
        ),
      );
    }
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) {
      setState(() {
        _formattedAmount = '';
        _hasEnoughBalance = true;
        _amountError = null;
      });
      return;
    }
    double? amount = double.tryParse(val);
    if (amount != null) {
      double balance =
          double.tryParse(
            balanceService.balances[balanceService.selectedCurrency] ?? '0.0',
          ) ??
          0.0;

      // Better formatting for very large numbers

      setState(() {
        _hasEnoughBalance = balance >= amount;
        _formattedAmount = formatAmountDisplay(amount);
        if (amount == 0) {
          _amountError = 'ادخل المبلغ بالشكل الصحيح';
        } else {
          _amountError = null;
        }
      });
    }
  }

  Future<void> _handleTransfer() async {
    if (_recipient == null) {
      await _performManualSearch();
      if (_recipient == null) return;
    }

    // التحقق من التحويل للنفس
    final currentUser = await ApiService.getCachedUser();
    if (!mounted) return;
    if (currentUser != null) {
      final myPhone =
          (currentUser['username'] ?? currentUser['phone_number'] ?? "")
              .toString();
      final myWalletId = (currentUser['wallet_id'] ?? "").toString();
      final recipientPhone =
          (_recipient!['username'] ?? _recipient!['phone_number'] ?? "")
              .toString();
      final recipientWalletId = (_recipient!['wallet_id'] ?? "").toString();

      if ((myPhone.isNotEmpty && myPhone == recipientPhone) ||
          (myWalletId.isNotEmpty && myWalletId == recipientWalletId)) {
        if (mounted) {
          ErrorDialog.show(
            context,
            message: 'لا يمكنك التحويل إلى حسابك الشخصي',
          );
        }
        return;
      }
    }

    if (_amountError != null ||
        _amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == 0) {
      if (mounted) {
        ErrorDialog.show(context, message: 'ادخل المبلغ بالشكل الصحيح');
      }
      return;
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
    FocusScope.of(context).unfocus();
    sessionManager.isOperationInProgress = true;

    TransactionDetailsBottomSheet.show(
      context,
      isDarkMode: widget.isDarkMode,
      amount: formatAmountDisplay(double.tryParse(_amountController.text) ?? 0),
      currency: _currency,
      transactionType: 'تحويل إلى مشترك',
      recipientName:
          _isSearchingById
              ? (_recipient!['first_name'] ?? 'مستخدم')
              : (_recipient!['full_name'] ?? _recipient!['username']),
      recipientId:
          _isSearchingById
              ? _recipient!['wallet_id'].toString()
              : _phoneController.text,
      onExecute: () async {
        final result = await SecurityConfirmationDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
        );

        if (result != null) {
          _executeTransfer(result is String ? result : null);
        }
      },
    );
  }

  Future<void> _executeTransfer(String? password) async {
    setState(() => _isLoading = true);
    sessionManager.isOperationInProgress = true;

    try {
      double amount = double.parse(_amountController.text);
      final transactionData = await ApiService.transferP2P(
        _phoneController.text,
        _currency,
        amount,
        description:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        password: password,
      );
      final refNumber = transactionData['reference_number'] ?? 'N/A';
      await balanceService.refreshBalance();
      final double currentBalance =
          double.tryParse(balanceService.currentBalance) ?? 0.0;
      final currency = balanceService.selectedCurrency;

      await NotificationService.showNotification(
        id: 1,
        title: 'تم التحويل بنجاح',
        body:
            'تم تحويل $amount $currency إلى ${_recipient!['full_name'] ?? _recipient!['username']}\nالمتبقي : $currentBalance $currency',
      );

      if (mounted) {
        if (_recipient != null) {
          await _saveToRecent(_recipient!);
        }
        setState(() => _isLoading = false);
        await _showSuccessDialog(currentBalance, refNumber, amount);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      sessionManager.isOperationInProgress = false;
    }
  }

  Future<void> _fetchUserData() async {
    final user = await ApiService.getCachedUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _showSuccessDialog(
    double currentBalance,
    String refNumber,
    double amount,
  ) async {
    SoundService.playSuccessSound();
    final receiverName =
        _isSearchingById
            ? (_recipient!['first_name'] ?? 'مستخدم')
            : (_recipient!['full_name'] ?? _recipient!['username']);
    final receiverId =
        _isSearchingById
            ? _recipient!['wallet_id'].toString()
            : _phoneController.text;

    final senderName =
        _currentUser != null
            ? (_currentUser!['full_name'] ??
                "${_currentUser!['first_name'] ?? ''} ${_currentUser!['last_name'] ?? ''}"
                    .trim())
            : 'مستخدم صيفي';
    final senderPhone =
        _currentUser != null
            ? (_currentUser!['username'] ?? _currentUser!['phone_number'] ?? '')
            : '';

    await ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'ايصال تحويل لمشترك',
      mainAmount: formatAmountDisplay(amount),
      mainCurrency: balanceService.selectedCurrency,
      details: [
        ReceiptRowData(label: 'المستفيد', value: '$receiverName\n$receiverId'),
        ReceiptRowData(label: 'المودع', value: '$senderName\n$senderPhone'),
        ReceiptRowData(label: 'رقم المرجع', value: refNumber, isCopyable: true),
        ReceiptRowData(
          label: 'تاريخ العملية',
          value: intl.DateFormat(
            'yyyy-MM-dd (hh:mm a)',
            'en_US',
          ).format(DateTime.now()),
        ),
      ],
      shareText:
          '✅ إيصال تحويل لمشترك - نظام صيفي باي\n\n'
          'المبلغ: ${formatAmountDisplay(amount)} $_currency\n'
          'المستلم: $receiverName\n'
          'الرقم المرجع: $refNumber\n',
      amountColor: Colors.red,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Stack(
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
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CurrentBalanceCard(isDarkMode: widget.isDarkMode),
                          const SizedBox(height: 15),
                          _buildPremiumInputField(
                            label: 'phoneOrId'.tr(),
                            controller: _phoneController,
                            icon: Icons.phone_android,
                            onChanged: _onPhoneChanged,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              ArabicToEnglishNumbersFormatter(),
                            ],
                            hasError:
                                _phoneController.text.isNotEmpty &&
                                ((_phoneController.text
                                                .replaceAll(RegExp(r'\D'), '')
                                                .length ==
                                            9 &&
                                        !['77', '70', '71', '73', '78'].any(
                                          (p) => _phoneController.text
                                              .startsWith(p),
                                        )) ||
                                    (_searchError != null)),
                            suffix: Row(
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
                                            : AppColors.adaptiveIcon(
                                              widget.isDarkMode,
                                            ),
                                  ),
                                  onPressed:
                                      _phoneController.text.isEmpty
                                          ? _showFavorites
                                          : _toggleFavorite,
                                  tooltip: 'add_to_favorites'.tr(),
                                ),
                                // IconButton(
                                //   icon: Icon(
                                //     Icons.star_rounded,
                                //     color: AppColors.adaptiveIcon(
                                //       widget.isDarkMode,
                                //     ),
                                //   ),
                                //   onPressed: _showFavorites,
                                //   tooltip: 'view_favorites'.tr(),
                                // ),
                                IconButton(
                                  icon: Icon(
                                    Icons.contacts_rounded,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                  ),
                                  onPressed: _pickContact,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                  ),
                                  onPressed: _scanQr,
                                ),
                              ],
                            ),
                          ),

                          if (_filteredSubscribers.isNotEmpty &&
                              _recipient == null)
                            _buildFilteredSuggestions(),

                          if (_isSearching)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.adaptiveIcon(widget.isDarkMode),
                                ),
                              ),
                            ),
                          if (_searchError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, right: 10),
                              child: Text(
                                _searchError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          //const SizedBox(height: 15),

                          // _buildSectionTitle('amount_details_section'.tr()),
                          const SizedBox(height: 20),

                          _buildPremiumInputField(
                            label: 'amount_label'.tr(),
                            controller: _amountController,
                            hint: 'amount_hint'.tr(),
                            icon: Icons.monetization_on,
                            onChanged: _onAmountChanged,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                RegExp(r'^[0.]'),
                              ),
                              ArabicToEnglishNumbersFormatter(),
                            ],
                          ),

                          if (_formattedAmount.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 5, right: 10),
                              child: Text(
                                '${formatAmountToArabicWords(double.tryParse(_amountController.text) ?? 0.0)} ${balanceService.selectedCurrency == 'YER' ? 'ريال يمني' : (balanceService.selectedCurrency == 'USD' ? 'دولار' : 'ريال سعودي')}',
                                style: TextStyle(
                                  color: AppColors.adaptiveText(
                                    widget.isDarkMode,
                                  ).withValues(alpha: 0.7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          if (!_hasEnoughBalance)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, right: 10),
                              child: Text(
                                'insufficient_balance_warning'.tr(),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          if (_amountError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, right: 10),
                              child: Text(
                                _amountError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 15),

                          _buildPremiumInputField(
                            label: 'notes_label'.tr(),
                            controller: _notesController,
                            hint: 'notes_hint'.tr(),
                            icon: Icons.note_alt,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 40),

                          _buildSubmitButton(),

                          const SizedBox(height: 30),
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
                message: 'loading_transfer_message'.tr(),
              ),
            // Voice Assistant Button
            // Positioned(
            //   bottom: 100,
            //   right: 20,
            //   child: VoiceAssistantButton(isDarkMode: widget.isDarkMode),
            // ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'transfer_to_subscriber'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // To balance the back button
        ],
      ),
    );
  }

  Widget _buildPremiumInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    Widget? suffix,
    bool hasError = false,
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
              color: (widget.isDarkMode ? Colors.white70 : AppColors.textBlack),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border:
                hasError
                    ? Border.all(color: Colors.redAccent, width: 1.5)
                    : null,
            boxShadow: [
              BoxShadow(
                color:
                    hasError
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : Colors.black.withValues(
                          alpha: widget.isDarkMode ? 0.3 : 0.05,
                        ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint ?? 'أدخل $label هنا...',
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color:
                    hasError
                        ? Colors.redAccent
                        : AppColors.adaptiveIcon(widget.isDarkMode),
                size: 20,
              ),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      constraints: const BoxConstraints(maxHeight: 135),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _filteredSubscribers.length,
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
        itemBuilder: (context, index) {
          final sub = _filteredSubscribers[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                (sub['full_name'] ?? 'U')[0],
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.adaptiveText(widget.isDarkMode),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              sub['full_name'] ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              sub['username'] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            onTap: () {
              setState(() {
                _phoneController.text = sub['username'] ?? '';
                _filteredSubscribers = [];
              });
              _onPhoneChanged(sub['username'] ?? '', isSelection: true);
            },
          );
        },
      ),
    );
  }

  // Widget _buildSectionTitle(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 15, right: 10),
  //     child: Text(
  //       title,
  //       style: TextStyle(
  //         color: widget.isDarkMode ? Colors.white70 : Colors.black54,

  //         fontSize: 14,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSubmitButton() {
    bool canSubmit =
        _phoneController.text.length >= 7 &&
        _amountController.text.isNotEmpty &&
        _hasEnoughBalance &&
        !_isLoading;

    return Container(
      width: double.infinity,
      height: 50,
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
        onPressed: canSubmit ? _handleTransfer : null,
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
                  'continue_to_otp'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      // Refresh cache since we now have permission
      contactService.preLoadContacts(force: true);
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      // Ensure we have properties (phones)
      var full = contact;
      if (contact.phones.isEmpty) {
        final fetched = await FlutterContacts.getContact(
          contact.id,
          withProperties: true,
        );
        if (fetched != null) full = fetched;
      }

      if (full.phones.isNotEmpty) {
        _setPhoneAndLookup(full.phones.first.number);
      } else {
        if (mounted) {
          ErrorDialog.show(context, message: 'contact_no_phone'.tr());
        }
      }
    }
  }

  Future<void> _scanQr() async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => QRScannerScreen(isDarkMode: widget.isDarkMode),
        ),
      );
      if (result != null && result.isNotEmpty) {
        _setPhoneAndLookup(result);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: 'تعذر فتح الماسح: $e');
      }
    }
  }
}
