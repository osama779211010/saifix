import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../components/error_dialog.dart';
import '../password_setup_screen.dart';
import '../../services/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final bool isDarkMode;
  final String phoneNumber;
  final String? email;
  final Map<String, dynamic>? userData;
  final bool isDeviceVerification;
  final String? verificationTarget;
  final bool isForgotPassword;
  final bool isFamilyOTP;

  const OTPVerificationScreen({
    super.key,
    required this.isDarkMode,
    required this.phoneNumber,
    this.email,
    this.userData,
    this.isDeviceVerification = false,
    this.verificationTarget,
    this.isForgotPassword = false,
    this.isFamilyOTP = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  late final SmsRetrieverImpl _smsRetriever;
  bool _isLoading = false;

  // Timer variables
  Timer? _timer;
  int _start = 120; // 2 minutes in seconds
  bool _canResend = false;
  int _resendCount = 0;
  bool _isBlocked = false;

  void _startTimer({bool isResend = false}) {
    if (isResend) {
      _resendCount++;
      if (_resendCount > 2) {
        setState(() {
          _isBlocked = true;
          _canResend = false;
        });
        _timer?.cancel();
        return;
      }
    }

    _canResend = false;
    // Increase time by 60s for each resend
    _start = 120 + (_resendCount * 60);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    _smsRetriever = SmsRetrieverImpl(SmartAuth.instance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    _smsRetriever.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    String otp = _pinController.text;
    if (otp.length < 6) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isDeviceVerification) {
        // التحقق من الجهاز
        final deviceId = await ApiService.getDeviceId();
        final success = await ApiService.verifyDeviceOTP(
          widget.phoneNumber,
          otp,
          deviceId,
        );

        if (!mounted) return;

        if (success) {
          showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  backgroundColor:
                      widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'device_verified_title'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Text('device_verified_message'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // قفل الحوار
                        Navigator.pop(context); // العودة لشاشة الدخول
                      },
                      child: Text(
                        'ok_button'.tr(),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
          );
        } else {
          throw Exception('invalid_otp_error'.tr());
        }
      } else if (widget.isForgotPassword) {
        // التحقق لاستعادة كلمة المرور
        final result = await ApiService.forgotPasswordReset(
          username: widget.phoneNumber, // Using phoneNumber as username
          otp: otp,
        );

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Text('password_reset_title'.tr()),
                  ],
                ),
                content: Text(
                  result['message'] ?? 'temp_password_default'.tr(),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      String pinToCopy = result['new_pin']?.toString() ?? "";
                      if (pinToCopy.isEmpty) {
                        // Fallback: Try to extract a 6-digit number from the message
                        final match = RegExp(
                          r'\d{6}',
                        ).firstMatch(result['message'] ?? "");
                        if (match != null) pinToCopy = match.group(0)!;
                      }

                      if (pinToCopy.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: pinToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('temp_password_copied'.tr())),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 18),
                        const SizedBox(width: 5),
                        Text('copy_code_button'.tr()),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // Close dialog
                      Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst); // Back to login
                    },
                    child: Text('ok_button'.tr()),
                  ),
                ],
              ),
        );
      } else if (widget.isFamilyOTP) {
        // التحقق لربط فرد الأسرة
        await ApiService.verifySubWalletOTP(
          widget.phoneNumber,
          otp,
          widget.userData?['relationship'] ?? 'OTHER',
        );

        if (!mounted) return;

        // العودة بنتيجة نجاح
        Navigator.pop(context, true);
      } else {
        // التحقق العادي لإكمال التسجيل أو إعادة التعين (حسب السياق)
        await ApiService.verifyEmailOTP(
          widget.phoneNumber,
          widget.email ?? '',
          otp,
        );
        if (!mounted) return;
        if (!mounted) return;

        // الانتقال لإعداد كلمة المرور
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PasswordSetupScreen(
                  isDarkMode: widget.isDarkMode,
                  userData: {
                    ...?(widget.userData),
                    'phone_number': widget.phoneNumber,
                    'email': widget.email ?? '',
                  },
                ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCount >= 2) {
      ErrorDialog.show(
        context,
        message: 'لقد تعديت المحاولات المسموحة لطلب رمز التحقق otp',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.sendEmailOTP(widget.phoneNumber, widget.email ?? '');
      if (!mounted) return;
      _startTimer(isResend: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'otp_resent_success'.tr().isNotEmpty
                ? 'otp_resent_success'.tr()
                : 'تم إعادة إرسال الرمز بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final Color subTextColor =
        widget.isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Icon illustration
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentBlue.withValues(alpha: 0.2),
                                AppColors.accentBlue.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentBlue,
                            ),
                            child: const Icon(
                              Icons.phonelink_lock_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),

                        const SizedBox(height: 30),

                        Text(
                          widget.isDeviceVerification
                              ? 'device_verification_title'.tr()
                              : 'enter_otp_title'.tr(),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (widget.isDeviceVerification) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.accentBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'device_warning_message'.tr(
                                      args: [
                                        widget.verificationTarget ??
                                            'account'.tr(),
                                      ],
                                    ),
                                    style: TextStyle(
                                      color: widget.isDarkMode
                                          ? AppColors.accentBlue.withValues(alpha: 0.8)
                                          : AppColors.primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'sent_otp_prefix'.tr(),
                                style: TextStyle(
                                  color: subTextColor,
                                  height: 1.5,
                                ),
                              ),
                              TextSpan(
                                text: 'sent_otp_channels'.tr(),
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(
                                text:
                                    widget.verificationTarget ??
                                    widget.phoneNumber,
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 50),

                        // OTP Input via Pinput
                        Pinput(
                          length: 6,
                          controller: _pinController,
                          focusNode: _focusNode,
                          smsRetriever: _smsRetriever,
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 60,
                            textStyle: TextStyle(
                              fontSize: 24,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                              border: Border.all(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white12
                                        : Colors.black12,
                                width: 1.5,
                              ),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 55,
                            height: 65,
                            textStyle: TextStyle(
                              fontSize: 26,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                              border: Border.all(
                                color: AppColors.accentBlue,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentBlue.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          submittedPinTheme: PinTheme(
                            width: 50,
                            height: 60,
                            textStyle: TextStyle(
                              fontSize: 24,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                              border: Border.all(
                                color: AppColors.accentBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onCompleted: (pin) => _onConfirm(),
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                        const SizedBox(height: 40),

                        if (!_isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white54
                                          : Colors.black45,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _timerText,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'timer_label'.tr(),
                                  style: TextStyle(
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white54
                                            : Colors.black45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_isBlocked)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'لقد تعديت المحاولات المسموحة لطلب رمز التحقق otp',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: TextButton(
                              onPressed: _canResend ? _resendOTP : null,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    _canResend
                                        ? AppColors.accentBlue.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'resend_action'.tr(),
                                style: TextStyle(
                                  color:
                                      _canResend
                                          ? AppColors.accentBlue
                                          : Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

                        // Confirm Button
                        SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accentBlue,
                                      AppColors.glowBlue,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentBlue.withValues(alpha: 
                                        0.3,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _onConfirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    'confirm_button'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 25),

                        const SizedBox(height: 20),

                        const SizedBox(height: 20),
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
              color: AppColors.accentBlue.withValues(alpha: 
                widget.isDarkMode ? 0.05 : 0.03,
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
              color: AppColors.accentBlue.withValues(alpha: 
                widget.isDarkMode ? 0.05 : 0.03,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            'header_title'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Implementation of Pinput's SmsRetriever using smart_auth package
class SmsRetrieverImpl implements SmsRetriever {
  const SmsRetrieverImpl(this.smartAuth);

  final SmartAuth smartAuth;

  @override
  Future<void> dispose() => smartAuth.removeSmsRetrieverApiListener();

  @override
  Future<String?> getSmsCode() async {
    final res = await smartAuth.getSmsWithRetrieverApi();
    if (res.hasData && res.data != null) {
      return res.data!.code;
    }
    return null;
  }

  @override
  bool get listenForMultipleSms => false;
}
