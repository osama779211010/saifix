import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import 'change_password_screen.dart';
import 'device_management_screen.dart';
import 'privacy_security_screen.dart';

class POSSettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  const POSSettingsScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final bool isDark = isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'settings_title'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSettingsItem(
                        context,
                        title: 'change_password'.tr(),
                        subtitle: 'change_password_subtitle'.tr(),
                        icon: Icons.lock_outline_rounded,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChangePasswordScreen(
                                    isDarkMode: isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSettingsItem(
                        context,
                        title: 'device_management'.tr(),
                        subtitle: 'device_management_subtitle'.tr(),
                        icon: Icons.phonelink_setup_rounded,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DeviceManagementScreen(
                                    isDarkMode: isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSettingsItem(
                        context,
                        title: 'privacy_security'.tr(),
                        subtitle: 'privacy_security_subtitle'.tr(),
                        icon: Icons.security_rounded,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PrivacySecurityScreen(
                                    isDarkMode: isDarkMode,
                                  ),
                            ),
                          );
                        },
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
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDarkMode ? Colors.white : AppColors.textBlack,
                  size: 18,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDarkMode ? Colors.white54 : Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 100.ms).slideX(begin: 0.05, end: 0);
  }
}
