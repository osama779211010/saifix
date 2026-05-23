import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'request_transfer_screen.dart';
import 'transfer_requests_report_screen.dart';

class ReceiveTransferRequestScreen extends StatelessWidget {
  final bool isDarkMode;

  const ReceiveTransferRequestScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'title': 'request_local_title'.tr()},
      {'title': 'request_international_title'.tr()},
      {'title': 'request_report_title'.tr()},
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
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.cardDark
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 
                                    isDarkMode ? 0.3 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                                            (context) => RequestTransferScreen(
                                              isDarkMode: isDarkMode,
                                              title: 'request_local_title'.tr(),
                                              services: [
                                                'service_saifi_cash'.tr(),
                                                'service_other_local'.tr(),
                                              ],
                                            ),
                                      ),
                                    );
                                  } else if (index == 1) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => RequestTransferScreen(
                                              isDarkMode: isDarkMode,
                                              title:
                                                  'request_international_title'
                                                      .tr(),
                                              services: [
                                                'service_saifi_cash'.tr(),
                                                'service_western_union'.tr(),
                                                'service_moneygram'.tr(),
                                                'service_express_money'.tr(),
                                                'service_shift'.tr(),
                                                'service_other_international'
                                                    .tr(),
                                              ],
                                            ),
                                      ),
                                    );
                                  } else if (index == 2) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                TransferRequestsReportScreen(
                                                  isDarkMode: isDarkMode,
                                                ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(18),
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
                                          items[index]['icon'] as IconData? ??
                                              Icons.inbox_rounded,
                                          color: AppColors.adaptiveIcon(
                                            isDarkMode,
                                          ),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          items[index]['title'],
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
            'request_receive_title'.tr(),
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
