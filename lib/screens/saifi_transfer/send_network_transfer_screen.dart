import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import '../../components/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/sound_service.dart';
import '../../services/api_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/security_confirmation_dialog.dart';
import '../../services/notification_service.dart';
import '../../services/session_manager.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/services.dart';
import '../account_confirmation_screen.dart';
import '../../services/favorites_service.dart';
import '../../components/favorites_bottom_sheet.dart';
import '../../widgets/receipt_dialog.dart';
import '../../components/recharge/add_favorite_dialog.dart';
import '../../services/contact_service.dart';

import '../../helper/custom_print_helper.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../components/current_balance_card.dart';
import '../../services/balance_service.dart';
import '../../helper/arabic_numbers_helper.dart';

class SendNetworkTransferScreen extends StatefulWidget {
  final bool isDarkMode;
  final String networkName;
  final String networkLogo;
  final String? initialPhone;
  final String? initialRecipientName;

  const SendNetworkTransferScreen({
    super.key,
    required this.isDarkMode,
    required this.networkName,
    required this.networkLogo,
    this.initialPhone,
    this.initialRecipientName,
  });

  @override
  State<SendNetworkTransferScreen> createState() =>
      _SendNetworkTransferScreenState();
}

class _SendNetworkTransferScreenState extends State<SendNetworkTransferScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _senderAddressController = TextEditingController();
  String _amountInWords = '';
  String _selectedCurrency = 'YER';
  String _selectedPurpose = 'purpose_family_expenses';
  bool _isLoading = false;
  bool _hasEnoughBalance = true;
  String _formattedAmount = '';
  double _fee = 0.0;
  double _totalWithFee = 0.0;
  bool _isFeeDeductedFromAmount = false;
  Map<String, dynamic>? _currentUser;
  bool _isFavorite = false;

  Future<void> _checkIfFavorite(String id) async {
    if (id.isEmpty) {
      if (mounted) setState(() => _isFavorite = false);
      return;
    }
    final fav = await favoritesService.isFavorite(id, FavoriteType.remittance);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_phoneController.text.isEmpty) return;

    if (_isFavorite) {
      await favoritesService.removeFavorite(
        _phoneController.text,
        FavoriteType.remittance,
      );
      _checkIfFavorite(_phoneController.text);
    } else {
      AddFavoriteDialog.show(
        context,
        isDarkMode: widget.isDarkMode,
        initialType: FavoriteType.remittance,
        onAdded: () {
          _checkIfFavorite(_phoneController.text);
        },
      );
    }
  }

  void _showFavoritesDialog() {
    FavoritesBottomSheet.show(
      context,
      type: FavoriteType.remittance,
      isDarkMode: widget.isDarkMode,
      onSelected: (phone, name, amount) {
        _phoneController.text = phone;
        _nameController.text = name;
        _amountController.text = amount ?? '0.00';
        _onAmountChanged(amount ?? '0.00');
        _checkIfFavorite(phone);
      },
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
        String phone = full.phones.first.number;
        phone = phone.replaceAll(RegExp(r'\D'), '');
        if (phone.startsWith('967')) phone = phone.substring(3);
        if (phone.length > 9) phone = phone.substring(phone.length - 9);

        setState(() {
          _phoneController.text = phone;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = full.displayName;
          }
        });
        _checkIfFavorite(phone);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('contact_no_phone'.tr())));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCurrency = balanceService.selectedCurrency;
    balanceService.addListener(_onBalanceServiceChanged);
    _fetchBalances();
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
      _checkIfFavorite(widget.initialPhone!);
    }
    if (widget.initialRecipientName != null) {
      _nameController.text = widget.initialRecipientName!;
    }
  }

  void _onBalanceServiceChanged() {
    if (mounted) {
      setState(() {
        _selectedCurrency = balanceService.selectedCurrency;
      });
      // Recalculate fees and limits if amount is not empty
      if (_amountController.text.isNotEmpty) {
        _onAmountChanged(_amountController.text);
      }
    }
  }

  @override
  void dispose() {
    balanceService.removeListener(_onBalanceServiceChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalances() async {
    await balanceService.refreshBalance();
    final user = await ApiService.getMe();
    if (mounted) {
      setState(() {
        _currentUser = user;
        if (user['full_name'] != null) {
          _senderNameController.text = user['full_name'];
        }
        if (user['phone_number'] != null) {
          _senderPhoneController.text = user['phone_number'];
        }
        if (user['address'] != null) {
          _senderAddressController.text = user['address'];
        } else if (user['location'] != null) {
          _senderAddressController.text = user['location'];
        } else {
          _senderAddressController.text = 'اليمن';
        }
      });
    }
  }

  bool _validateName(String name) {
    if (name.trim().isEmpty) return false;
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(name)) return false;
    final words = name.trim().split(RegExp(r'\s+'));
    return words.length >= 4;
  }

  bool _isAmountValid = true;
  String _amountLimitError = '';

  void _onAmountChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _amountInWords = '';
        _hasEnoughBalance = true;
        _isAmountValid = true;
        _amountLimitError = '';
        _formattedAmount = '';
        _fee = 0.0;
        _totalWithFee = 0.0;
      });
      return;
    }
    double? amount = double.tryParse(value);
    if (amount != null) {
      double balance =
          double.tryParse(
            balanceService.balances[balanceService.selectedCurrency] ?? '0.0',
          ) ??
          0.0;

      bool isValid = true;
      String limitError = '';

      if (balanceService.selectedCurrency == 'YER') {
        if (amount < 1000) {
          isValid = false;
          limitError = 'min_amount_yer'.tr();
        } else if (amount > 2000000) {
          isValid = false;
          limitError = 'max_amount_yer'.tr();
        }
      }

      setState(() {
        _amountInWords = formatAmountToArabicWords(amount);
        _hasEnoughBalance = balance >= amount;
        _isAmountValid = isValid;
        _amountLimitError = limitError;
        _formattedAmount = formatAmountDisplay(amount);
      });
      _calculateFees(amount);
    } else {
      setState(() {
        _amountInWords = 'invalid_amount'.tr();
        _hasEnoughBalance = true;
        _isAmountValid = false;
        _amountLimitError = 'invalid_amount_error'.tr();
      });
    }
  }

  Future<void> _calculateFees(double amount) async {
    try {
      final result = await ApiService.calculateFee(
        amount,
        balanceService.selectedCurrency,
      );
      if (mounted) {
        setState(() {
          _fee = double.tryParse(result['fee'].toString()) ?? 0.0;

          if (_isFeeDeductedFromAmount) {
            _totalWithFee = amount;
            if (_selectedCurrency == 'YER' && (amount - _fee) < 1000) {
              _isAmountValid = false;
              _amountLimitError = 'net_amount_min_error'.tr();
            }
          } else {
            _totalWithFee = double.tryParse(result['total'].toString()) ?? 0.0;
          }

          double balance =
              double.tryParse(
                balanceService.balances[balanceService.selectedCurrency] ??
                    '0.0',
              ) ??
              0.0;
          _hasEnoughBalance = balance >= _totalWithFee;
        });
      }
    } catch (e) {
      customPrint('Error calculating fees: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors();

    return Scaffold(
      backgroundColor: colors.scaffoldColor,
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
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildNetworkInfo(),
                          const SizedBox(height: 10),
                          CurrentBalanceCard(isDarkMode: widget.isDarkMode),
                          const SizedBox(height: 25),
                          _build3DInputCard(),
                          const SizedBox(height: 30),
                          _buildSubmitButton(),
                          const SizedBox(height: 20),
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
                message: 'sending_transfer'.tr(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.adaptiveIcon(
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            '${'send_a_money_transfer'.tr()} ${widget.networkName}',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
    );
  }

  Widget _buildNetworkInfo() {
    return Hero(
      tag: 'logo_${widget.networkName}',
      child: Container(
        width: 80,
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _buildLogoWidget(),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildLogoWidget() {
    final String logo = widget.networkLogo;
    if (logo.isEmpty) return _buildDefaultLogoIcon();

    if (logo.startsWith('http')) {
      return Image.network(
        logo,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildDefaultLogoIcon(),
      );
    } else if (logo.startsWith('/') || logo.startsWith('media/')) {
      String cleanBase = ApiService.baseUrl;
      if (cleanBase.endsWith('/')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 1);
      }
      final String fullUrl =
          logo.startsWith('/') ? '$cleanBase$logo' : '$cleanBase/$logo';
      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildDefaultLogoIcon(),
      );
    } else if (logo.startsWith('assets/') || logo.contains('.png')) {
      final String path =
          logo.startsWith('assets/') ? logo : 'assets/images/$logo';
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildDefaultLogoIcon(),
      );
    }
    return _buildDefaultLogoIcon();
  }

  Widget _buildDefaultLogoIcon() {
    return Icon(
      Icons.business_rounded,
      color: AppColors.adaptiveIcon(widget.isDarkMode),
      size: 40,
    );
  }

  Widget _build3DInputCard() {
    return Transform(
      transform:
          Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(0.02),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.adaptiveIcon(
                      widget.isDarkMode,
                    ).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.isDarkMode ? 0.3 : 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSectionTitle('recipient_section_title'.tr()),
            const SizedBox(height: 10),
            _buildPremiumTextField(
              controller: _nameController,
              label: 'recipient_name_label'.tr(),
              hint: 'recipient_name_hint'.tr(),
              bottomHint:
                  _nameController.text.isNotEmpty &&
                          !RegExp(
                            r'^[\u0600-\u06FF\s]+$',
                          ).hasMatch(_nameController.text)
                      ? 'يجب إدخال الاسم باللغة العربية فقط (بدون رموز أو أرقام)'
                      : 'name_quadruple_hint'.tr(),
              icon: Icons.person_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\u0600-\u06FF\s]')),
              ],
              onChanged: (val) => setState(() {}),
              hasError:
                  _nameController.text.isNotEmpty &&
                  !_validateName(_nameController.text),
            ),
            const SizedBox(height: 12),
            _buildPremiumTextField(
              controller: _phoneController,
              label: 'recipient_phone_label'.tr(),
              hint: 'recipient_phone_hint'.tr(),
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [ArabicToEnglishNumbersFormatter()],
              onChanged: (val) {
                _checkIfFavorite(val);
                setState(() {});
              },
              hasError:
                  _phoneController.text.isNotEmpty &&
                  _phoneController.text.length != 9,
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
                      color: AppColors.adaptiveIcon(widget.isDarkMode),
                      size: 20,
                    ),
                    onPressed: _pickContact,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            if (_phoneController.text.isNotEmpty &&
                _phoneController.text.length != 9)
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'phone_length_error'.tr(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            _buildPremiumTextField(
              controller: _amountController,
              label: 'amount_label'.tr(),
              hint: 'amount_hint'.tr(),
              icon: Icons.monetization_on_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                ArabicToEnglishNumbersFormatter(),
                FilteringTextInputFormatter.deny(RegExp(r'^0')),
              ],
              onChanged: _onAmountChanged,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _isFeeDeductedFromAmount
                        ? Colors.orangeAccent.withValues(alpha: 0.1)
                        : (widget.isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.02)),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color:
                      _isFeeDeductedFromAmount
                          ? Colors.orangeAccent.withValues(alpha: 0.3)
                          : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isFeeDeductedFromAmount
                        ? Icons.info_outline_rounded
                        : Icons.account_balance_wallet_outlined,
                    size: 18,
                    color:
                        _isFeeDeductedFromAmount
                            ? Colors.orangeAccent
                            : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'fee_deduction_label'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            widget.isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight:
                            _isFeeDeductedFromAmount
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isFeeDeductedFromAmount,
                    activeColor: Colors.orangeAccent,
                    onChanged: (val) {
                      setState(() {
                        _isFeeDeductedFromAmount = val;
                      });
                      if (_amountController.text.isNotEmpty) {
                        _onAmountChanged(_amountController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_formattedAmount.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isFeeDeductedFromAmount
                              ? 'total_label'.tr()
                              : 'sent_amount_label'.tr(),
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$_formattedAmount $_selectedCurrency',
                          style: TextStyle(
                            color: AppColors.adaptiveIcon(widget.isDarkMode),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (_amountInWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$_amountInWords ${_selectedCurrency == 'YER' ? 'ريال يمني' : (_selectedCurrency == 'USD' ? 'دولار' : 'ريال سعودي')}',
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_fee > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _isFeeDeductedFromAmount
                                    ? 'fee_deducted_label'.tr()
                                    : 'fee_added_label'.tr(),
                                style: TextStyle(
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${formatAmountDisplay(_fee)} $_selectedCurrency',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_totalWithFee > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _isFeeDeductedFromAmount
                                    ? 'net_amount_label'.tr()
                                    : 'total_to_pay_label'.tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      _isFeeDeductedFromAmount
                                          ? Colors.green
                                          : AppColors.adaptiveIcon(
                                            widget.isDarkMode,
                                          ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isFeeDeductedFromAmount
                                  ? '${formatAmountDisplay((double.tryParse(_amountController.text) ?? 0.0) - _fee)} $_selectedCurrency'
                                  : '${formatAmountDisplay(_totalWithFee)} $_selectedCurrency',
                              style: TextStyle(
                                color:
                                    _isFeeDeductedFromAmount
                                        ? Colors.green
                                        : AppColors.adaptiveText(
                                          widget.isDarkMode,
                                          lightColor: AppColors.primaryBlue,
                                        ),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(),
            if (!_isAmountValid && _amountLimitError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 5),
                child: Text(
                  '${'amount_limit_warning_prefix'.tr()} $_amountLimitError',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().shake(),
            if (!_hasEnoughBalance)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 5),
                child: Text(
                  'insufficient_balance_warning'.tr(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().shake(),
            const SizedBox(height: 18),
            _buildPurposeDropdown(),
            const SizedBox(height: 18),
            _buildPremiumTextField(
              controller: _notesController,
              label: 'notes_label'.tr(),
              hint: 'notes_hint'.tr(),
              icon: Icons.note_alt_rounded,
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.adaptiveIcon(widget.isDarkMode),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    Widget? suffixIcon,
    bool hasError = false,
    String? bottomHint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  hasError
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : (widget.isDarkMode
                          ? Colors.white10
                          : Colors.grey.shade200),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            textDirection: ui.TextDirection.rtl,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (bottomHint != null && hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Text(
              bottomHint,
              style: TextStyle(
                color:
                    hasError
                        ? Colors.redAccent
                        : (widget.isDarkMode ? Colors.white54 : Colors.black54),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPurposeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 6),
          child: Text(
            'purpose_label'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPurpose,
              isExpanded: true,
              dropdownColor:
                  widget.isDarkMode ? AppColors.cardDark : Colors.white,
              items:
                  [
                        'purpose_family_expenses',
                        'purpose_rent',
                        'purpose_bill_payment',
                        'purpose_other',
                      ]
                      .map(
                        (String val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(
                            val.tr(),
                            style: TextStyle(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white
                                      : AppColors.textBlack,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPurpose = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.adaptiveIcon(
              widget.isDarkMode,
            ).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _sendRemittance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'send_transfer_now'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _sendRemittance() async {
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
    final recipientName = _nameController.text.trim();
    final senderName = _senderNameController.text.trim();
    final senderAddress = _senderAddressController.text.trim();
    final senderPhone = _senderPhoneController.text.trim();
    if (!_validateInputs(
      recipientName: recipientName,
      senderName: senderName,
      senderAddress: senderAddress,
      senderPhone: senderPhone,
    )) {
      return;
    }
    // إظهار تفاصيل الحوالة
    TransactionDetailsBottomSheet.show(
      context,
      isDarkMode: widget.isDarkMode,
      amount: _amountController.text,
      currency: _selectedCurrency,
      transactionType: 'send_local_transfer'.tr(),
      networkName: widget.networkName,
      fee: '${formatAmountDisplay(_fee)} $_selectedCurrency',
      totalAmount: '${formatAmountDisplay(_totalWithFee)} $_selectedCurrency',
      recipientName: recipientName,
      recipientId: _phoneController.text,
      senderName: senderName,
      senderId: senderPhone,
      onExecute: () async {
        final result = await SecurityConfirmationDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
        );
        if (!mounted) return;

        if (result != null) {
          _executeSendRemittance(
            result is String ? result : null,
            recipientName: recipientName,
            senderName: senderName,
            senderAddress: senderAddress,
            senderPhone: senderPhone,
          );
        }
      },
    );
  }

  Future<void> _executeSendRemittance(
    String? password, {
    required String recipientName,
    required String senderName,
    required String senderAddress,
    required String senderPhone,
  }) async {
    sessionManager.isOperationInProgress = true;
    setState(() => _isLoading = true);

    try {
      final payload = _buildPayload(
        senderAddress: senderAddress,
        recipientName: recipientName,
        senderName: senderName,
        senderPhone: senderPhone,
        password: password ?? '',
      );

      String endPoint = 'api/SaifiCash/wallet/send-remittance/';
      if (widget.networkName.contains('باي')) {
        endPoint = 'api/remittances/send/';
      }

      final result = await ApiService.sendRemittance(
        payload,
        customEndpoint: endPoint,
      );
      if (!mounted) return;

      if (mounted) {
        await _handleTransactionResult(
          result: result,
          payload: payload,
          recipientName: recipientName,
          senderName: senderName,
          senderPhone: senderPhone,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        _fetchBalances();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(
          context,
          message: e.toString().replaceAll('Exception:', ''),
        );
      }
    } finally {
      sessionManager.isOperationInProgress = false;
    }
  }

  bool _validateInputs({
    required String recipientName,
    required String senderName,
    required String senderAddress,
    required String senderPhone,
  }) {
    if (recipientName.isEmpty ||
        _phoneController.text.isEmpty ||
        _amountController.text.isEmpty ||
        senderName.isEmpty ||
        senderAddress.isEmpty ||
        senderPhone.isEmpty) {
      ErrorDialog.show(context, message: 'fill_all_fields'.tr());
      return false;
    }
    if (!_validateName(recipientName)) {
      ErrorDialog.show(
        context,
        message: 'recipient_name_four_words_error'.tr(),
      );
      return false;
    }
    if (!_validateName(senderName)) {
      ErrorDialog.show(context, message: 'sender_name_four_words_error'.tr());
      return false;
    }
    if (!_isAmountValid) {
      ErrorDialog.show(context, message: _amountLimitError);
      return false;
    }
    if (!_hasEnoughBalance) {
      ErrorDialog.show(context, message: 'insufficient_balance_with_fees'.tr());
      return false;
    }
    return true;
  }

  Map<String, dynamic> _buildPayload({
    required String senderAddress,
    required String recipientName,
    required String senderName,
    required String senderPhone,
    required String password,
  }) {
    final amountValue = double.tryParse(_amountController.text) ?? 0.0;
    final netAmount =
        _isFeeDeductedFromAmount ? (amountValue) : amountValue + _fee;
    if (widget.networkName.contains('باي')) {
      return {
        'sender_type': 'APP',
        'sender_name': senderName,
        'sender_phone': senderPhone,
        'sender_address': senderAddress,
        'recipient_name': recipientName,
        'recipient_phone': _phoneController.text,
        'amount': netAmount,
        'currency': _selectedCurrency,
        'fee': _fee,
        'is_fee_deducted': _isFeeDeductedFromAmount,
        'network_name': widget.networkName,
        'purpose': _selectedPurpose,
        'sender_user': _currentUser?['id'] ?? 0,
        'password': password,
        'notes': _notesController.text,
      };
    } else {
      return {
        'bnf_address': senderAddress,
        'bnf_name': recipientName,
        'bnf_mobile': _phoneController.text,
        'rmt_amt': netAmount,
        'rmt_ccy': _selectedCurrency,
        'rmt_notes': _notesController.text,
      };
    }
  }

  Future<void> _handleTransactionResult({
    required Map<String, dynamic> result,
    required Map<String, dynamic> payload,
    required String recipientName,
    required String senderName,
    required String senderPhone,
  }) async {
    final isSuccess = result['status'] == 'success';
    final responseMessage =
        result['message'] ??
        (isSuccess ? 'تم إرسال الحوالة بنجاح' : 'الحوالة قيد الانتظار');
    final responseData = result['data'] ?? {};
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(responseMessage),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
    final displayAmount =
        double.tryParse(payload['rmt_amt']?.toString() ?? '') ??
        double.tryParse(payload['amount']?.toString() ?? '') ??
        0.0;
    final displayFee =
        double.tryParse(responseData['fee']?.toString() ?? '') ??
        double.tryParse(responseData['commission']?.toString() ?? '') ??
        double.tryParse(responseData['rmt_fee']?.toString() ?? '') ??
        double.tryParse(payload['fee']?.toString() ?? '') ??
        double.tryParse(payload['rmt_fee']?.toString() ?? '') ??
        _fee;
    final rmtNo =
        responseData['rmt_no']?.toString() ??
        responseData['remittance_number']?.toString() ??
        '---';

    SoundService.playSuccessSound();

    await ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: isSuccess ? 'receipt_title'.tr() : 'تمت العملية',
      mainAmount: formatAmountDisplay(displayAmount),
      mainCurrency: _selectedCurrency,
      details: [
        ReceiptRowData(label: 'system_prefix'.tr(), value: widget.networkName),
        ReceiptRowData(
          label: 'المستفيد',
          value: '$recipientName\n${_phoneController.text}',
        ),
        ReceiptRowData(label: 'المودع', value: '$senderName\n$senderPhone'),
        if (_isFeeDeductedFromAmount)
          ReceiptRowData(
            label: 'receipt_fee_deducted_text'.tr(),
            value: 'receipt_fee_deducted_note'.tr(),
          ),
        ReceiptRowData(
          label: 'العمولة',
          value: '${formatAmountDisplay(displayFee)} $_selectedCurrency',
        ),
        ReceiptRowData(
          label: 'remittance_number_label'.tr(),
          value: rmtNo,
          isCopyable: true,
        ),
        if (responseData['transaction_ref'] != null)
          ReceiptRowData(
            label: 'رقم العملية',
            value: responseData['transaction_ref'].toString(),
          ),
        ReceiptRowData(
          label: 'receipt_date_label'.tr(),
          value:
              '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        ),
      ],
      shareText:
          '✅ إشعار إرسال حوالة - نظام ${widget.networkName}\n\nالحالة: $responseMessage\nالمبلغ: ${formatAmountDisplay(displayAmount)} $_selectedCurrency\nالعمولة: ${formatAmountDisplay(displayFee)} $_selectedCurrency\nالمستلم: $recipientName\nالهاتف: ${_phoneController.text}\nرقم الحوالة: $rmtNo\nتمت العملية عبر تطبيق المحفظة.',
      amountColor: Colors.red,
    );
    await NotificationService.showNotification(
      id: 2,
      title: isSuccess ? 'تم إرسال الحوالة' : 'الحوالة قيد الانتظار',
      body:
          '${formatAmountDisplay(displayAmount)} $_selectedCurrency إلى $recipientName - $responseMessage',
    );
  }

  ThemeColors _getThemeColors() {
    return ThemeColors(
      scaffoldColor: widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
      textColor:
          widget.isDarkMode
              ? Colors.white
              : AppColors.adaptiveIcon(widget.isDarkMode),
      borderColor: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
    );
  }
}

class ThemeColors {
  final Color scaffoldColor;
  final Color textColor;
  final Color borderColor;
  ThemeColors({
    required this.scaffoldColor,
    required this.textColor,
    required this.borderColor,
  });
}
