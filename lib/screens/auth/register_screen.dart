import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../services/theme_service.dart';
import '../terms_conditions_screen.dart';
import 'otp_verification_screen.dart';
import '../../services/api_service.dart';
import '../locations_view_screen.dart';
import 'dart:ui' as ui;

class RegisterScreen extends StatefulWidget {
  final bool isDarkMode;
  const RegisterScreen({super.key, required this.isDarkMode});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _thirdNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // FocusNodes for ordered navigation between name fields
  final _firstNameFocus = FocusNode();
  final _secondNameFocus = FocusNode();
  final _thirdNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _isMale = true;
  bool _agreedToTerms = false;

  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _thirdNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _firstNameFocus.dispose();
    _secondNameFocus.dispose();
    _thirdNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  /// Opens Terms screen and sets agreedToTerms to true upon return if accepted
  Future<void> _openTermsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TermsConditionsScreen(
              isDarkMode: _isDarkMode,
              onAccepted: () {
                setState(() => _agreedToTerms = true);
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors();

    return Scaffold(
      backgroundColor: colors.scaffoldColor,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(context, colors),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // اللوجو في الأعلى
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: colors.cardColor,
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
                                _isDarkMode ? 'logo_circle.png' : 'pr_logo.png',
                                height: 80,
                                width: 80,
                              ),
                            ).animate().scale(
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // نصوص الترحيب
                          Column(
                            children: [
                              Text(
                                    'welecom'.tr(),
                                    style: TextStyle(
                                      color: colors.textColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 8),
                              Text(
                                    'enter_signin'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 14,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 15),
                              Text(
                                'enter_name_like_id'.tr(),
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ).animate().shake(delay: 1.seconds),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // حقول الاسم (شبكة 2x2) — بالترتيب: الأول ← الثاني ← الثالث ← اللقب
                          Row(
                            children: [
                              Expanded(
                                child: _buildNameInputField(
                                  controller: _firstNameController,
                                  focusNode: _firstNameFocus,
                                  nextFocusNode: _secondNameFocus,
                                  label: 'first_name'.tr(),
                                  colors: colors,
                                  validator:
                                      (v) =>
                                          _validateArabicName(v, 'first_name'),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildNameInputField(
                                  controller: _secondNameController,
                                  focusNode: _secondNameFocus,
                                  nextFocusNode: _thirdNameFocus,
                                  label: 'second_name'.tr(),
                                  colors: colors,
                                  validator:
                                      (v) =>
                                          _validateArabicName(v, 'second_name'),
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
                                  label: 'third_name'.tr(),
                                  colors: colors,
                                  validator:
                                      (v) =>
                                          _validateArabicName(v, 'third_name'),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildNameInputField(
                                  controller: _lastNameController,
                                  focusNode: _lastNameFocus,
                                  nextFocusNode: _phoneFocus,
                                  label: 'last_name'.tr(),
                                  colors: colors,
                                  isLast: true,
                                  validator:
                                      (v) =>
                                          _validateArabicName(v, 'last_name'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // رقم الموبايل بتصميم البطاقة
                          _buildPhoneInputField(colors),

                          const SizedBox(height: 15),

                          // حقل البريد الإلكتروني
                          _buildEmailInputField(colors),

                          const SizedBox(height: 20),

                          // اختيار الجنس
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderSelector(
                                  isMale: false,
                                  colors: colors,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildGenderSelector(
                                  isMale: true,
                                  colors: colors,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // الموافقة على الشروط
                          // الضغط على الصف كله أو على الـ Checkbox يفتح شاشة الشروط
                          InkWell(
                            onTap: _openTermsScreen,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  activeColor: AppColors.accentBlue,
                                  onChanged: (v) {
                                    if (v == true) {
                                      // عند تفعيل الـ Checkbox نفتح شاشة الشروط
                                      _openTermsScreen();
                                    } else {
                                      setState(() => _agreedToTerms = false);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              'agree_to_the_termsandconditions'
                                                  .tr(),
                                          style: TextStyle(
                                            color: AppColors.accentBlue,
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // زر التسجيل
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _phoneController,
                            builder: (context, value, child) {
                              final phone = value.text.trim();
                              final email = _emailController.text.trim();
                              final isPhoneValid = phone.length == 9;
                              final isEmailValid =
                                  email.isEmpty ||
                                  (email.contains('@') && email.contains('.'));
                              final isButtonEnabled =
                                  _agreedToTerms &&
                                  isPhoneValid &&
                                  isEmailValid;

                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors:
                                        isButtonEnabled
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
                                      isButtonEnabled
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
                                  onPressed:
                                      isButtonEnabled ? _handleRegister : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      60,
                                    ),
                                  ),
                                  child: Text(
                                    'sign_up'.tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // رابط العودة للدخول
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'have_an_account'.tr(),
                                style: TextStyle(
                                  color: colors.textColor.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'login'.tr(),
                                  style: TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // العنوان الجمالي لتواصل معنا
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: colors.borderColor),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Text(
                                  'contact_us'.tr(),
                                  style: TextStyle(
                                    color: colors.textColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: colors.borderColor),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // أيقونات التواصل في الأسفل
                          _buildContactIcons(colors),

                          const SizedBox(height: 20),
                        ],
                      ),
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

  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (phone.length != 9) return;
    if (!email.contains('@')) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // التحقق مما إذا كان المستخدم موجوداً مسبقاً
      final exists = await ApiService.checkUserExists(phone);
      if (exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        _showErrorDialog(
          title: 'register_failed'.tr(),
          message:
              '${'phone_registered_prefix'.tr()} ($phone) ${'phone_registered_suffix'.tr()}',
          primaryButtonText: 'login'.tr(),
          onPrimaryPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to login
          },
          secondaryButtonText: 'ok'.tr(),
        );
        return;
      }

      final userData = {
        'first_name': _firstNameController.text,
        'second_name': _secondNameController.text,
        'third_name': _thirdNameController.text,
        'last_name': _lastNameController.text,
        'phone_number': phone,
        'email': email,
        'gender': _isMale ? 'M' : 'F',
      };

      // أرسل الرمز للهاتف (والإيميل إذا وجد) وانتقل لشاشة التحقق
      await ApiService.sendEmailOTP(phone, email);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => OTPVerificationScreen(
                isDarkMode: _isDarkMode,
                phoneNumber: phone,
                email: email,
                userData: userData,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        title: 'error_occurred'.tr(),
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEmailInputField(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: Text(
            '${"email".tr()} (${"verification_code".tr()})',
            style: TextStyle(
              color: colors.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          textAlign: TextAlign.left,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            color: colors.textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'example@mail.com',
            hintStyle: TextStyle(
              color: colors.textColor.withValues(alpha: 0.3),
            ),
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            filled: true,
            fillColor: colors.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderColor),
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

  /// التحقق من أن النص يحتوي على حروف عربية فقط
  String? _validateArabicName(String? value, String labelKey) {
    if (value == null || value.trim().isEmpty) {
      return 'please_enter_the_required_data'.tr();
    }
    // تعبير منتظم يسمح فقط بالحروف العربية والمسافات
    final arabicRegex = RegExp(r'^[\u0600-\u06FF\s]*$');
    if (!arabicRegex.hasMatch(value)) {
      return 'enter_field_in_arabic'.tr(args: [labelKey.tr()]);
    }
    return null;
  }

  /// حقل الاسم: نص عربي فقط، لا أرقام ولا رموز
  /// عند الضغط على مسافة أو زر "التالي" ينتقل للحقل التالي
  Widget _buildNameInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required String label,
    required ThemeColors colors,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
              color: colors.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.right,
          textInputAction: isLast ? TextInputAction.next : TextInputAction.next,
          keyboardType: TextInputType.text,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters:
              inputFormatters ??
              [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[\u0600-\u06FFa-zA-Z\s]'),
                ),
              ],
          validator: validator,
          onChanged: (value) {
            // عند الضغط على مسافة: احذف المسافة وانتقل للحقل التالي
            if (value.endsWith(' ')) {
              controller.text = value.trimRight();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          },
          style: TextStyle(
            color: colors.textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            errorStyle: TextStyle(
              color: AppColors.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            errorMaxLines: 2,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accentBlue, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: Text(
            'phone_number'.tr(),
            style: TextStyle(
              color: colors.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              color: colors.cardColor,
              border: Border.all(color: colors.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              // textDirection: TextDirection.LTR,
              children: [
                // مفتاح الدولة
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
                      // محاكاة علم اليمن
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          width: 28,
                          height: 18,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  color: const Color(0xFFCE1126),
                                ),
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
                Container(width: 1, height: 25, color: colors.borderColor),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.left,
                    maxLength: 9,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    onChanged: (value) {
                      if (value.length == 9) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: '77X XXX XXX',
                      counterText: "",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector({
    required bool isMale,
    required ThemeColors colors,
  }) {
    final isSelected = _isMale == isMale;
    return InkWell(
      onTap: () => setState(() => _isMale = isMale),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : colors.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : colors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isMale ? 'male'.tr() : 'female'.tr(),
              style: TextStyle(
                color: isSelected ? AppColors.accentBlue : colors.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isMale ? Icons.male_rounded : Icons.female_rounded,
              color: isSelected ? AppColors.accentBlue : colors.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactIcons(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildContactItem(
          Icons.call_rounded,
          'free_number'.tr(),
          colors,
          onTap: () async {
            final Uri phoneUri = Uri(scheme: 'tel', path: '8000002');
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri);
            }
          },
        ),
        _buildContactItem(
          Icons.location_on_rounded,
          'service_points'.tr(),
          colors,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        LocationsViewScreen(isDarkMode: _getIsDarkMode()),
              ),
            );
          },
        ),
        _buildContactItem(
          Icons.chat_bubble_rounded,
          'customer_service'.tr(),
          colors,
          onTap: _launchWhatsApp,
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+967778555555';
    // Try native app first
    final nativeUrl = Uri.parse('whatsapp://send?phone=$phone');
    // Fallback to web link using api.whatsapp.com which is more reliable than wa.me
    final webUrl = Uri.parse(
      'https://api.whatsapp.com/send?phone=${phone.replaceAll('+', '')}',
    );

    try {
      if (await canLaunchUrl(nativeUrl)) {
        await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('whatsapp_not_installed'.tr())),
          );
        }
      }
    } catch (e) {
      customPrint('Error launching WhatsApp: $e');
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('unable_to_open_whatsapp'.tr())),
          );
        }
      }
    }
  }

  bool _getIsDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    ThemeColors colors, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: Icon(icon, color: AppColors.accentBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.textColor.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  ThemeColors _getThemeColors() {
    final isDark = themeService.isDarkModeActive(context);
    return ThemeColors(
      scaffoldColor: isDark ? AppColors.scaffoldDark : Colors.white,
      textColor: isDark ? Colors.white : AppColors.primaryBlue,
      hintColor: isDark ? Colors.white70 : Colors.black54,
      borderColor: isDark ? Colors.white24 : Colors.grey.shade300,
      cardColor:
          isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
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
              color: AppColors.accentBlue.withValues(
                alpha: _isDarkMode ? 0.05 : 0.03,
              ),
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
              color: AppColors.accentBlue.withValues(
                alpha: _isDarkMode ? 0.05 : 0.03,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textColor,
            ),
          ),
          Text(
            'sign_up'.tr(),
            style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  void _showErrorDialog({
    required String title,
    required String message,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    final isDark = themeService.isDarkModeActive(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            elevation: 10,
            shadowColor: AppColors.accentBlue.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(
                color:
                    isDark
                        ? Colors.white10
                        : AppColors.accentBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon with subtle glow effect
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.accentBlue.withValues(alpha: 0.1)
                            : AppColors.accentBlue.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textGreyLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                if (primaryButtonText != null && secondaryButtonText != null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              onSecondaryPressed ??
                              () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            secondaryButtonText,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? Colors.white70
                                      : AppColors.textGreyLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              onPrimaryPressed ?? () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            primaryButtonText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          onPrimaryPressed ?? () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        primaryButtonText ?? 'ok'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}

class ThemeColors {
  final Color scaffoldColor;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;
  final Color cardColor;

  ThemeColors({
    required this.scaffoldColor,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.cardColor,
  });
}
