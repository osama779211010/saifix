import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saifaicash_transfers/saificash_receive_transfer_screen.dart';
import 'saifaicash_transfers/saificash_status_enquiry_screen.dart';
import '../core/app_colors.dart';
import 'saifi_transfer/send_network_transfer_screen.dart';
import 'saifi_transfer/cancel_transfer_screen.dart';

class SaifiTransferScreen extends StatefulWidget {
  final bool isDarkMode;

  const SaifiTransferScreen({super.key, required this.isDarkMode});

  @override
  State<SaifiTransferScreen> createState() => _SaifiTransferScreenState();
}

class _SaifiTransferScreenState extends State<SaifiTransferScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'send_a_money_transfer_saifix'.tr(),
        'icon': Icons.forward_to_inbox_rounded,
      },
      // {'title': 'receiving_transfer'.tr(), 'icon': Icons.downloading_rounded},
      // {'title': 'transfer_status'.tr(), 'icon': Icons.fact_check_rounded},
      // {
      //   'title': 'cancel_transfer'.tr(),
      //   'icon': Icons.cancel_schedule_send_rounded,
      // },
      {
        'title': 'receive_saificash_transfer'.tr(),
        'icon': Icons.downloading_rounded,
      },
      {
        'title': 'enquire_saificash_transfer'.tr(),
        'icon': Icons.fact_check_rounded,
      },
    ];

    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'saifi_cash'.tr(),
                  () => Navigator.pop(context),
                ),
                // .animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color:
                                  widget.isDarkMode
                                      ? AppColors.cardDark
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 
                                    widget.isDarkMode ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  if (index == 0) {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                SendNetworkTransferScreen(
                                                  isDarkMode: widget.isDarkMode,
                                                  networkName:
                                                      'saifi_cash'.tr(),
                                                  networkLogo: 'pr_logo.png',
                                                ),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    }
                                  } else if (index == 1) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                SaificashReceiveTransferScreen(
                                                  isDarkMode: widget.isDarkMode,
                                                ),
                                      ),
                                    );
                                  } else if (index == 2) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                SaificashStatusEnquiryScreen(
                                                  isDarkMode: widget.isDarkMode,
                                                ),
                                      ),
                                    );
                                  } else if (index == 3) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CancelTransferScreen(
                                              isDarkMode: widget.isDarkMode,
                                            ),
                                      ),
                                    );
                                  } else if (index == 4) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                SaificashReceiveTransferScreen(
                                                  isDarkMode: widget.isDarkMode,
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
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white.withValues(alpha: 
                                                    0.05,
                                                  )
                                                  : const Color(0xFFF1F4F9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          options[index]['icon'] as IconData,
                                          color: AppColors.adaptiveIcon(
                                            widget.isDarkMode,
                                          ),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          options[index]['title'],
                                          style: GoogleFonts.cairo(
                                            color:
                                                widget.isDarkMode
                                                    ? Colors.white
                                                    : const Color(0xFF2D3748),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
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
                          // .fade(duration: 300.ms, delay: (index * 100).ms)
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
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  size: 18,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SvgPicture.asset(
              //   'Sp.svg',
              //   height: 24,
              //   width: 24,
              //   // color: AppColors.primaryBlue,
              //   errorBuilder:
              //       (context, error, stackTrace) =>
              //            Icon(Icons.wallet, color: AppColors.primaryBlue),
              // ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
