import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import 'hassalaty_list_screen.dart';

class SaifiScreen extends StatelessWidget {
  final bool isDarkMode;

  const SaifiScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
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
                  'saifix'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 20),

                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Column(
                          children: [
                            // // بطاقة خدمة "فرقك"
                            // GestureDetector(
                            //       onTap: () {
                            //         Navigator.push(
                            //           context,
                            //           MaterialPageRoute(
                            //             builder:
                            //                 (context) => SaifiPocketMoneyScreen(
                            //                   isDarkMode: isDarkMode,
                            //                 ),
                            //           ),
                            //         );
                            //       },
                            //       child: Container(
                            //         padding: const EdgeInsets.all(20),
                            //         decoration: BoxDecoration(
                            //           color:
                            //               isDarkMode
                            //                   ? AppColors.cardDark
                            //                   : Colors.white,
                            //           borderRadius: BorderRadius.circular(15),
                            //           border: Border.all(
                            //             color:
                            //                 isDarkMode
                            //                     ? Colors.white.withValues(alpha: 0.05)
                            //                     : Colors.black.withValues(alpha: 
                            //                       0.05,
                            //                     ),
                            //           ),
                            //           boxShadow: [
                            //             BoxShadow(
                            //               color: Colors.black.withValues(alpha: 
                            //                 isDarkMode ? 0.2 : 0.03,
                            //               ),
                            //               blurRadius: 8,
                            //               offset: const Offset(0, 3),
                            //             ),
                            //           ],
                            //         ),
                            //         child: Row(
                            //           mainAxisAlignment:
                            //               MainAxisAlignment.spaceBetween,
                            //           children: [
                            //             // اسم الخدمة
                            //             Text(
                            //               'your_section'.tr(),
                            //               style: TextStyle(
                            //                 color:
                            //                     isDarkMode
                            //                         ? Colors.white
                            //                         : AppColors.textBlack,
                            //                 fontSize: 15,
                            //                 fontWeight: FontWeight.bold,
                            //               ),
                            //             ),
                            //             // أيقونة الخدمة
                            //             Container(
                            //               padding: const EdgeInsets.all(10),
                            //               decoration: BoxDecoration(
                            //                 color: AppColors.accentBlue
                            //                     .withValues(alpha: 0.1),
                            //                 borderRadius: BorderRadius.circular(
                            //                   12,
                            //                 ),
                            //               ),
                            //               child: Icon(
                            //                 Icons.pie_chart_rounded,
                            //                 color:
                            //                     isDarkMode
                            //                         ? Colors.white
                            //                         : AppColors.accentBlue,
                            //                 size: 24,
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     )
                            //     .animate()
                            //     .fade(duration: 400.ms, delay: 100.ms)
                            //     .slideX(begin: 0.1, end: 0),
                            // const SizedBox(height: 12),
                            // // بطاقة خدمة "الأسرة"
                            // GestureDetector(
                            //       onTap: () {
                            //         Navigator.push(
                            //           context,
                            //           MaterialPageRoute(
                            //             builder:
                            //                 (context) => FamilyScreen(
                            //                   isDarkMode: isDarkMode,
                            //                 ),
                            //           ),
                            //         );
                            //       },
                            //       child: Container(
                            //         padding: const EdgeInsets.all(20),
                            //         decoration: BoxDecoration(
                            //           color:
                            //               isDarkMode
                            //                   ? AppColors.cardDark
                            //                   : Colors.white,
                            //           borderRadius: BorderRadius.circular(15),
                            //           border: Border.all(
                            //             color:
                            //                 isDarkMode
                            //                     ? Colors.white.withValues(alpha: 0.05)
                            //                     : Colors.black.withValues(alpha: 
                            //                       0.05,
                            //                     ),
                            //           ),
                            //           boxShadow: [
                            //             BoxShadow(
                            //               color: Colors.black.withValues(alpha: 
                            //                 isDarkMode ? 0.2 : 0.03,
                            //               ),
                            //               blurRadius: 8,
                            //               offset: const Offset(0, 3),
                            //             ),
                            //           ],
                            //         ),
                            //         child: Row(
                            //           mainAxisAlignment:
                            //               MainAxisAlignment.spaceBetween,
                            //           children: [
                            //             // اسم الخدمة
                            //             Text(
                            //               'faimly'.tr(),
                            //               style: TextStyle(
                            //                 color:
                            //                     isDarkMode
                            //                         ? Colors.white
                            //                         : AppColors.textBlack,
                            //                 fontSize: 15,
                            //                 fontWeight: FontWeight.bold,
                            //               ),
                            //             ),
                            //             // أيقونة الخدمة
                            //             Container(
                            //               padding: const EdgeInsets.all(10),
                            //               decoration: BoxDecoration(
                            //                 color: AppColors.accentBlue
                            //                     .withValues(alpha: 0.1),
                            //                 borderRadius: BorderRadius.circular(
                            //                   12,
                            //                 ),
                            //               ),
                            //               child: Icon(
                            //                 Icons.people_rounded,
                            //                 color:
                            //                     isDarkMode
                            //                         ? Colors.white
                            //                         : AppColors.accentBlue,
                            //                 size: 24,
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     )
                            // .animate()
                            // .fade(duration: 400.ms, delay: 200.ms)
                            // .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 12),
                            // بطاقة خدمة "حصالتي"
                            GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => HassalatyListScreen(
                                              isDarkMode: isDarkMode,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
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
                                                : Colors.black.withValues(alpha: 
                                                  0.05,
                                                ),
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // اسم الخدمة
                                        Text(
                                          'hassalaty'.tr(),
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : AppColors.textBlack,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        // أيقونة الخدمة
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentBlue
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.savings_rounded,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : AppColors.accentBlue,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fade(duration: 400.ms, delay: 300.ms)
                                .slideX(begin: 0.1, end: 0),
                          ],
                        ),
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
}
