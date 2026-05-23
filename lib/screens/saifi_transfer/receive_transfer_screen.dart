import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../account_confirmation_screen.dart';

class ReceiveTransferScreen extends StatefulWidget {
  final bool isDarkMode;
  const ReceiveTransferScreen({super.key, required this.isDarkMode});

  @override
  State<ReceiveTransferScreen> createState() => _ReceiveTransferScreenState();
}

class _ReceiveTransferScreenState extends State<ReceiveTransferScreen> {
  final _transferIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors();

    return Scaffold(
      backgroundColor: colors.scaffoldColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode
                                  ? AppColors.cardDark
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                widget.isDarkMode
                                    ? Colors.white10
                                    : Colors.black12,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color:
                              widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.textBlack,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'receive_transfer_title'.tr(),
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
            ),

            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        // Service Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.download_for_offline_rounded,
                              color: AppColors.adaptiveIcon(widget.isDarkMode),
                              size: 24,
                            ),
                          ),
                        ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),

                        const SizedBox(height: 40),

                        // Notification Message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(right: 5, bottom: 15),
                          child: Text(
                            'receive_transfer_notice'.tr(),
                            style: TextStyle(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white70
                                      : AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Transfer ID Input
                        TextField(
                          controller: _transferIdController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: colors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                          decoration: InputDecoration(
                            hintText: 'transfer_id_hint'.tr(),
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.adaptiveIcon(
                                  widget.isDarkMode,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Help Text
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(
                            'enter_transfer_id_first'.tr(),
                            style: TextStyle(
                              color: colors.textColor.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Search Button
                        Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 
                                      0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!await ApiService.checkVerification(
                                    context,
                                    isDarkMode: widget.isDarkMode,
                                    onVerifyNavigate:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    AccountConfirmationScreen(
                                                      isDarkMode:
                                                          widget.isDarkMode,
                                                    ),
                                          ),
                                        ),
                                  )) {
                                    return;
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  'search_transfer'.tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ThemeColors _getThemeColors() {
    return ThemeColors(
      scaffoldColor: widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
      textColor:
          widget.isDarkMode
              ? Colors.white
              : AppColors.adaptiveIcon(widget.isDarkMode),
      borderColor: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
    );
  }
}

class ThemeColors {
  final Color scaffoldColor;
  final Color textColor;
  final Color borderColor;

  ThemeColors({
    required this.scaffoldColor,
    required this.textColor,
    required this.borderColor,
  });
}
