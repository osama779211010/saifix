import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saifix/core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/receipt_dialog.dart';

// Since this is UI-only for requesting an account, we don't necessarily need API implementations yet unless requested,
// but we will prepare the form with validations.
class BusinessRegisterScreen extends StatefulWidget {
  final bool isDarkMode;
  const BusinessRegisterScreen({super.key, required this.isDarkMode});

  @override
  State<BusinessRegisterScreen> createState() => _BusinessRegisterScreenState();
}

class _BusinessRegisterScreenState extends State<BusinessRegisterScreen> {
  // Controllers
  final _orgNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _thirdNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Focus Nodes
  final _orgNameFocus = FocusNode();
  final _firstNameFocus = FocusNode();
  final _secondNameFocus = FocusNode();
  final _thirdNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();

  // State
  String _selectedType = 'POS'; // 'تاجر', 'وكيل', 'شركة'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await ApiService.getCachedUser();
    if (user != null) {
      setState(() {
        _firstNameController.text = user['first_name'] ?? '';
        _secondNameController.text = user['second_name'] ?? '';
        _thirdNameController.text = user['third_name'] ?? '';
        _lastNameController.text = user['last_name'] ?? '';
        _phoneController.text = user['phone_number'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _firstNameController.dispose();
    _secondNameController.dispose();
    _thirdNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    _orgNameFocus.dispose();
    _firstNameFocus.dispose();
    _secondNameFocus.dispose();
    _thirdNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 9) return;
    if (_orgNameController.text.isEmpty) return;
    if (_firstNameController.text.isEmpty ||
        _secondNameController.text.isEmpty ||
        _thirdNameController.text.isEmpty ||
        _lastNameController.text.isEmpty) {
      return;
    }
    if (_addressController.text.isEmpty) return;

    final fullName =
        '${_firstNameController.text} ${_secondNameController.text} ${_thirdNameController.text} ${_lastNameController.text}';

    setState(() => _isLoading = true);

    try {
      await ApiService.businessRegister(
        fullName: fullName,
        requestType: _selectedType,
        location: _addressController.text,
        establishmentName: _orgNameController.text,
        notes: _addressController.text,
      );
      if (!mounted) return;

      if (context.mounted) {
        setState(() => _isLoading = false);
        ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'request_received_title'.tr(),
          mainAmount: '',
          mainCurrency: '',
          details: [
            ReceiptRowData(
              label: 'request_reference_number'.tr(),
              value:
                  'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              isCopyable: true,
            ),
            ReceiptRowData(label: 'request_type'.tr(), value: _selectedType),
            ReceiptRowData(
              label: 'establishment_name_label'.tr(),
              value: _orgNameController.text,
            ),
            ReceiptRowData(label: 'full_name_label'.tr(), value: fullName),
          ],
          onClose: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // Simulate API call for now since no specific endpoint was mentioned for this type of account request
    // await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Color _getCardColor() =>
      widget.isDarkMode ? AppColors.cardDark : Colors.white;
  Color _getTextColor() =>
      widget.isDarkMode ? Colors.white : AppColors.textBlack;
  Color _getBorderColor() =>
      widget.isDarkMode ? Colors.white10 : Colors.grey.shade200;
  Color _getScaffoldColor() =>
      widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight;

  Widget _buildPremiumBackground() {
    return Positioned(
      top: -150,
      right: -50,
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
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: _getTextColor()),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'business_register_title'.tr(),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Balance spacing
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldColor(),
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
                      horizontal: 25,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _getCardColor(),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              widget.isDarkMode
                                  ? 'logo_circle.png'
                                  : 'pr_logo.png',
                              height: 70,
                              width: 70,
                            ),
                          ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Column(
                          children: [
                            Text(
                                  'business_account_title'.tr(),
                                  style: TextStyle(
                                    color: _getTextColor(),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 8),
                            Text(
                                  'business_account_subtitle'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _getTextColor().withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 13,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideY(begin: 0.2, end: 0),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Account Type Selector
                        Row(
                          children: [
                            Expanded(child: _buildTypeSelector('POS')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTypeSelector('AGENT')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTypeSelector('COMPANY')),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Org Name
                        _buildInputField(
                          controller: _orgNameController,
                          focusNode: _orgNameFocus,
                          nextFocusNode: _firstNameFocus,
                          label: 'org_name_label'.tr(),
                          icon: Icons.storefront_rounded,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          '* ${'owner_note'.tr()}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(),

                        const SizedBox(height: 10),

                        // Name fields (2x2 grid)
                        Row(
                          children: [
                            Expanded(
                              child: _buildNameInputField(
                                controller: _firstNameController,
                                focusNode: _firstNameFocus,
                                nextFocusNode: _secondNameFocus,
                                label: 'first_name_label'.tr(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildNameInputField(
                                controller: _secondNameController,
                                focusNode: _secondNameFocus,
                                nextFocusNode: _thirdNameFocus,
                                label: 'second_name_label'.tr(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNameInputField(
                                controller: _thirdNameController,
                                focusNode: _thirdNameFocus,
                                nextFocusNode: _lastNameFocus,
                                label: 'third_name_label'.tr(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildNameInputField(
                                controller: _lastNameController,
                                focusNode: _lastNameFocus,
                                nextFocusNode: _phoneFocus,
                                label: 'last_name_label'.tr(),
                                isLastInGrid: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Phone
                        _buildPhoneInputField(),

                        const SizedBox(height: 20),

                        // Address
                        _buildInputField(
                          controller: _addressController,
                          focusNode: _addressFocus,
                          nextFocusNode: null,
                          label: 'address_label_main'.tr(),
                          icon: Icons.location_on_rounded,
                          isLast: true,
                        ),

                        const SizedBox(height: 30),

                        // Submit Button
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _phoneController,
                          builder: (context, value, child) {
                            final isValid =
                                value.text.length == 9 &&
                                _orgNameController.text.isNotEmpty &&
                                _addressController.text.isNotEmpty &&
                                _firstNameController.text.isNotEmpty &&
                                _secondNameController.text.isNotEmpty &&
                                _thirdNameController.text.isNotEmpty &&
                                _lastNameController.text.isNotEmpty;

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors:
                                      isValid
                                          ? [
                                            AppColors.primaryBlue,
                                            AppColors.accentBlue,
                                          ]
                                          : [
                                            Colors.grey.shade400,
                                            Colors.grey.shade500,
                                          ],
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                ),
                                boxShadow:
                                    isValid
                                        ? [
                                          BoxShadow(
                                            color: AppColors.primaryBlue
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: ElevatedButton(
                                onPressed: isValid ? _handleSubmit : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  minimumSize: const Size(double.infinity, 55),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                        : Text(
                                          'submit_request'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(String type) {
    final isSelected = _selectedType == type;
    // Display mapping: keep internal value (type) unchanged for logic, translate only for UI
    final displayText =
        type == 'POS'
            ? 'merchant_label'.tr()
            : type == 'AGENT'
            ? 'agent_label'.tr()
            : 'company_label'.tr();

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : _getCardColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : _getBorderColor(),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: isSelected ? AppColors.accentBlue : _getTextColor(),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocusNode,
    required String label,
    required IconData icon,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: Text(
            label,
            style: TextStyle(
              color: _getTextColor().withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.right,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          onSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.accentBlue, size: 20),
            filled: true,
            fillColor: _getCardColor(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor()),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
            ),
          ),
          onChanged: (v) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildNameInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required String label,
    bool isLastInGrid = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: Text(
            label,
            style: TextStyle(
              color: _getTextColor().withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          textAlign: TextAlign.right,
          textInputAction:
              isLastInGrid ? TextInputAction.next : TextInputAction.next,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[\u0600-\u06FFa-zA-Z\s]'),
            ),
          ],
          onChanged: (value) {
            if (value.endsWith(' ')) {
              controller.text = value.trimRight();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
            setState(() {});
          },
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          },
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _getCardColor(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor()),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: Text(
            'mobile_label'.tr(),
            style: TextStyle(
              color: _getTextColor().withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: _getCardColor(),
            border: Border.all(color: _getBorderColor()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+967',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: 28,
                        height: 18,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(color: const Color(0xFFCE1126)),
                            ),
                            Expanded(child: Container(color: Colors.white)),
                            Expanded(child: Container(color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 25, color: _getBorderColor()),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  readOnly: true, // Auto-filled data should not be modified
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.left,
                  maxLength: 9,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  onChanged: (value) {
                    if (value.length == 9) {
                      FocusScope.of(context).requestFocus(_addressFocus);
                    }
                    setState(() {});
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_addressFocus);
                  },
                  style: TextStyle(
                    color: _getTextColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'phone_input_hint'.tr(),
                    counterText: "",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      letterSpacing: 0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
