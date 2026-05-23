import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'account_confirmation_screen.dart';
import 'change_password_screen.dart';
import 'device_management_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  final bool isDarkMode;

  const PrivacySecurityScreen({super.key, required this.isDarkMode});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _hideNameAtTransfer = false;
  bool _hideNameAtPurchase = false;
  bool _isLoadingPrivacy = false;
  String _fullName = "";

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSettings();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isSupported && canCheck;
        });
      }
    } catch (e) {
      customPrint('Error checking biometrics: $e');
    }
  }

  Future<void> _loadSettings() async {
    final user = await ApiService.getCachedUser();
    if (user == null) return;
    final username = user['username'] ?? user['phone_number'];

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isBiometricEnabled =
            prefs.getBool('biometrics_enabled_$username') ?? false;

        // جلب إعدادات الخصوصية من بيانات المستخدم المخزنة
        final walletUser =
            user['wallet_user'] ??
            user; // قد تكون البيانات مباشرة في الـ user حسب السيريالايزر
        // _fullName =
        //     walletUser['full_name'] ??
        //     "${walletUser['first_name'] ?? ''} ${walletUser['second_name'] ?? ''} ${walletUser['third_name'] ?? ''} ${walletUser['last_name'] ?? ''}"
        //         .trim();
        _hideNameAtTransfer = walletUser['hide_name_at_transfer'] ?? false;
        _hideNameAtPurchase = walletUser['hide_name_at_purchase'] ?? false;
        // استخدام المثال لتعيين المتغير
        _fullName = _buildMaskedFullName(walletUser);
      });
    }
  }

  Future<void> _togglePrivacySetting(String key, bool value) async {
    setState(() => _isLoadingPrivacy = true);
    try {
      await ApiService.updatePrivacySettings({key: value});
      setState(() {
        if (key == 'hide_name_at_transfer') {
          _hideNameAtTransfer = value;
        } else if (key == 'hide_name_at_purchase') {
          _hideNameAtPurchase = value;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث إعدادات الخصوصية بنجاح'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التحديث: $e')));
      }
    } finally {
      setState(() => _isLoadingPrivacy = false);
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final user = await ApiService.getCachedUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحديد المستخدم الحالي')),
        );
      }
      return;
    }
    final username = user['username'] ?? user['phone_number'];
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      // If enabling, we might want to verify once
      try {
        final authenticated = await _auth.authenticate(
          localizedReason: 'يرجى تأكيد هويتك لتفعيل الدخول بالبصمة',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (authenticated) {
          await prefs.setBool('biometrics_enabled_$username', true);
          setState(() => _isBiometricEnabled = true);
        }
      } catch (e) {
        customPrint('Error authenticating: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('فشل التحقق من البصمة')));
        }
      }
    } else {
      await prefs.setBool('biometrics_enabled_$username', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'privacy_security_title'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildSectionHeader('section_login_settings'.tr()),
                      const SizedBox(height: 12),
                      _buildSecurityItem(
                        title: 'change_password'.tr(),
                        subtitle: 'change_password_subtitle'.tr(),
                        icon: Icons.lock_outline_rounded,
                        onTap: () async {
                          if (!await ApiService.checkVerification(
                            context,
                            isDarkMode: widget.isDarkMode,
                            onVerifyNavigate:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AccountConfirmationScreen(
                                          isDarkMode: widget.isDarkMode,
                                        ),
                                  ),
                                ),
                          )) {
                            return;
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChangePasswordScreen(
                                    isDarkMode: widget.isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isBiometricAvailable)
                        _buildBiometricToggle()
                      else
                        _buildBiometricUnavailable(),

                      const SizedBox(height: 40),
                      _buildSectionHeader('section_additional_security'.tr()),
                      const SizedBox(height: 12),
                      _buildSecurityItem(
                        title: 'device_management'.tr(),
                        subtitle: 'device_management_subtitle'.tr(),
                        icon: Icons.devices_rounded,
                        onTap: () async {
                          if (!await ApiService.checkVerification(
                            context,
                            isDarkMode: widget.isDarkMode,
                            onVerifyNavigate:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AccountConfirmationScreen(
                                          isDarkMode: widget.isDarkMode,
                                        ),
                                  ),
                                ),
                          )) {
                            return;
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DeviceManagementScreen(
                                    isDarkMode: widget.isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                      _buildSectionHeader('section_privacy_settings'.tr()),
                      const SizedBox(height: 12),
                      _buildPrivacyToggle(
                        title: 'hide_name_at_transfer'.tr(),
                        subtitle: 'hide_name_at_transfer_subtitle'.tr(),
                        icon: Icons.person_off_outlined,
                        value: _hideNameAtTransfer,
                        onChanged:
                            (val) => _togglePrivacySetting(
                              'hide_name_at_transfer',
                              val,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildPrivacyToggle(
                        title: 'hide_name_at_purchase'.tr(),
                        subtitle: 'hide_name_at_purchase_subtitle'.tr(),
                        icon: Icons.shopping_bag_outlined,
                        value: _hideNameAtPurchase,
                        onChanged:
                            (val) => _togglePrivacySetting(
                              'hide_name_at_purchase',
                              val,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildPremiumHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.accentBlue,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ).animate().fade().slideX(begin: 0.1);
  }

  Widget _buildSecurityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white60 : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios_rounded,
          size: 16,
          color: Colors.grey,
        ),
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildBiometricToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fingerprint_rounded, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'biometric_authentication'.tr(),
                  style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'biometric_subtitle'.tr(),
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white60 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isBiometricEnabled,
            activeColor: AppColors.accentBlue,
            onChanged: _toggleBiometrics,
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildBiometricUnavailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'biometric_unavailable'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white60 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _fullName,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white60 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _isLoadingPrivacy
              ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Switch.adaptive(
                value: value,
                activeColor: AppColors.primaryBlue,
                onChanged: onChanged,
              ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.05);
  }

  String _buildMaskedFullName(Map<String, dynamic> walletUser) {
    String first = (walletUser['first_name'] ?? '').toString().trim();
    String second = (walletUser['second_name'] ?? '').toString().trim();
    String third = (walletUser['third_name'] ?? '').toString().trim();
    String last = (walletUser['last_name'] ?? '').toString().trim();

    String maskPart(String part) {
      if (part.isEmpty) return '';
      if (part.length == 1) return part;
      return part.characters.first + List.filled(part.length - 1, '*').join();
    }

    final parts =
        [
          maskPart(first),
          maskPart(second),
          maskPart(third),
          maskPart(last),
        ].where((p) => p.isNotEmpty).toList();

    return parts.join(' ');
  }
}
