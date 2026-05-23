import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../components/biometric_auth.dart';
import 'dart:ui' as ui;

class LoginDialog extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onLoginSuccess;

  const LoginDialog({super.key, required this.isDarkMode, this.onLoginSuccess});

  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    VoidCallback? onLoginSuccess,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return LoginDialog(
          isDarkMode: isDarkMode,
          onLoginSuccess: onLoginSuccess,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: anim1, child: child),
        );
      },
    );
  }

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _error;
  String _phoneNumber = '';
  String _username = '';
  String _userType = '';
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometrics();
  }

  Future<void> _loadUserData() async {
    final user = await ApiService.getCachedUser();
    if (user != null) {
      setState(() {
        _phoneNumber = user['phone_number'] ?? '';
        _username = user['username'] ?? _phoneNumber;
        _userType = user['user_type'] ?? 'subscriber';
      });
    }
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await BiometricAuth.canAuthenticate();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.login(_username, _passwordController.text, _userType);

      if (mounted) {
        Navigator.pop(context);
        if (widget.onLoginSuccess != null) widget.onLoginSuccess!();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      bool authenticated = await BiometricAuth.authenticate(
        reason: 'biometric_auth_reason'.tr(),
      );

      if (authenticated && mounted) {
        const storage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        final storedPassword = await storage.read(
          key: 'saved_password_$_username',
        );

        if (storedPassword != null) {
          _passwordController.text = storedPassword;
          _handleLogin();
        } else {
          setState(() {
            _error = 'biometric_first_time_error'.tr();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل التحقق من البصمة';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppColors.scaffoldDark : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final inputColor =
        widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100];
    final borderColor = widget.isDarkMode ? Colors.white10 : Colors.grey[300]!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: Center(
          child: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  margin: const EdgeInsets.only(top: 45),
                  padding: const EdgeInsets.only(
                    top: 55,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'session_expired_title'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        'session_expired_subtitle'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Mobile Number Field
                      Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: inputColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'phone_number'.tr(),
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ),
                              Text(
                                _phoneNumber,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textAlign: TextAlign.start,
                        onChanged: (v) => setState(() {}),
                        style: GoogleFonts.cairo(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'password'.tr(),
                          labelStyle: GoogleFonts.cairo(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon:
                              _canCheckBiometrics
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.fingerprint,
                                      color: textColor.withValues(alpha: 0.6),
                                      size: 28,
                                    ),
                                    onPressed: _handleBiometricAuth,
                                  )
                                  : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textColor.withValues(alpha: 0.3),
                              size: 20,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                          ),
                          filled: true,
                          fillColor: inputColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: GoogleFonts.cairo(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              (_isLoading || _passwordController.text.isEmpty)
                                  ? null
                                  : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            disabledBackgroundColor: AppColors.primaryBlue
                                .withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : Text(
                                    'login'.tr(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo Circle
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode
                              ? AppColors.scaffoldDark
                              : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        gradient: AppColors.logoGradientDay,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage('logo_circle.png'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
