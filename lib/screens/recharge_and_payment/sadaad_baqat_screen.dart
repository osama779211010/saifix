import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../../core/app_colors.dart';
import '../../services/alzajil_service.dart';
import '../../services/api_service.dart';
import '../../data/yemen_mobile_offers.dart';
import '../../data/you_offers.dart';
import '../../data/sabafon_offers.dart';
import '../../data/y_offers.dart';

import '../../components/loading_overlay.dart';
import '../../helper/counvert_amunt_helper.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../widgets/receipt_dialog.dart';
import '../../services/session_manager.dart';
import '../account_confirmation_screen.dart';
import '../../services/favorites_service.dart';
import '../../components/favorites_bottom_sheet.dart';
import '../../components/security_verification_dialog.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../services/sound_service.dart';
import '../../components/current_balance_card.dart';
import '../../services/balance_service.dart';
import '../../components/recharge/add_favorite_dialog.dart';
import '../../services/contact_service.dart';

class SadaadBaqatScreen extends StatefulWidget {
  final bool isDarkMode;
  const SadaadBaqatScreen({super.key, required this.isDarkMode});

  @override
  State<SadaadBaqatScreen> createState() => _SadaadBaqatScreenState();
}

class _SadaadBaqatScreenState extends State<SadaadBaqatScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _loadingMessage = 'package_activation_loading'.tr();
  String? _phoneError;
  bool _isFavorite = false;

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
        _autoSelectProvider(phone);
        _checkIfFavorite(phone);
      },
    );
  }

  String? _selectedProvider;
  int? _selectedServiceCode;
  String? _selectedOfferId; // SAC
  int _subscriberType = 0; // 0: Prepaid, 1: Billing

  // Loan tracking
  double _subscriberLoan = 0.0;
  bool _isCheckingLoan = false;

  final AlzajilService _alzajilService = AlzajilService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        balanceService.refreshBalance();
      }
    });
  }

  // Tab controller for categories
  late TabController _tabController;
  List<String> _categories = [
    'category_daily'.tr(),
    'category_weekly'.tr(),
    'category_monthly'.tr(),
    'category_other'.tr(),
  ];

  // Cache categories for providers to avoid re-creating lists
  final List<String> _ymCategories = [
    'category_daily'.tr(),
    'category_weekly'.tr(),
    'category_monthly'.tr(),
    'category_other'.tr(),
  ];
  final List<String> _youCategories = [
    'category_daily'.tr(),
    'category_weekly'.tr(),
    'category_monthly'.tr(),
    'category_other'.tr(),
  ];
  final List<String> _sabafonCategories = [
    'category_daily'.tr(),
    'category_weekly'.tr(),
    'category_monthly'.tr(),
    'category_other'.tr(),
  ];
  final List<String> _yCategories = [
    'category_weekly'.tr(),
    'category_monthly'.tr(),
    'category_other'.tr(),
  ]; // No Daily for Y
  // Offers based on selection
  List<dynamic> _offers = [];

  // Mapping based on PDF
  final List<Map<String, dynamic>> providers = [
    {
      'title': 'provider_ym_packages'.tr(),
      'logoLabel': 'YM',
      'color': const Color(0xFFB00049),
      'code': 42103, // YM Packages
      'prefixes': ['77', '78'],
      'imagePath': 'assets/images/networks/YemenMobile.png',
    },
    {
      'title': 'provider_sabafon_packages'.tr(),
      'logoLabel': 'S',
      'color': Colors.blue.shade700,
      'code': 42101, // Sabafon
      'prefixes': ['71'],
      'imagePath': 'assets/images/networks/sabafon.png',
    },
    {
      'title': 'provider_you_packages'.tr(),
      'logoLabel': 'You',
      'color': Colors.yellow.shade700,
      'code': 42102, // YOU
      'prefixes': ['73'],
      'imagePath': 'assets/images/networks/MTN.png',
    },
    {
      'title': 'provider_y_packages'.tr(),
      'logoLabel': 'Y',
      'color': Colors.purple,
      'code': 42104, // Y Packages
      'prefixes': ['70'],
      'imagePath': 'assets/images/networks/y.png',
    },
  ];

  Future<void> _fetchBalances({bool forceRefresh = false}) async {
    await balanceService.refreshBalance(forceRefresh: forceRefresh);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadStaticOffers();
  }

  Future<void> _fetchSubscriberLoan() async {
    if (_phoneController.text.length < 9 || _selectedServiceCode == null) {
      setState(() {
        _subscriberLoan = 0.0;
      });
      return;
    }

    setState(() => _isCheckingLoan = true);

    try {
      final result = await _alzajilService.checkBalance(
        serviceCode: _selectedServiceCode!,
        subscriberNo: _phoneController.text,
        actionCode: 4006, // Query balance and loan
      );

      if (mounted) {
        if (result['RC'] == 0 || result['rc'] == 0 || result['RC'] == "0") {
          // Robust parsing logic (Synchronized with ShahnAlraseedScreen)
          String loan =
              (result['LOAN'] ??
                      result['CREDIT'] ??
                      result['Loan'] ??
                      result['Credit'] ??
                      result['loan'] ??
                      result['credit'] ??
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
            } catch (e) {
              customPrint("Error decoding SD: $e");
            }
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

          int isPrepaid =
              (mtValue.toString() == "0" || mtValue.toString() == "1") ? 0 : 1;

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

          setState(() {
            _subscriberLoan = double.tryParse(loan) ?? 0.0;
            _subscriberType = isPrepaid;
            _isCheckingLoan = false;
          });

          if (_selectedServiceCode != 42103) {
            _fetchDynamicOffers();
          }
        } else {
          setState(() {
            _subscriberLoan = 0.0;
            _isCheckingLoan = false;
          });
        }
      }
    } catch (e) {
      customPrint("Error fetching loan: $e");
      if (mounted) {
        setState(() => _isCheckingLoan = false);
      }
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

        // Auto-select provider based on prefix
        _autoSelectProvider(phone);

        // Trigger balance/loan check
        _fetchSubscriberLoan();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('no_phone_in_contact'.tr())));
        }
      }
    }
  }

  Future<void> _fetchDynamicOffers() async {
    if (_selectedServiceCode == null || _phoneController.text.length < 9) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'fetching_offers_loading'.tr();
    });
    try {
      final result = await _alzajilService.getOffers(
        actionCode: 4001,
        serviceCode: _selectedServiceCode!,
        subscriberNo: _phoneController.text,
      );

      if (mounted) {
        setState(() {
          if (result['RC'] == 0 || result['rc'] == 0) {
            final rawOffers =
                result['SD'] ?? result['sd'] ?? result['OFFERS'] ?? [];
            if (rawOffers is List) {
              _offers = rawOffers;
            } else if (rawOffers is Map) {
              _offers = [rawOffers];
            } else {
              _offers = [];
            }
          } else {
            _offers = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      customPrint("Error fetching dynamic offers: $e");
      if (mounted) setState(() => _isLoading = false);
      sessionManager.isOperationInProgress = false;
    }
  }

  void _loadStaticOffers() {
    if (_selectedServiceCode == 42103) {
      setState(() {
        final category = _categories[_tabController.index];
        final allOffers = YemenMobileOffersData.getOffersByCategory(category);
        final currentType = _subscriberType == 0 ? 'دفع مسبق' : 'فوترة';

        _offers =
            allOffers
                .where((offer) {
                  final nameContainsType = offer.nameAr.contains(currentType);
                  return nameContainsType || offer.payType == currentType;
                })
                .map((offer) => offer.toJson())
                .toList();
        _selectedOfferId = null;
      });
    } else if (_selectedServiceCode == 42102) {
      setState(() {
        final category = _categories[_tabController.index];
        final allOffers = YouOffersData.getOffersByCategory(category);
        final currentType = _subscriberType == 0 ? 'دفع مسبق' : 'فوترة';

        _offers =
            allOffers
                .where((offer) {
                  return offer.payType == currentType;
                })
                .map((offer) => offer.toJson())
                .toList();
        _selectedOfferId = null;
      });
    } else if (_selectedServiceCode == 42101) {
      setState(() {
        final category = _categories[_tabController.index];
        final allOffers = SabafonOffersData.getOffersByCategory(category);
        final currentType = _subscriberType == 0 ? 'دفع مسبق' : 'فوترة';

        _offers =
            allOffers
                .where((offer) {
                  return offer.payType == currentType;
                })
                .map((offer) => offer.toJson())
                .toList();
        _selectedOfferId = null;
      });
    } else if (_selectedServiceCode == 42104) {
      setState(() {
        if (_tabController.index >= _categories.length) return;
        final category = _categories[_tabController.index];
        final allOffers = YOffersData.getOffersByCategory(category);

        if (_subscriberType == 0) {
          _offers = allOffers.map((offer) => offer.toJson()).toList();
        } else {
          _offers = [];
        }
        _selectedOfferId = null;
      });
    }
  }

  Future<void> _submitPackagePayment() async {
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

    if (_selectedOfferId == null) return;

    sessionManager.isOperationInProgress = true;
    if (!_formKey.currentState!.validate()) return;

    final selectedProvider = providers.firstWhere(
      (p) => p['code'] == _selectedServiceCode,
      orElse: () => {},
    );
    if (selectedProvider.isNotEmpty) {
      List<String>? allowedPrefixes = selectedProvider['prefixes'];
      String enteredPhone = _phoneController.text.trim();
      if (allowedPrefixes != null && allowedPrefixes.isNotEmpty) {
        bool hasValidPrefix = allowedPrefixes.any(
          (prefix) => enteredPhone.startsWith(prefix),
        );
        if (!hasValidPrefix) {
          _showDialog(
            'invalid_number_title'.tr(),
            'invalid_phone_prefix_message'.tr(
              args: [allowedPrefixes.join(' أو ')],
            ),
          );
          return;
        }
      }
    }

    try {
      final selectedOffer = _offers.firstWhere(
        (offer) =>
            (offer['offer_id'].toString() == _selectedOfferId ||
                offer['id'].toString() == _selectedOfferId ||
                offer['SAC'].toString() == _selectedOfferId),
        orElse: () => <String, dynamic>{},
      );

      if (selectedOffer.isEmpty) {
        _showDialog('error'.tr(), 'selected_package_not_found'.tr());
        return;
      }

      final packageName = selectedOffer['name_ar'] ?? 'package_label'.tr();
      final double amount = double.parse(selectedOffer['amt'].toString());

      double walletBalance =
          double.tryParse(balanceService.balances['YER'].toString()) ?? 0.0;
      if (walletBalance < amount) {
        _showDialog(
          'insufficient_balance'.tr(),
          'not_enough_wallet_balance'.tr(),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (_subscriberLoan == 0 && _phoneController.text.length >= 9) {
        await _fetchSubscriberLoan();
      }
      // Force loanAmount to 0 for Billing (Postpaid) as per requirement
      double loanAmount = (_subscriberType == 1) ? 0.0 : _subscriberLoan;

      final totalAmount = amount + loanAmount;

      if (walletBalance < totalAmount) {
        _showDialog(
          'insufficient_balance'.tr(),
          'not_enough_balance_with_loan'.tr(
            args: [amount.toString(), loanAmount.toString()],
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final providerInfo = providers.firstWhere(
        (p) => p['code'] == _selectedServiceCode,
        orElse: () => providers.first,
      );

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String rechargeRef = 'CHG_${timestamp.substring(timestamp.length - 8)}';
      String activateRef = 'PKG_${timestamp.substring(timestamp.length - 8)}';
      int apiSubscriberType = (_subscriberType == 0) ? 0 : 2;

      String recipientName = contactService.getContactName(
        _phoneController.text,
      );

      if (!mounted) return;
      TransactionDetailsBottomSheet.show(
        context,
        isDarkMode: widget.isDarkMode,
        amount: amount.toString(),
        totalAmount: totalAmount.toString(),
        currency: 'YER',
        transactionType: 'activate_package'.tr(),
        networkName: providerInfo['title'],
        recipientName: recipientName,
        recipientId: _phoneController.text,
        details: [
          DetailItem(label: 'package_label'.tr(), value: packageName),
          if (loanAmount > 0)
            DetailItem(
              label: 'loan_repayment_label'.tr(),
              value: '$loanAmount ${'currency_YER'.tr()}',
              color: Colors.orange,
              isBold: true,
            ),
        ],
        onExecute: () async {
          final authenticated = await SecurityVerificationDialog.show(
            context,
            isDarkMode: widget.isDarkMode,
            title: 'confirm_activate_package'.tr(),
            description: 'confirm_identity_description'.tr(),
          );

          if (authenticated) {
            _executePaymentLogic(
              activateRef: activateRef,
              rechargeRef: rechargeRef,
              totalAmount: totalAmount,
              apiSubscriberType: apiSubscriberType,
              packageName: packageName,
              amount: amount,
              loanAmount: loanAmount,
            );
          } else {
            setState(() => _isLoading = false);
            sessionManager.isOperationInProgress = false;
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      sessionManager.isOperationInProgress = false;
      _showDialog('error'.tr(), e.toString());
    }
  }

  Future<void> _executePaymentLogic({
    required String activateRef,
    required String rechargeRef,
    required double totalAmount,
    required int apiSubscriberType,
    required String packageName,
    required double amount,
    required double loanAmount,
  }) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'package_activation_loading'.tr();
    });

    try {
      Map<String, dynamic> result;

      if (_selectedServiceCode == 42102 ||
          _selectedServiceCode == 42101 ||
          _selectedServiceCode == 42104) {
        final activateResult = await _alzajilService.sendPayment(
          actionCode: 7200,
          serviceCode: _selectedServiceCode!,
          amount: totalAmount,
          subscriberNo: _phoneController.text,
          subscriberType: (_subscriberType == 0) ? 1 : 2,
          ref: activateRef,
          offerId: _selectedOfferId,
          remarks: 'GSM Package Activation',
        );
        result = activateResult;
      } else {
        // Fallback for other services
        final rechargeResult = await _alzajilService.sendPayment(
          actionCode: 7100,
          serviceCode: _selectedServiceCode!,
          amount: totalAmount,
          subscriberNo: _phoneController.text,
          subscriberType: apiSubscriberType,
          ref: rechargeRef,
          offerId: "0",
          remarks: 'Package Activation + Loan Clear',
        );

        if (rechargeResult['RC'] != 0) {
          _showDialog(
            'payment_failed_title'.tr(),
            rechargeResult['MSG'] ?? 'payment_failed_message'.tr(),
          );
          setState(() => _isLoading = false);
          return;
        }

        final activateResult = await _alzajilService.activatePackage(
          serviceCode: _selectedServiceCode.toString(),
          subscriberNo: _phoneController.text,
          offerId: _selectedOfferId!,
          amount: 0,
          ref: activateRef,
        );
        result = activateResult;
      }

      setState(() => _isLoading = false);

      if (result['RC'] == 0 || result['RC'] == '0') {
        if (mounted) {
          final String refNumber =
              (result['REF'] ?? result['ref'] ?? 'N/A').toString();
          SoundService.playSuccessSound();
          if (mounted) {
            await ReceiptDialog.show(
              context,
              isDarkMode: widget.isDarkMode,
              title: 'internet_package_activation_receipt'.tr(),
              mainAmount: formatAmountDisplay(totalAmount),
              mainCurrency: 'currency_YER'.tr(),
              details: [
                ReceiptRowData(
                  label: 'system_prefix'.tr(),
                  value: 'saifi_pay_system'.tr(),
                ),
                ReceiptRowData(label: 'package_label'.tr(), value: packageName),
                ReceiptRowData(
                  label: 'subscriber_number_label'.tr(),
                  value: _phoneController.text,
                ),
                ReceiptRowData(
                  label: 'package_price_label'.tr(),
                  value:
                      '${formatAmountDisplay(amount)} ${'currency_YER'.tr()}',
                ),
                if (loanAmount > 0)
                  ReceiptRowData(
                    label: 'loan_repayment_label'.tr(),
                    value:
                        '${formatAmountDisplay(loanAmount)} ${'currency_YER'.tr()}',
                  ),
                ReceiptRowData(
                  label: 'total_deducted_label'.tr(),
                  value:
                      '${formatAmountDisplay(totalAmount)} ${'currency_YER'.tr()}',
                ),
                ReceiptRowData(
                  label: 'referenceNumber'.tr(),
                  value: refNumber,
                  isCopyable: true,
                ),
              ],
              shareText: '✅ إيصال تفعيل باقة - صيفي باي\nالمرجع: $refNumber',
              onClose: () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
            );
          }
          _resetForm();
        }
        // Refresh in background
        _fetchBalances(forceRefresh: true);
      } else {
        _showDialog('error'.tr(), result['MSG'] ?? 'activation_failed'.tr());
      }
    } catch (e) {
      if (mounted) {
        _showDialog('error'.tr(), e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title, style: const TextStyle()),
            content: Text(content, style: const TextStyle()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'ok'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
            'mobile_packages_payment'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // Spacer for balance
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

  Widget _buildModernDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color:
                  color ?? (widget.isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _onProviderTap(String title, int code, {bool keepPhone = false}) {
    setState(() {
      _selectedProvider = title;
      _selectedServiceCode = code;
      _selectedOfferId = null;
      _offers = [];
      _subscriberLoan = 0.0;

      if (code == 42102) {
        _categories = _youCategories;
      } else if (code == 42101) {
        _categories = _sabafonCategories;
      } else if (code == 42104) {
        _categories = _yCategories;
      } else {
        _categories = _ymCategories;
      }

      if (_tabController.length != _categories.length) {
        _tabController.dispose();
        _tabController = TabController(length: _categories.length, vsync: this);
        _tabController.addListener(_onTabChanged);
      } else {
        _tabController.animateTo(0);
      }
    });

    if (!keepPhone) _phoneController.clear();

    if (code == 42103 || code == 42102 || code == 42101 || code == 42104) {
      Future.delayed(Duration.zero, () {
        if (mounted) _loadStaticOffers();
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _phoneController.clear();
    setState(() {
      _selectedOfferId = null;
      _offers = [];
      _subscriberLoan = 0.0;
    });
  }

  Widget _buildSelectedProviderBanner() {
    if (_selectedServiceCode == null) return const SizedBox.shrink();

    final provider = providers.firstWhere(
      (p) => p['code'] == _selectedServiceCode,
      orElse: () => providers.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: provider['color'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: provider['color'].withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              provider['imagePath'],
              height: 32,
              width: 32,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) =>
                      Icon(Icons.cell_wifi, size: 24, color: provider['color']),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 24),
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
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
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
                                    labelText: 'phone_label'.tr(),
                                    hintText: 'phone_hint'.tr(),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelStyle: TextStyle(
                                      color: AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor:
                                        widget.isDarkMode
                                            ? Colors.white.withValues(
                                              alpha: 0.05,
                                            )
                                            : Colors.white,
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
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            _isFavorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: AppColors.secondaryBlue,
                                            size: 20,
                                          ),
                                          onPressed:
                                              _phoneController.text.isEmpty
                                                  ? _showFavoritesDialog
                                                  : _toggleFavorite,
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            Icons.contacts_rounded,
                                            color: AppColors.primaryBlue,
                                            size: 20,
                                          ),
                                          onPressed: _pickContact,
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
                                        color: AppColors.adaptiveIcon(
                                          widget.isDarkMode,
                                        ).withValues(alpha: 0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: AppColors.adaptiveIcon(
                                          widget.isDarkMode,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'phone_required'.tr();
                                    }
                                    if (value.length < 9) {
                                      return 'phone_invalid'.tr();
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(9),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (val) {
                                    _checkIfFavorite(val);
                                    setState(() {
                                      if (val.length < 9 && val.isNotEmpty) {
                                        _phoneError = 'must_be_9_digits'.tr();
                                      } else {
                                        _phoneError = null;
                                      }
                                    });
                                    if (val.length >= 2) {
                                      String prefix = val.substring(0, 2);
                                      bool found = false;
                                      for (var provider in providers) {
                                        List<String> prefixes =
                                            provider['prefixes'];
                                        if (prefixes.contains(prefix)) {
                                          if (_selectedServiceCode !=
                                              provider['code']) {
                                            _onProviderTap(
                                              provider['title'],
                                              provider['code'],
                                              keepPhone: true,
                                            );
                                          }
                                          found = true;
                                          break;
                                        }
                                      }
                                      if (!found &&
                                          _selectedServiceCode != null) {
                                        setState(() {
                                          _selectedServiceCode = null;
                                          _selectedProvider = null;
                                          _offers = [];
                                        });
                                      }
                                    } else if (val.length < 9 &&
                                        _selectedServiceCode != null) {
                                      setState(() {
                                        _offers = [];
                                        _subscriberLoan = 0.0;
                                        _selectedOfferId = null;
                                      });
                                    }

                                    if (_selectedServiceCode == 42103 ||
                                        _selectedServiceCode == 42102 ||
                                        _selectedServiceCode == 42101 ||
                                        _selectedServiceCode == 42104) {
                                      _loadStaticOffers();
                                    }
                                    if (val.length == 9) {
                                      _fetchSubscriberLoan();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_phoneError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                right: 12,
                                bottom: 8,
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
                          const SizedBox(height: 25),
                          _buildSelectedProviderBanner(),
                          if (_selectedServiceCode != null) ...[
                            // _buildWalletBalanceCard()
                            //     .animate()
                            //     .fade(duration: 400.ms, delay: 200.ms)
                            //     .slideY(begin: 0.1, end: 0),
                            // const SizedBox(height: 25),
                            if (_isCheckingLoan)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                  ),
                                ),
                              )
                            else if (_phoneController.text.length >= 9 &&
                                _subscriberLoan > 0 &&
                                _subscriberType == 0) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: _buildModernDetailRow(
                                  'المبلغ المطلوب (سلفة)',
                                  '${formatAmountDisplay(_subscriberLoan)} ريال',
                                  Icons.history_edu,
                                  color: Colors.orange,
                                  isBold: true,
                                ),
                              ),
                              const SizedBox(height: 25),
                            ],
                            if (_selectedServiceCode == 42103 ||
                                _selectedServiceCode == 42102 ||
                                _selectedServiceCode == 42101 ||
                                _selectedServiceCode == 42104) ...[
                              _buildCategoryTabs(),
                              const SizedBox(height: 25),
                            ],
                            _buildOffersList(),
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
    );
  }

  // Widget _buildSubscriberTypeSelector() {
  //   return Container(
  //     padding: const EdgeInsets.all(6),
  //     decoration: BoxDecoration(
  //       color:
  //           widget.isDarkMode
  //               ? Colors.white.withValues(alpha: 0.05)
  //               : Colors.black.withValues(alpha: 0.05),
  //       borderRadius: BorderRadius.circular(18),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: _buildTypeButton(
  //             label: 'prepaid_label'.tr(),
  //             isSelected: _subscriberType == 0,
  //             onTap: () {
  //               setState(() => _subscriberType = 0);
  //               if (_selectedServiceCode != null) _loadStaticOffers();
  //             },
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: _buildTypeButton(
  //             label: 'postpaid_label'.tr(),
  //             isSelected: _subscriberType == 1,
  //             onTap: () {
  //               setState(() => _subscriberType = 1);
  //               if (_selectedServiceCode != null) _loadStaticOffers();
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTypeButton({
  //   required String label,
  //   required bool isSelected,
  //   required VoidCallback onTap,
  // }) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(12),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 10),
  //       decoration: BoxDecoration(
  //         color: isSelected ? AppColors.primaryBlue : Colors.transparent,
  //         borderRadius: BorderRadius.circular(12),
  //         boxShadow:
  //             isSelected
  //                 ? [
  //                   BoxShadow(
  //                     color: AppColors.primaryBlue.withValues(alpha: 0.3),
  //                     blurRadius: 8,
  //                     offset: const Offset(0, 3),
  //                   ),
  //                 ]
  //                 : null,
  //       ),
  //       child: Center(
  //         child: Text(
  //           label,
  //           style: TextStyle(
  //             color:
  //                 isSelected
  //                     ? Colors.white
  //                     : (widget.isDarkMode ? Colors.white60 : Colors.black54),
  //             fontWeight: FontWeight.bold,
  //             fontSize: 13,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child:
          _tabController.length != _categories.length
              ? const Center(child: CircularProgressIndicator())
              : TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor:
                    widget.isDarkMode ? Colors.white54 : Colors.black54,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.adaptiveIcon(widget.isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.adaptiveIcon(
                        widget.isDarkMode,
                      ).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                tabs:
                    _categories
                        .map(
                          (category) => Tab(
                            height: 35,
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
    );
  }

  Widget _buildOffersList() {
    if (_offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'no_offers_in_category'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        final offerId =
            (offer['offer_id'] ?? offer['id'] ?? offer['SAC'] ?? '').toString();
        final isSelected = _selectedOfferId == offerId;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedOfferId = offerId;
            });
            FocusScope.of(context).unfocus();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.1)
                      : (widget.isDarkMode ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? AppColors.primaryBlue
                        : (widget.isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: AppColors.adaptiveIcon(widget.isDarkMode),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer['name_ar'] ?? 'package_label'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${offer['amt']} ريال',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adaptiveIcon(widget.isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.adaptiveIcon(widget.isDarkMode),
                        size: 22,
                      ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            _isLoading
                                ? [Colors.grey, Colors.grey.shade400]
                                : [
                                  AppColors.adaptiveIcon(widget.isDarkMode),
                                  AppColors.adaptiveIcon(
                                    widget.isDarkMode,
                                  ).withValues(alpha: 0.8),
                                ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                          _isLoading
                              ? null
                              : [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || _phoneController.text.length != 9)
                              ? null
                              : _submitPackagePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'activate_package_button'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget _buildContactPickerButton() {
  //   return Container(
  //     height: 45,
  //     width: 45,
  //     decoration: BoxDecoration(
  //       color:
  //           widget.isDarkMode
  //               ? AppColors.cardDark
  //               : AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.05),
  //       borderRadius: BorderRadius.circular(15),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //       border: Border.all(
  //         color:
  //             widget.isDarkMode
  //                 ? Colors.white.withValues(alpha: 0.1)
  //                 : Colors.transparent,
  //       ),
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         onTap: _pickContact,
  //         borderRadius: BorderRadius.circular(15),
  //         child: Icon(
  //           Icons.contacts_rounded,
  //           color: widget.isDarkMode ? Colors.white : AppColors.primaryBlue,
  //           size: 24,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _autoSelectProvider(String phone) {
    if (phone.length < 2) return;

    // Find provider matching the prefix
    final provider = providers.firstWhere((p) {
      final prefixes = p['prefixes'] as List<String>;
      return prefixes.any((prefix) => phone.startsWith(prefix));
    }, orElse: () => {});

    if (provider.isNotEmpty && provider['title'] != _selectedProvider) {
      // Only change if different to avoid reloading offers unnecessarily
      _onProviderTap(provider['title'], provider['code'], keepPhone: true);
    }
  }
}
