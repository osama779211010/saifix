import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';

class TransferStatusScreen extends StatefulWidget {
  final bool isDarkMode;
  const TransferStatusScreen({super.key, required this.isDarkMode});

  @override
  State<TransferStatusScreen> createState() => _TransferStatusScreenState();
}

class _TransferStatusScreenState extends State<TransferStatusScreen> {
  final _transferIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
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
                    'transfer_status_title'.tr(),
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
                                  Icons.info_outline_rounded,
                                  color: AppColors.adaptiveIcon(
                                    widget.isDarkMode,
                                  ),
                                  size: 24,
                                ),
                              ),
                            )
                            .animate()
                            .scale(duration: 400.ms, curve: Curves.easeOutBack)
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 40),

                        // Transfer ID Input
                        TextField(
                          controller: _transferIdController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.white
                                    : AppColors.textBlack,
                            fontSize: 14,
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
                              borderSide: BorderSide(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                              ),
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
                                onPressed: () {
                                  // Logic
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
}
