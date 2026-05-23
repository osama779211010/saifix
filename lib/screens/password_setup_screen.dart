import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PasswordSetupScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, String>? userData;
  final String? phoneNumber;
  final bool isResetMode;
  final String? oldPassword;
  final bool isForced;
  final Map<String, dynamic>? fullUserData;

  const PasswordSetupScreen({
    super.key,
    required this.isDarkMode,
    this.userData,
    this.phoneNumber,
    this.isResetMode = false,
    this.oldPassword,
    this.isForced = false,
    this.fullUserData,
  });

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'passwords_not_match'.tr(),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'password_min_length'.tr(),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    if (_passwordController.text == '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'password_cannot_be_default'.tr(),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isResetMode) {
        // --- وضع تحديث كلمة المرور (Reset Password Mode) ---
        if (widget.oldPassword == null) throw Exception('session_data_incomplete'.tr());
        
        await ApiService.changePassword(
          widget.oldPassword!,
          _passwordController.text,
        );

        final userData = await ApiService.getMe();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('password_updated_success'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
            ),
          );

          final finalUserData = widget.fullUserData ?? userData;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                isDarkMode: widget.isDarkMode,
                isInitiallyVerified: finalUserData['is_verified'] ?? false,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        // --- وضع إنشاء الحساب الجديد (Registration Mode) ---
        if (widget.userData == null) throw Exception('user_data_missing'.tr());
        
        final deviceId = await ApiService.getDeviceId();
        final registrationData = {
          ...widget.userData!,
          'password': _passwordController.text,
          'mac_address': deviceId,
        };

        final response = await ApiService.register(registrationData);
        final userData = response['user'];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('account_created_success'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
            ),
          );

          // إذا كان التسجيل لفرد عائلة → ارجع بـ true بدلاً من فتح HomeScreen
          if (widget.userData!['is_family_member'] == 'true') {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  isDarkMode: widget.isDarkMode,
                  isInitiallyVerified: userData['is_verified'] ?? false,
                ),
              ),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_occurred'.tr(args: [e.toString()]), style: const TextStyle()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isForced,
      child:Scaffold(
        backgroundColor:
            widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
        body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_reset_rounded,
                          size: 80,
                          color: AppColors.accentBlue,
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.isResetMode ? 'reset_title'.tr() : 'final_step'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'set_strong_password_hint'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 40),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'password_label'.tr(),
                          hint: 'password_hint'.tr(),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'confirm_password_label'.tr(),
                          hint: 'confirm_password_hint'.tr(),
                        ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.accentBlue,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                          widget.isResetMode ? 'save_update'.tr() : 'complete_registration'.tr(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),);

  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    widget.isDarkMode ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
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
    final textColor = widget.isDarkMode ? Colors.white : AppColors.primaryBlue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isForced)
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          Text(
            'reset_password_now'.tr(),
            style: TextStyle(
              color: textColor,
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
