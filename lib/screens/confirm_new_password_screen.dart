import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ConfirmNewPasswordScreen extends StatefulWidget {
  final bool isDarkMode;
  final String oldPassword; // 123456

  const ConfirmNewPasswordScreen({
    super.key,
    required this.isDarkMode,
    required this.oldPassword,
  });

  @override
  State<ConfirmNewPasswordScreen> createState() => _ConfirmNewPasswordScreenState();
}

class _ConfirmNewPasswordScreenState extends State<ConfirmNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || confirm.isEmpty) {
       _showSnackBar('enter_password_and_confirm'.tr());
       return;
    }

    if (password != confirm) {
      _showSnackBar('passwords_do_not_match'.tr());
      return;
    }

    if (password.length < 6) {
      _showSnackBar('password_min_length'.tr());
      return;
    }
    
    if (password == '123456') {
      _showSnackBar('choose_different_than_temp'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      // API call to change password
      await ApiService.changePassword(
        widget.oldPassword,
        password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('password_updated_success'.tr())),
      );

      // Go to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            isDarkMode: widget.isDarkMode,
            isInitiallyVerified: true, // User is already logged in and verified identity to reset password
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _showSnackBar('error_occurred'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : AppColors.primaryBlue;
    return Scaffold(
      backgroundColor: widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(context, textColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Icon(
                          Icons.security_update_good_rounded,
                          size: 80,
                          color: AppColors.accentBlue,
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'secure_account_title'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'secure_account_message'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 40),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'new_password_label'.tr(),
                          hint: 'new_password_hint'.tr(),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'confirm_password_label'.tr(),
                          hint: 'confirm_password_hint'.tr(),
                        ),
                        const SizedBox(height: 50),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.isDarkMode ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.accentBlue],
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
          onPressed: _isLoading ? null : _handleUpdatePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'update_password_and_login'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
              color: AppColors.accentBlue.withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'update_password_title'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
