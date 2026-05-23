import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';

import 'internet_payment_screen.dart';

class InternetFixedPhoneScreen extends StatelessWidget {
  final bool isDarkMode;
  const InternetFixedPhoneScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'adsl_package_payment'.tr(),
        'imagePath': 'assets/images/networks/Yemen_Telc.png',
      },
      {
        'title': 'fixed_phone_bills'.tr(),
        'imagePath': 'assets/images/networks/Yemen_Telc.png',
      },
      {
        'title': 'ftth_fiber_internet'.tr(),
        'imagePath': 'assets/images/networks/Yemen_Telc.png',
      },
      // {
      //   'title': 'yemen_wifi'.tr(),
      //   'imagePath': 'assets/images/networks/Yemen_Telc.png',
      // },
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
                // .animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.cardDark
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 
                                    isDarkMode ? 0.3 : 0.05,
                                  ),
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
                                  int sc = 42105;
                                  int itemCode = 8;
                                  String itemTitle = items[index]['title'];

                                  if (index == 0) {
                                    sc = 42105;
                                    itemCode = 8;
                                  } else if (index == 1) {
                                    sc = 42106;
                                    itemCode = 9;
                                  } else if (index == 2) {
                                    sc = 42105;
                                    itemCode = 8;
                                  } else if (index == 3) {
                                    sc = 42105;
                                    itemCode = 8;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => InternetPaymentScreen(
                                            isDarkMode: isDarkMode,
                                            title: itemTitle,
                                            serviceCode: sc,
                                            itemCode: itemCode,
                                          ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Logo Container
                                      Container(
                                        width: 60,
                                        height: 40,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? Colors.white.withValues(alpha: 
                                                    0.05,
                                                  )
                                                  : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDarkMode
                                                    ? Colors.white10
                                                    : Colors.black.withValues(alpha: 
                                                      0.03,
                                                    ),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.asset(
                                            items[index]['imagePath'],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Title
                                      Expanded(
                                        child: Text(
                                          items[index]['title'],
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : AppColors.textBlack,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : AppColors.adaptiveIcon(
                                                  isDarkMode,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          // .animate()
                          // .fade(duration: 400.ms, delay: (index * 100).ms)
                          // .slideX(begin: 0.1, end: 0);
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

  Widget _buildPremiumBackground() {
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
              color: AppColors.adaptiveIcon(
                isDarkMode,
              ).withValues(alpha: isDarkMode ? 0.05 : 0.03),
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
              color: AppColors.adaptiveIcon(
                isDarkMode,
              ).withValues(alpha: isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDarkMode ? Colors.white : AppColors.textBlack,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'internet_fixed_phone_title'.tr(),
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }
}
