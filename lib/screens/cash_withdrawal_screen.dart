import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import 'cash_withdrawal/cash_withdrawal_request_screen.dart';
import 'locations_view_screen.dart';

class CashWithdrawalScreen extends StatelessWidget {
  final bool isDarkMode;

  const CashWithdrawalScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'cash_withdrawal_request'.tr(),
        'icon': Icons.outbox_rounded,
        'color': AppColors.accentBlue,
        'screen': (bool dm) => CashWithdrawalRequestScreen(isDarkMode: dm),
      },
      // {
      //   'title': '${"withdrawal_ATM".tr()} YKB',
      //   'icon': Icons.atm_rounded,
      //   'color': AppColors.accentBlue,
      //   'screen': (bool dm) => YKBAtmWithdrawalScreen(isDarkMode: dm),
      // },
      // {
      //   'title': '${"withdrawal_ATM".tr()} كاك بنك',
      //   'icon': Icons.account_balance_rounded,
      //   'color': AppColors.accentBlue,
      //   'screen': (bool dm) => CACBankAtmWithdrawalScreen(isDarkMode: dm),
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
                _buildPremiumHeader(
                  'cash_withdrawal'.tr(),
                  () => Navigator.pop(context),
                ),
                // .animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        children: [
                          // مواقع الصرافات
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LocationsViewScreen(
                                            isDarkMode: isDarkMode,
                                          ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.white24
                                                  : AppColors.adaptiveIcon(
                                                    isDarkMode,
                                                  ).withValues(alpha: 0.5),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.map_outlined,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : AppColors.primaryBlue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'locations_ATM'.tr(),
                                            style: TextStyle(
                                              color:
                                                  isDarkMode
                                                      ? Colors.white
                                                      : AppColors.adaptiveIcon(
                                                        isDarkMode,
                                                      ),
                                              fontSize: 12,

                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // .animate()
                                    // .fade(duration: 400.ms, delay: 200.ms)
                                    // .slideY(begin: 0.1, end: 0),
                              ),
                            ),
                          ),

                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? AppColors.cardDark
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.white.withValues(alpha: 
                                                    0.05,
                                                  )
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
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        options[index]['screen'](
                                                          isDarkMode,
                                                        ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 14,
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
                                                    options[index]['icon'] as IconData,
                                                    color: AppColors.adaptiveIcon(
                                                      isDarkMode,
                                                    ),
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                                Expanded(
                                                  child: Text(
                                                    options[index]['title'],
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
                                    // .animate()
                                    // .fade(
                                    //   duration: 400.ms,
                                    //   delay: (250 + (index * 50)).ms,
                                    // )
                                    // .slideX(begin: 0.1, end: 0);
                              },
                            ),
                          ),
                        ],
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
                color: AppColors.adaptiveIcon(isDarkMode).withValues(alpha: 0.05),
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
                color: AppColors.adaptiveIcon(isDarkMode).withValues(alpha: 0.05),
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
