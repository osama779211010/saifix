import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../helper/counvert_amunt_helper.dart';

import '../../../core/app_colors.dart';
import '../../../services/alzajil_service.dart';
import '../../../services/api_service.dart';
import '../../../services/favorites_service.dart';
import '../../../components/security_verification_dialog.dart';
import '../../../components/transaction_details_bottom_sheet.dart';
import '../../../components/loading_overlay.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../account_confirmation_screen.dart';
import '../../../components/error_dialog.dart';
import '../../../widgets/receipt_dialog.dart';
import '../../../components/recharge/add_favorite_dialog.dart';
import '../../../services/sound_service.dart';
import '../../../components/favorites_bottom_sheet.dart';
import '../../../components/current_balance_card.dart';
import '../../../services/balance_service.dart';
import '../../../services/contact_service.dart';

class Yemen4GPackagesScreen extends StatefulWidget {
  final bool isDarkMode;
  final String title;

  const Yemen4GPackagesScreen({
    super.key,
    required this.isDarkMode,
    required this.title,
  });

  @override
  State<Yemen4GPackagesScreen> createState() => _Yemen4GPackagesScreenState();
}

class _Yemen4GPackagesScreenState extends State<Yemen4GPackagesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final AlzajilService _alzajilService = AlzajilService();

  bool _isLoading = false;
  String? _selectedPackageId;
  double _selectedPackagePrice = 0.0;
  String _selectedPackageName = '';
  String? _inquiryRef;
  bool _isFavorite = false;
  String? _phoneError;

  final List<Map<String, dynamic>> _packages = [
    {'id': '15', 'name': 'data_package_15'.tr(), 'price': 2400.0},
    {'id': '25', 'name': 'data_package_25'.tr(), 'price': 4000.0},
    {'id': '60', 'name': 'data_package_60'.tr(), 'price': 8000.0},
    {'id': '130', 'name': 'data_package_130'.tr(), 'price': 16000.0},
    {'id': '250', 'name': 'data_package_250'.tr(), 'price': 26000.0},
    {'id': '500', 'name': 'data_package_500'.tr(), 'price': 46000.0},
  ];

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
      ErrorDialog.show(
        context,
        message: 'please_enter_subscriber_number_first'.tr(),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _alzajilService.checkBalance(
        serviceCode: 42113,
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
          ErrorDialog.show(
            context,
            message: result['MSG'] ?? 'query_failed'.tr(),
          );
        }
      }
    } catch (e) {
      if (mounted) ErrorDialog.show(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBalanceDetails(Map<String, dynamic> result) {
    if (!mounted) return;
    Map<String, dynamic> data = result;
    if (result.containsKey('SD') && result['SD'] is String) {
      try {
        data = jsonDecode(result['SD']);
      } catch (e) {
        ErrorDialog.show(context, message: e.toString());
      }
    }

    String balance =
        (data['remain'] ??
                data['REMAIN'] ??
                result['BAL'] ??
                result['bal'] ??
                '0')
            .toString();
    String expiry =
        (data['ExpDate'] ??
                data['EXPDATE'] ??
                result['EXP'] ??
                result['exp'] ??
                'N/A')
            .toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = widget.isDarkMode;
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
                'account_details_title'.tr(),
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
              _buildBalanceRow(
                'remaining_balance_label'.tr(),
                balance,
                isBold: true,
              ),
              _buildBalanceRow('expiry_date_label'.tr(), expiry),
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
                    'close_button'.tr(),
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
              fontWeight: FontWeight.bold,
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackageId == null) {
      ErrorDialog.show(context, message: 'please_select_package'.tr());
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

    String recipientName = contactService.getContactName(_phoneController.text);

    if (mounted) {
      TransactionDetailsBottomSheet.show(
        context,
        isDarkMode: widget.isDarkMode,
        amount: _selectedPackagePrice.toString(),
        currency: 'YER',
        transactionType: 'yemen_4g_packages'.tr(),
        recipientName: recipientName,
        recipientId: _phoneController.text,
        details: [
          DetailItem(label: 'package_label'.tr(), value: _selectedPackageName),
        ],
        onExecute: () async {
          final auth = await SecurityVerificationDialog.show(
            context,
            isDarkMode: widget.isDarkMode,
          );
          if (auth) _executePayment();
        },
      );
    }
  }

  Future<void> _executePayment() async {
    setState(() => _isLoading = true);
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String fallbackRef = timestamp.substring(timestamp.length - 10);

    try {
      final result = await _alzajilService.sendPayment(
        actionCode: 7100,
        serviceCode: 42113,
        amount: _selectedPackagePrice,
        subscriberNo: _phoneController.text,
        subscriberType: 1,
        offerId: _selectedPackageId,
        ref: _inquiryRef ?? fallbackRef,
      );

      setState(() => _isLoading = false);

      if (result['RC'] == 0 || result['RC'] == '0') {
        SoundService.playSuccessSound();
        final String refNumber =
            (result['REF'] ?? result['ref'] ?? fallbackRef).toString();
        if (mounted) {
          await ReceiptDialog.show(
            context,
            isDarkMode: widget.isDarkMode,
            title: 'receipt_yemen_4g'.tr(),
            mainAmount: formatAmountDisplay(_selectedPackagePrice),
            mainCurrency: 'currency_riyal'.tr(),
            details: [
              ReceiptRowData(
                label: 'subscriber_number_label'.tr(),
                value: _phoneController.text,
              ),
              ReceiptRowData(
                label: 'package_label'.tr(),
                value: _selectedPackageName,
              ),
              ReceiptRowData(
                label: 'referenceNumber'.tr(),
                value: refNumber,
                isCopyable: true,
              ),
            ],
            shareText: '✅ إيصال تفعيل باقة 4G - صيفي باي\nالمرجع: $refNumber',
            onClose: () {
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
          );
        }
        _phoneController.clear();
        setState(() {
          _selectedPackageId = null;
          _selectedPackageName = '';
          _selectedPackagePrice = 0.0;
        });
      } else {
        if (mounted) {
          ErrorDialog.show(
            context,
            message: result['MSG'] ?? 'activation_failed'.tr(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(context, message: e.toString());
      }
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
        _checkIfFavorite(phone);
      },
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
                          _buildSectionTitle('subscriber_number'.tr()),
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
                          const SizedBox(height: 25),
                          _buildSectionTitle('packages_label'.tr()),
                          _buildPackagesGrid(),
                          const SizedBox(height: 35),
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
              message: 'processing_loading'.tr(),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _phoneError != null ? Colors.red : Colors.transparent,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: '10XXXXXXX',
          prefixIcon: Icon(
            Icons.phone_android_rounded,
            color: AppColors.primaryBlue,
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
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
              IconButton(
                onPressed: _pickContact,
                icon: Icon(
                  Icons.contacts_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'phone_required'.tr();
          }
          if (value.length != 9 || !value.startsWith('10')) {
            return 'y4g_must_be_9_digits'.tr();
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
            if (val.isEmpty) {
              _phoneError = null;
            } else if (val.length != 9 || !val.startsWith('10')) {
              _phoneError = 'y4g_must_be_9_digits'.tr();
            } else {
              _phoneError = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildPackagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        final isSelected = _selectedPackageId == pkg['id'];
        return GestureDetector(
          onTap:
              () => setState(() {
                _selectedPackageId = pkg['id'];
                _selectedPackageName = pkg['name'];
                _selectedPackagePrice = pkg['price'];
              }),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.05)
                      : (widget.isDarkMode ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pkg['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatAmountDisplay(pkg['price'].toDouble())} YER',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'confirm_payment_button'.tr(),
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
        label: Text(
          'check_balance_button'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
