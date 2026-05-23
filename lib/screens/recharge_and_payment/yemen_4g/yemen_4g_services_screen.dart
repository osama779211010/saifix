import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/app_colors.dart';
import 'yemen_4g_packages_screen.dart';
import 'yemen_4g_credit_screen.dart';
import 'yemen_4g_change_package_screen.dart';

class Yemen4GServicesScreen extends StatelessWidget {
  final bool isDarkMode;
  const Yemen4GServicesScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'title': 'yemen_4g_packages'.tr(), 'icon': Icons.wifi_rounded},
      {
        'title': 'yemen_4g_call_credit'.tr(),
        'icon': Icons.phone_in_talk_rounded,
      },
      {
        'title': 'change_yemen_4g_packages'.tr(),
        'icon': Icons.change_circle_rounded,
      },
      {
        'title': 'change_and_pay_yemen_4g_internet_only'.tr(),
        'icon': Icons.wifi_tethering_rounded,
      },
      {
        'title': 'change_and_pay_yemen_4g_voice_only'.tr(),
        'icon': Icons.perm_phone_msg_rounded,
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
                _buildPremiumHeader(context),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (index == 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => Yemen4GPackagesScreen(
                                          isDarkMode: isDarkMode,
                                          title: items[index]['title'],
                                        ),
                                  ),
                                );
                              } else if (index == 1) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => Yemen4GCreditScreen(
                                          isDarkMode: isDarkMode,
                                          title: items[index]['title'],
                                        ),
                                  ),
                                );
                              } else if (index == 2 ||
                                  index == 3 ||
                                  index == 4) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => Yemen4GChangePackageScreen(
                                          isDarkMode: isDarkMode,
                                          title: item['title'],
                                        ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item['icon'],
                                      color: AppColors.primaryBlue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : AppColors.textBlack,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color:
                                        isDarkMode
                                            ? Colors.white24
                                            : Colors.black26,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      // .animate()
                      // .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                      // .slideX(begin: 0.2, end: 0);
                    },
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
              color: AppColors.primaryBlue.withValues(alpha: 
                isDarkMode ? 0.05 : 0.03,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDarkMode ? Colors.white : AppColors.textBlack,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'yemen_4g_services'.tr(),
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
}
