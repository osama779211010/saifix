import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // مكتبة التحريك
import '../core/app_colors.dart';
import 'financial_transfers/transfer_to_subscriber_screen.dart';
import 'financial_transfers/transfer_between_accounts_screen.dart';
import 'financial_transfers/local_network_transfers_screen.dart';
import 'financial_transfers/receive_transfer_request_screen.dart';

class FinancialTransfersScreen extends StatelessWidget {
  final bool isDarkMode;

  const FinancialTransfersScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // قائمة خدمات التحويلات المالية
    final List<Map<String, dynamic>> transferServices = [
      {'title': 'switch_shared_account'.tr(), 'icon': Icons.person_add_rounded},
      {
        'title': 'transfer_between_my_accounts'.tr(),
        'icon': Icons.sync_alt_rounded,
      },
      {'title': 'localNetworkTransfers'.tr(), 'icon': Icons.hub_rounded},
      {
        'title': 'receiveTransferRequestTitle'.tr(),
        'icon': Icons.description_rounded,
      },
      // {
      //   'title': 'banks_and_portfolios'.tr(),
      //   'icon': Icons.account_balance_rounded,
      // },
      // {
      //   'title': 'otherWalletTransferswasel'.tr(),
      //   'icon': Icons.account_balance_wallet_rounded,
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
                  'money_transfers'.tr(),
                  () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),

                // قائمة خيارات التحويل
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transferServices.length,
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
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.grey.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 
                                    isDarkMode ? 0.2 : 0.02,
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
                                                TransferToSubscriberScreen(
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
                                                TransferBetweenAccountsScreen(
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
                                                LocalNetworkTransfersScreen(
                                                  isDarkMode: isDarkMode,
                                                ),
                                      ),
                                    );
                                  } else if (index == 3) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ReceiveTransferRequestScreen(
                                                  isDarkMode: isDarkMode,
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
                                      // Icon Box (Right side in RTL)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? Colors.white.withValues(alpha: 
                                                    0.05,
                                                  )
                                                  : const Color(0xFFF1F4F9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          transferServices[index]['icon']
                                              as IconData,
                                          color: AppColors.adaptiveIcon(
                                            isDarkMode,
                                          ),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      // Text (Left side in RTL)
                                      Expanded(
                                        child: Text(
                                          transferServices[index]['title'],
                                          style: TextStyle(
                                            color:
                                                isDarkMode
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
                          // .fade(duration: 250.ms, delay: (index * 80).ms)
                          // .slideX(begin: 0.1, end: 0),
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
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
