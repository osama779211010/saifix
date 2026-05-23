import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaScreen extends StatelessWidget {
  final bool isDarkMode;

  const SocialMediaScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> socialLinks = [
      {
        'name': 'facebook'.tr(),
        'icon': 'assets/images/networks/facebook.webp',
        'color': const Color(0xFF1877F2),
        'url': 'https://www.facebook.com/alsaifiex/',
      },
      {
        'name': 'instgram'.tr(),
        'icon': 'assets/images/networks/instgram.jpg',
        'color': const Color(0xFFE4405F),
        'url': 'https://www.instagram.com/alsaifiex/',
      },
      {
        'name': 'tek_tok',
        'icon': 'assets/images/networks/tek tok.jpg',
        'color': const Color(0xFF000000),
        'url': 'https://www.tiktok.com/@alsaifiex',
      },
      {
        'name': 'youtube'.tr(),
        'icon': 'assets/images/networks/youtube.png',
        'color': const Color(0xFFFF0000),
        'url': 'https://www.youtube.com/@alsaifico.forexchange1027',
      },
      {
        'name': 'x_app'.tr(),
        'icon': 'assets/images/networks/x.jpg',
        'color': const Color(0xFF000000),
        'url': 'https://x.com/alsaifiex_',
      },
      {
        'name': 'threads'.tr(),
        'icon': 'assets/images/networks/threads.png',
        'color': const Color(0xFF000000),
        'url': 'https://www.threads.com/@alsaifiex',
      },
    ];

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'socialmedia_app'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Logo Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'logo_circle.png',
                                  height: 80,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons
                                                .account_balance_wallet_rounded,
                                            size: 60,
                                            color: AppColors.primaryBlue,
                                          ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'my_app_name'.tr(),
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'official_social_media_accounts'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : AppColors.textBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Social Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: socialLinks.length,
                          itemBuilder: (context, index) {
                            final link = socialLinks[index];
                            return _buildSocialCard(link);
                          },
                        ),
                        const SizedBox(height: 40),
                        // Warning
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'msg_warrning_dont_us_another_wallet'.tr(),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.redAccent.shade100
                                            : Colors.red.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildSocialCard(Map<String, dynamic> link) {
    return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _launchUrl(link['url']),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: link['color'].withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        link['icon'] is IconData
                            ? Icon(link['icon'], color: link['color'], size: 30)
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                link['icon'],
                                height: 34,
                                width: 34,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.link_rounded,
                                      color: link['color'],
                                      size: 30,
                                    ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    link['name'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 500.ms, delay: 100.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.03),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentBlue.withValues(alpha: 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      customPrint('Could not launch $urlString');
    }
  }
}
