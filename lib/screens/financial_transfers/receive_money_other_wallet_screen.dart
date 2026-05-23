import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'package:flutter/services.dart';
import '../../helper/arabic_numbers_helper.dart';
import '../../components/error_dialog.dart';

class ReceiveMoneyFromOtherWalletScreen extends StatefulWidget {
  final bool isDarkMode;
  const ReceiveMoneyFromOtherWalletScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<ReceiveMoneyFromOtherWalletScreen> createState() =>
      _ReceiveMoneyFromOtherWalletScreenState();
}

class _ReceiveMoneyFromOtherWalletScreenState
    extends State<ReceiveMoneyFromOtherWalletScreen> {
  final TextEditingController _transferNumberController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _amountInWords = 'amount_zero_words'.tr();

  final List<Map<String, String>> _currencies = [
    {'name': 'ريال يمني', 'code': 'YER'},
    {'name': 'ريال سعودي', 'code': 'SAR'},
    {'name': 'دولار', 'code': 'USD'},
  ];
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _currencies[0]['code']!;
    _amountController.addListener(_updateAmountInWords);
    _transferNumberController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  void _updateAmountInWords() {
    if (_amountController.text.isEmpty || _amountController.text == '0') {
      setState(() => _amountInWords = 'amount_zero_words'.tr());
    } else {
      String currencyName =
          _currencies.firstWhere(
            (c) => c['code'] == _selectedCurrency,
          )['name']!;
      setState(
        () => _amountInWords = '${_amountController.text} $currencyName',
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canSearch =
        _transferNumberController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != 0;

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
                  _buildPremiumHeader(context),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Column(
                            children: [
                              _buildTopLogo(),
                              const SizedBox(height: 15),

                              // Form Container
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      widget.isDarkMode
                                          ? AppColors.cardDark
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 
                                        widget.isDarkMode ? 0.3 : 0.05,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPremiumLabel(
                                      'transfer_to_other_wallet_label'.tr(),
                                    ),
                                    _buildPremiumTextField(
                                      hint:
                                          'transfer_to_other_wallet_hint'.tr(),
                                      controller: _transferNumberController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        ArabicToEnglishNumbersFormatter(),
                                      ],
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: AppColors.accentBlue,
                                        ),
                                        onPressed: () {
                                          // QR Scanning logic would go here
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    _buildPremiumLabel('currency_label'.tr()),
                                    _buildPremiumDropdownField(),

                                    const SizedBox(height: 12),

                                    _buildPremiumLabel('amount_label'.tr()),
                                    _buildPremiumTextField(
                                      hint: 'amount_hint'.tr(),
                                      controller: _amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(RegExp(r'^[0.]')),
                                        ArabicToEnglishNumbersFormatter(),
                                      ],
                                      prefixIcon: Icons.monetization_on_rounded,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        right: 4,
                                      ),
                                      child: Text(
                                        _amountInWords,
                                        style: TextStyle(
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white60
                                                  : Colors.grey.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Action Button
                              _buildPremiumActionButton(
                                'search_other_wallet_button'.tr(),
                                canSearch,
                              ),

                              const SizedBox(height: 20),

                              // Terms and Conditions
                              _buildTerms(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildPremiumHeader(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
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
                'receive_from_other_wallet'.tr(),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48), // Spacer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopLogo() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'logo_circle.png',
          width: 40,
          errorBuilder:
              (context, error, stackTrace) => Icon(
                Icons.download_rounded,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
                size: 30,
              ),
        ),
      ),
    );
  }

  Widget _buildPremiumLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        label,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required String hint,
    Widget? suffixIcon,
    IconData? prefixIcon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: widget.isDarkMode ? Colors.white38 : Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon:
              prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.accentBlue, size: 22)
                  : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPremiumDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          isExpanded: true,
          dropdownColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.accentBlue,
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCurrency = val;
                _updateAmountInWords();
              });
            }
          },
          items:
              _currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency['code'],
                  child: Text(
                    '${currency['name']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildPremiumActionButton(String text, bool enabled) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            enabled
                ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton(
        onPressed:
            enabled
                ? () async {
                  ErrorDialog.show(
                    context,
                    message: "هذه الخدمة سوف يتم تفعيلها قريبا",
                  );
                  // if (!await ApiService.checkVerification(
                  //   context,
                  //   isDarkMode: widget.isDarkMode,
                  //   onVerifyNavigate:
                  //       () => Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder:
                  //               (context) => AccountConfirmationScreen(
                  //                 isDarkMode: widget.isDarkMode,
                  //               ),
                  //         ),
                  //       ),
                  // ))
                  //   return;
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'terms_title'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTermItem('term_item_1'.tr()),
          _buildTermItem('term_item_2'.tr()),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accentBlue,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
