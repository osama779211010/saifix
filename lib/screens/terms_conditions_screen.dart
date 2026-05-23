import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

class TermsConditionsScreen extends StatefulWidget {
  final bool isDarkMode;

  /// يُستدعى عند الضغط على "أوافق" في نهاية الشروط
  final VoidCallback? onAccepted;

  const TermsConditionsScreen({
    super.key,
    required this.isDarkMode,
    this.onAccepted,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ينزل بسرعة إلى آخر القائمة
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final bgColor =
        isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight;

    return Scaffold(
      backgroundColor: bgColor,
      // زر النزول السريع العائم
      floatingActionButton: FloatingActionButton.small(
        onPressed: _scrollToBottom,
        backgroundColor: AppColors.accentBlue,
        tooltip: 'scroll_to_bottom'.tr(),
        child: const Icon(
          Icons.keyboard_double_arrow_down_rounded,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          _buildPremiumBackground(isDarkMode),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  context,
                  'terms_and_conditions_title'.tr(),
                  isDarkMode,
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Logo
                        Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      isDarkMode
                                          ? 'logo_circle.png'
                                          : 'pr_logo.png',
                                      height: 60,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'usage_and_privacy_policy'.tr(),
                                    style: GoogleFonts.cairo(
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : AppColors.primaryBlue,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'app_name_wallet'.tr(),
                                    style: GoogleFonts.cairo(
                                      color: AppColors.accentBlue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fade(delay: 200.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 30),

                        _buildSection(
                              'section_1_title'.tr(),
                              'section_1_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 300.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildSection(
                              'section_2_title'.tr(),
                              'section_2_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildSection(
                              'section_3_title'.tr(),
                              'section_3_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 500.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildSection(
                              'section_4_title'.tr(),
                              'section_4_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 600.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildSection(
                              'section_5_title'.tr(),
                              'section_5_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 700.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildSection(
                              'section_6_title'.tr(),
                              'section_6_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 800.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildSection(
                              'section_7_title'.tr(),
                              'section_7_content'.tr(),
                              isDarkMode,
                            )
                            .animate()
                            .fade(delay: 900.ms)
                            .slideY(begin: 0.1, end: 0),

                        Padding(
                              padding: const EdgeInsets.only(
                                bottom: 15,
                                top: 10,
                              ),
                              child: Text(
                                'section_8_title'.tr(),
                                style: GoogleFonts.cairo(
                                  color: AppColors.accentBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            .animate()
                            .fade(delay: 1000.ms)
                            .slideY(begin: 0.1, end: 0),

                        _buildPermissionItem(
                          'permission_contact_title'.tr(),
                          'permission_contact_desc'.tr(),
                          isDarkMode,
                        ).animate().fade(delay: 1100.ms),
                        _buildPermissionItem(
                          'permission_sms_title'.tr(),
                          'permission_sms_desc'.tr(),
                          isDarkMode,
                        ).animate().fade(delay: 1200.ms),
                        _buildPermissionItem(
                          'permission_location_title'.tr(),
                          'permission_location_desc'.tr(),
                          isDarkMode,
                        ).animate().fade(delay: 1300.ms),
                        _buildPermissionItem(
                          'permission_storage_title'.tr(),
                          'permission_storage_desc'.tr(),
                          isDarkMode,
                        ).animate().fade(delay: 1400.ms),

                        const SizedBox(height: 30),

                        // بطاقة الإقرار والموافقة
                        Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? AppColors.cardDark
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.primaryBlue,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'acknowledgment_title'.tr(),
                                    style: GoogleFonts.cairo(
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : AppColors.textBlack,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'acknowledgment_content'.tr(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      color:
                                          isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fade(delay: 1500.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // زر "أوافق على الشروط والأحكام" في الأسفل
                        if (widget.onAccepted != null)
                          Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.accentBlue,
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(alpha: 
                                        0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    widget.onAccepted!();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      55,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'accept_button'.tr(),
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fade(delay: 1600.ms)
                              .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 40),
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

  Widget _buildPremiumBackground(bool isDarkMode) {
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

  Widget _buildPremiumHeader(
    BuildContext context,
    String title,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
            style: GoogleFonts.cairo(
              color: isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: AppColors.accentBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.cairo(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 14,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 15),
          Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, String desc, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.cairo(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
