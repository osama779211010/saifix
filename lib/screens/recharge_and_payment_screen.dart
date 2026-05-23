import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import 'recharge_and_payment/shahn_alraseed_screen.dart';
import 'recharge_and_payment/sadaad_baqat_screen.dart';
import 'recharge_and_payment/internet_fixed_phone_screen.dart';
import 'recharge_and_payment/yemen_4g/yemen_4g_services_screen.dart';
import 'recharge_and_payment/games_entertainment_screen.dart';

class RechargeAndPaymentScreen extends StatelessWidget {
  final bool isDarkMode;

  const RechargeAndPaymentScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'title': 'top_up_balance'.tr(), 'icon': Icons.phonelink_ring_rounded},
      {'title': 'payment_of_packages'.tr(), 'icon': Icons.sim_card_rounded},
      {'title': 'net_and_landline_phone'.tr(), 'icon': Icons.router_rounded},
      {'title': 'yemen_4G_Services'.tr(), 'icon': Icons.wifi_tethering_rounded},
      // {'title': 'water_and_electricity_bills'.tr(), 'icon': Icons.water_drop_rounded},
      // {'title': 'games_and_entertainment'.tr(), 'icon': Icons.sports_esports_rounded},
      // {'title': 'higher_education_and_universities'.tr(), 'icon': Icons.school_rounded},
    ];

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(isDarkMode),
          SafeArea(
            child: Column(
              children: [
                // _buildPremiumHeader(context, isDarkMode),
                _buildPremiumHeader(
                  'shipping_and_payment'.tr(),
                  () => Navigator.pop(context),
                ),
                // .animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                SizedBox(height: 10),

                // List of Services
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.cardDark
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 
                                    isDarkMode ? 0.2 : 0.03,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  dynamic targetScreen;
                                  if (index == 0) {
                                    targetScreen = ShahnAlraseedScreen(isDarkMode: isDarkMode);
                                  } else if (index == 1) {
                                    targetScreen = SadaadBaqatScreen(isDarkMode: isDarkMode);
                                  } else if (index == 2) {
                                    targetScreen = InternetFixedPhoneScreen(isDarkMode: isDarkMode);
                                  } else if (index == 3) {
                                    targetScreen = Yemen4GServicesScreen(isDarkMode: isDarkMode);
                                  } else if (index == 5) {
                                    targetScreen = GamesEntertainmentScreen(isDarkMode: isDarkMode);
                                  }

                                  if (targetScreen != null) {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => targetScreen),
                                    );
                                    if (result == true && context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : const Color(0xFFF1F4F9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          services[index]['icon'] as IconData,
                                          color: AppColors.adaptiveIcon(
                                            isDarkMode,
                                          ),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          services[index]['title'],
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF2D3748),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
              color: AppColors.accentBlue.withValues(alpha: isDarkMode ? 0.05 : 0.03),
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
              color: AppColors.accentBlue.withValues(alpha: isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
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

  // Widget _buildPremiumHeader(BuildContext context, bool isDarkMode) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //            const SizedBox(width: 48),
  //         Text(
  //           'shipping_and_payment'.tr(),
  //           style: TextStyle(
  //             color: isDarkMode ? Colors.white : AppColors.textBlack,
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         IconButton(
  //           icon: Icon(
  //             Icons.arrow_back_ios_rounded_rounded,
  //             color: isDarkMode ? Colors.white : AppColors.textBlack,
  //           ),
  //           onPressed: () => Navigator.pop(context),
  //         ),

  //       ],
  //     ),
  //   );
  // }
}
