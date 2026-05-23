import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    this.title = 'تنبيه',
    required this.message,
    this.buttonText = 'موافق',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return ErrorDialog(
          title: title ?? 'warning'.tr(),
          message: message,
          buttonText: buttonText ?? 'ok'.tr(),
          onDismiss: onDismiss,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Main Container
          Container(
            margin: const EdgeInsets.only(top: 45),
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon & Title
                // Container(
                //   padding: const EdgeInsets.all(8),
                //   decoration: BoxDecoration(
                //     color: AppColors.errorRed.withValues(alpha: 0.1),
                //     shape: BoxShape.circle,
                //   ),
                //   child: const Icon(
                //     Icons.error_outline_rounded,
                //     color: AppColors.errorRed,
                //     size: 28,
                //   ),
                // ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryBlue,
                    ),
                  ),
                ),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //  ],
                // ),
                const SizedBox(height: 20),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color:
                        isDark
                            ? AppColors.textGreyDark
                            : AppColors.textBlack.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    if (onDismiss != null) onDismiss!();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      buttonText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logo Circle
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.scaffoldDark : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: AppColors.logoGradientDay,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: const AssetImage('logo_circle.png'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
