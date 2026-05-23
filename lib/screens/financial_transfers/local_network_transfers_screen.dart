import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'select_local_network_screen.dart';
import 'receive_local_transfer_screen.dart';
import 'local_transfer_status_cancel_screen.dart';

class LocalNetworkTransfersScreen extends StatelessWidget {
  final bool isDarkMode;

  const LocalNetworkTransfersScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'title': 'send_local_transfer', 'icon': Icons.outbox_rounded},
      {'title': 'receive_local_transfer', 'icon': Icons.inbox_rounded},
      {'title': 'local_transfer_status', 'icon': Icons.fact_check_rounded},
      {
        'title': 'cancel_local_transfer',
        'icon': Icons.cancel_schedule_send_rounded,
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
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
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
                              borderRadius: BorderRadius.circular(15),
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
                                            (context) =>
                                                SelectLocalNetworkScreen(
                                                  isDarkMode: isDarkMode,
                                                ),
                                      ),
                                    );
                                  } else if (index == 1) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ReceiveLocalTransferScreen(
                                                  isDarkMode: isDarkMode,
                                                ),
                                      ),
                                    );
                                  } else if (index == 2) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                LocalTransferStatusCancelScreen(
                                                  isDarkMode: isDarkMode,
                                                  title:
                                                      'local_transfer_status'
                                                          .tr(),
                                                  icon:
                                                      Icons.fact_check_rounded,
                                                ),
                                      ),
                                    );
                                  } else if (index == 3) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (
                                              context,
                                            ) => LocalTransferStatusCancelScreen(
                                              isDarkMode: isDarkMode,
                                              title:
                                                  'cancel_local_transfer'.tr(),
                                              icon:
                                                  Icons
                                                      .cancel_schedule_send_rounded,
                                              rules: [
                                                'rule_cancel_after_24h'.tr(),
                                                'rule_cancel_from_your_wallet'
                                                    .tr(),
                                              ],
                                            ),
                                      ),
                                    );
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
                                          items[index]['icon'] as IconData,
                                          color: AppColors.adaptiveIcon(
                                            isDarkMode,
                                          ),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          items[index]['title'].toString().tr(),
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
            'local_transfers_title'.tr(),
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Refresh Button
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.adaptiveIcon(isDarkMode),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
