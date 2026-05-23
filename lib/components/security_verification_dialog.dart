import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'biometric_auth.dart';

class SecurityVerificationDialog extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final String description;
  final Widget? content;

  const SecurityVerificationDialog({
    super.key,
    required this.isDarkMode,
    this.title = 'تأكيد العملية',
    this.description = 'يرجى إدخال كلمة المرور أو استخدام البصمة لتأكيد العملية',
    this.content,
  });

  static Future<dynamic> showWithPassword(
    BuildContext context, {
    required bool isDarkMode,
    String? title,
    String? description,
    Widget? content,
  }) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => SecurityVerificationDialog(
            isDarkMode: isDarkMode,
            title: title ?? 'تأكيد العملية',
            description: description ?? 'يرجى إدخال كلمة المرور أو استخدام البصمة لتأكيد العملية',
            content: content,
          ),
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required bool isDarkMode,
    String? title,
    String? description,
    Widget? content,
  }) async {
    final result = await showWithPassword(
      context,
      isDarkMode: isDarkMode,
      title: title,
      description: description,
      content: content,
    );

    if (result == true) return true;
    if (result is String && result.isNotEmpty) return true;
    return false;
  }

  @override
  State<SecurityVerificationDialog> createState() =>
      _SecurityVerificationDialogState();
}

class _SecurityVerificationDialogState
    extends State<SecurityVerificationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _canCheckBiometrics = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await BiometricAuth.canAuthenticate();
    final user = await ApiService.getCachedUser();
    bool isEnabled = false;
    
    if (user != null) {
      final username = user['username'] ?? user['phone_number'];
      final prefs = await SharedPreferences.getInstance();
      isEnabled = prefs.getBool('biometrics_enabled_$username') ?? false;
    }

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
      });

      if (canCheck && isEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _verifyBiometrics();
        });
      }
    }
  }

  Future<void> _verifyPassword({bool returnPassword = false}) async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'الرجاء إدخال كلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isValid = await ApiService.verifyOperationPassword(
        _passwordController.text,
      );

      if (mounted) {
        if (isValid) {
          Navigator.pop(
            context,
            returnPassword ? _passwordController.text : true,
          );
        } else {
          setState(() {
            _isLoading = false;
            _error = 'كلمة المرور غير صحيحة';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'خطأ في التحقق';
        });
      }
    }
  }

  Future<void> _verifyBiometrics() async {
    try {
      bool authenticated = await BiometricAuth.authenticate(
        reason: 'تأكيد العملية باستخدام البصمة',
      );

      if (authenticated && mounted) {
        const storage = FlutterSecureStorage();
        final storedPassword = await storage.read(key: 'user_password');
        if (mounted) {
          Navigator.pop(context, storedPassword ?? true);
        }
      } else if (mounted) {
        setState(() {
          _error = 'فشل التحقق من البصمة';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطأ في نظام البصمة';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : AppColors.textBlack;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.content != null) ...[
              widget.content!,
              const SizedBox(height: 15),
              Divider(color: textColor.withValues(alpha: 0.1)),
              const SizedBox(height: 15),
            ],

            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            if (_canCheckBiometrics)
              GestureDetector(
                onTap: _verifyBiometrics,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isDarkMode ? Colors.white10 : Colors.grey[300]!,
                    ),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 36,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            
            if (_canCheckBiometrics) const SizedBox(height: 15),

            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 13),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: textColor.withValues(alpha: 0.3),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                filled: true,
                fillColor: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.isDarkMode ? Colors.white10 : Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _verifyPassword(returnPassword: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'تأكيد العملية',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
