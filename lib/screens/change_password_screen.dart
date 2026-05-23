import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import '../services/theme_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool isForced;
  final Map<String, dynamic>? userData;
  final String? currentPassword;

  const ChangePasswordScreen({
    super.key,
    required this.isDarkMode,
    this.isForced = false,
    this.userData,
    this.currentPassword,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.isForced && widget.currentPassword != null) {
      _oldPasswordController.text = widget.currentPassword!;
    }
  }

  Future<void> _handleChangePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showError('fill_all_fields'.tr());
      return;
    }

    if (newPass != confirmPass) {
      _showError('new_password_mismatch'.tr());
      return;
    }

    if (newPass.length < 6) {
      _showError('password_min_length'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.changePassword(oldPass, newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('password_changed_success'.tr())),
        );

        if (widget.isForced && widget.userData != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => HomeScreen(
                    isDarkMode: themeService.isDarkModeActive(context),
                    isInitiallyVerified:
                        widget.userData!['is_verified'] ?? false,
                  ),
            ),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return PopScope(
      canPop: !widget.isForced, // منع الخروج إذا كان التغيير إجبارياً
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
        body: Stack(
          children: [
            _buildPremiumBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildPremiumHeader(
                        widget.isForced
                            ? 'forced_update_title'.tr()
                            : 'change_password_title'.tr(),
                        widget.isForced ? null : () => Navigator.pop(context),
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          _buildInfoCard(),
                          const SizedBox(height: 30),
                          if (!widget.isForced) ...[
                            _buildPasswordField(
                              controller: _oldPasswordController,
                              label: 'old_password_label'.tr(),
                              showPassword: _showOldPassword,
                              onToggle:
                                  () => setState(
                                    () => _showOldPassword = !_showOldPassword,
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: 'new_password_label'.tr(),
                            showPassword: _showNewPassword,
                            onToggle:
                                () => setState(
                                  () => _showNewPassword = !_showNewPassword,
                                ),
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'confirm_password_label'.tr(),
                            showPassword: _showConfirmPassword,
                            onToggle:
                                () => setState(
                                  () =>
                                      _showConfirmPassword =
                                          !_showConfirmPassword,
                                ),
                          ),
                          const SizedBox(height: 40),
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
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
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
                color: AppColors.accentBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String title, VoidCallback? onBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        widget.isDarkMode ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          widget.isDarkMode ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
                    size: 18,
                  ),
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accentBlue),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              widget.isForced
                  ? 'info_forced_message'.tr()
                  : 'info_regular_message'.tr(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    final isDark = widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textBlack),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    ).animate().fade(delay: 100.ms).slideX(begin: 0.05);
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleChangePassword,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child:
                _isLoading
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      'update_password_button'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ),
    ).animate().fade(delay: 200.ms).scale();
  }
}
