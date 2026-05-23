import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'change_password_screen.dart';
import 'device_management_screen.dart';
import 'privacy_security_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'account_confirmation_screen.dart';

class POSAccountScreen extends StatefulWidget {
  final bool isDarkMode;
  const POSAccountScreen({super.key, required this.isDarkMode});

  @override
  State<POSAccountScreen> createState() => _POSAccountScreenState();
}

class _POSAccountScreenState extends State<POSAccountScreen> {
  static const Color saifiNavy = Color(0xFF1F2D5D);

  Map<String, dynamic>? _userData;
  String _posNumber = '';
  String _posName = 'نقطة المبيعات';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = await ApiService.getMe(forceRefresh: true);
      if (mounted) {
        setState(() {
          _userData = data;
          _posNumber = prefs.getString('pos_number') ?? '';
          _posName =
              prefs.getString('pos_trade_name') ??
              (data['first_name'] ?? 'صاحب النقطة').toString();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color bg = isDark ? AppColors.scaffoldDark : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        children: [
                          _buildHeader(isDark),
                          const SizedBox(height: 20),
                          _buildProfileCard(isDark),
                          const SizedBox(height: 20),
                          _buildQRCard(isDark),
                          const SizedBox(height: 20),
                          _buildInfoCard(isDark),
                          const SizedBox(height: 20),
                          _buildSettingsSection(isDark),
                          const SizedBox(height: 20),
                          _buildLogoutButton(isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: saifiNavy.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: saifiNavy.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : saifiNavy,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'account_title'.tr(),
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : saifiNavy,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildProfileCard(bool isDark) {
    final String displayNum = _posNumber.isNotEmpty ? _posNumber : '-------';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [saifiNavy, Color(0xFF3B4D8D)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: saifiNavy.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _posName,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'pos_number_label'.tr(args: [displayNum]),
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: displayNum));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('pos_number_copied'.tr())),
                        );
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white54,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'pos_active_label'.tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQRCard(bool isDark) {
    // Use the POS number stored at login time
    final String posNum = _posNumber;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: saifiNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: saifiNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'pos_qr_title'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : saifiNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (posNum.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: 'POS:$posNum',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                embeddedImage: const AssetImage('logo_circle.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(35, 35),
                ),
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: saifiNavy,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: saifiNavy,
                ),
                errorStateBuilder: (cxt, err) {
                  return Center(
                    child: Text(
                      'qr_generation_error'.tr(),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_rounded,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'pos_number_not_set'.tr(),
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'scan_instruction'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoCard(bool isDark) {
    final String phone = _userData?['phone_number'] ?? '-';
    final String username = _userData?['username'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account_info'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : saifiNavy,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow(isDark, Icons.phone_rounded, 'phone_label'.tr(), phone),
          const Divider(height: 24),
          _infoRow(
            isDark,
            Icons.person_rounded,
            'username_label'.tr(),
            username,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _infoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: saifiNavy.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    final items = [
      {
        'title': 'change_password_title'.tr(),
        'subtitle': 'change_password_subtitle'.tr(),
        'icon': Icons.lock_outline_rounded,
        'color': Colors.blue,
        'onTap': () async {
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

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChangePasswordScreen(isDarkMode: widget.isDarkMode),
              ),
            );
          }
        },
      },
      {
        'title': 'device_management_title'.tr(),
        'subtitle': 'device_management_subtitle'.tr(),
        'icon': Icons.phonelink_setup_rounded,
        'color': Colors.purple,
        'onTap': () async {
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

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => DeviceManagementScreen(isDarkMode: widget.isDarkMode),
              ),
            );
          }
        },
      },
      {
        'title': 'privacy_security_title'.tr(),
        'subtitle': 'privacy_security_subtitle'.tr(),
        'icon': Icons.security_rounded,
        'color': Colors.teal,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PrivacySecurityScreen(isDarkMode: widget.isDarkMode),
              ),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'settings_title'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : saifiNavy,
            ),
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final int i = entry.key;
          final Map item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
                  onTap: item['onTap'] as VoidCallback,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.05,
                          ),
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
                            color: (item['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                item['subtitle'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: (350 + i * 60).ms)
                .slideX(begin: 0.05, end: 0),
          );
        }),
      ],
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showConfirmLogoutDialog(isDark),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Text(
              'logout'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Future<void> _showConfirmLogoutDialog(bool isDark) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDark ? AppColors.cardDark : Colors.white,
            elevation: 10,
            shadowColor: saifiNavy.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(
                color:
                    isDark
                        ? Colors.white10
                        : saifiNavy.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with subtle glow effect
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : saifiNavy.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    isDark ? 'pr_logo.png' : 'logo_circle.png',
                    height: 70,
                    width: 70,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.logout_rounded,
                          size: 50,
                          color: saifiNavy,
                        ),
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                Text(
                  'logout'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  'msg_logout'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textGreyLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          await ApiService.logout();
                          sessionManager.stopSession();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saifiNavy,
                          elevation: 4,
                          shadowColor: saifiNavy.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'ok'.tr(),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                        ),
                        child: Text(
                          'cancel'.tr(),
                          style: GoogleFonts.cairo(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
