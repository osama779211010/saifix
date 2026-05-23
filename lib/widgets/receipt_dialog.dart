import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../core/app_colors.dart';
import '../components/error_dialog.dart';

class ReceiptRowData {
  final String label;
  final String value;
  final bool isCopyable;

  ReceiptRowData({
    required this.label,
    required this.value,
    this.isCopyable = false,
  });
}

class ReceiptDialog extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final String mainAmount;
  final String mainCurrency;
  final List<ReceiptRowData> details;
  final String? shareText;
  final Color? amountColor;
  final VoidCallback? onClose;

  const ReceiptDialog({
    super.key,
    required this.isDarkMode,
    this.title = 'ايصال العملية',
    required this.mainAmount,
    required this.mainCurrency,
    required this.details,
    this.shareText,
    this.amountColor,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    String title = 'ايصال العملية',
    required String mainAmount,
    required String mainCurrency,
    required List<ReceiptRowData> details,
    String? shareText,
    Color? amountColor,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ReceiptDialog(
              isDarkMode: isDarkMode,
              title: title,
              mainAmount: mainAmount,
              mainCurrency: mainCurrency,
              details: details,
              shareText: shareText,
              amountColor: amountColor,
              onClose: onClose,
            ),
          ),
    ).then((_) {
      if (onClose != null) onClose();
    });
  }

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final Set<String> _copiedValues = {};
  String? _currentlyCopying;
  bool isSave = false;

  String _formatMainCurrency(String code) {
    switch (code.toUpperCase()) {
      case 'YER':
        return 'ريال يمني';
      case 'SAR':
        return 'ريال سعودي';
      case 'USD':
        return 'دولار';
      default:
        return code;
    }
  }

  String _formatDetailValue(String value) {
    String formatted = value;
    formatted = formatted.replaceAll('YER', 'ر.ي');
    formatted = formatted.replaceAll('SAR', 'ر.س');
    formatted = formatted.replaceAll('USD', 'دولار');
    return formatted;
  }

  Widget _buildReceiptContent() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_circle.png',
              height: 70,
              errorBuilder:
                  (context, error, stackTrace) => Icon(
                    Icons.account_balance_wallet,
                    size: 70,
                    color: AppColors.primaryBlue,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.mainAmount,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.amountColor ?? const Color(0xFF1F2D5D),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatMainCurrency(widget.mainCurrency),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...widget.details.map(
              (item) => _buildDetailRow(context, item, isForScreenshot: true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري تحضير الإيصال للمشاركة...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final Uint8List imageBytes = await _screenshotController
          .captureFromWidget(
            _buildReceiptContent(),
            delay: const Duration(milliseconds: 500),
            pixelRatio: 2.0,
            context: context,
          );

      if (context.mounted) {
        final directory = await getTemporaryDirectory();
        final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.png';
        final imagePath = '${directory.path}/$fileName';
        final imageFile = File(imagePath);

        await imageFile.writeAsBytes(imageBytes, flush: true);

        await Future.delayed(const Duration(milliseconds: 300));

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath, mimeType: 'image/png')],
            text:
                'صيفي باي تغنيك عن الجميع \n قم بتحميل صيفي باي \n https://alsaifiex.com/',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDialog.show(context, message: 'حدث خطأ أثناء المشاركة: $e');
      }
      try {
        if (widget.shareText != null && widget.shareText!.trim().isNotEmpty) {
          await SharePlus.instance.share(ShareParams(text: widget.shareText!));
        }
      } catch (_) {}
    }
  }

  Future<void> _saveReceipt(BuildContext context) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      if (!context.mounted) return;
      final Uint8List imageBytes = await _screenshotController
          .captureFromWidget(
            _buildReceiptContent(),
            delay: const Duration(milliseconds: 300),
            pixelRatio: 2.0,
            context: context,
          );

      await Gal.putImageBytes(imageBytes, album: 'Saifi Pay');

      if (context.mounted) {
        setState(() {
          isSave = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ الإيصال بنجاح في مجلد Saifi Pay في الاستوديو',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDialog.show(context, message: 'خطأ في حفظ السند: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_circle.png',
                    height: 70,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          Icons.account_balance_wallet,
                          size: 70,
                          color: AppColors.primaryBlue,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode
                              ? Colors.grey.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.mainAmount,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                widget.amountColor ?? const Color(0xFF1F2D5D),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatMainCurrency(widget.mainCurrency),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  ...widget.details.map(
                    (item) => _buildDetailRow(context, item),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon:
                      isSave ? Icons.check_box_rounded : Icons.download_rounded,
                  label: 'حفظ',
                  onTap: () => _saveReceipt(context),
                  color: isSave ? Colors.green : AppColors.primaryBlue,
                  bgColor:
                      isSave
                          ? Colors.green.withValues(alpha: 0.1)
                          : AppColors.primaryBlue.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 40),
                _buildActionButton(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  onTap: () => _shareReceipt(context),
                  color: AppColors.primaryBlue,
                  bgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    ReceiptRowData item, {
    bool isForScreenshot = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap:
                      (!isForScreenshot && item.isCopyable)
                          ? () {
                            Clipboard.setData(ClipboardData(text: item.value));
                            setState(() {
                              _copiedValues.add(item.value);
                              _currentlyCopying = item.value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم النسخ بنجاح'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDetailValue(item.value),
                            textAlign: TextAlign.end,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.isDarkMode
                                      ? Colors.white
                                      : AppColors.textBlack,
                            ),
                          ),
                        ),
                        if (!isForScreenshot && item.isCopyable) ...[
                          const SizedBox(width: 8),
                          Icon(
                            _currentlyCopying == item.value
                                ? Icons.download_done_rounded
                                : Icons.copy_rounded,
                            size: 18,
                            color:
                                _currentlyCopying == item.value
                                    ? Colors.green
                                    : (widget.isDarkMode
                                        ? Colors.white54
                                        : Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color bgColor,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
          ),
        ),
      ],
    );
  }
}
