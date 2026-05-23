// import 'dart:io'; (Removed)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
// import 'package:path_provider/path_provider.dart'; (Removed)
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_colors.dart';
import '../../models/operation_history.dart';
import '../../helper/counvert_amunt_helper.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final bool isDarkMode;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    required this.isDarkMode,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();


  String _maskName(String? name) {
    if (name == null || name.trim().isEmpty || name == '-') return '';
    final parts = name.trim().split(' ');
    List<String> maskedParts = [];
    for (var p in parts) {
      if (p.length <= 2) {
        maskedParts.add('**');
      } else {
        maskedParts.add('${p.substring(0, p.length - 2)}**');
      }
    }
    return maskedParts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final type = t['type'] ?? 'unknown';
    final amount = t['amount'] ?? 0.0;
    final currency = t['currency'] ?? 'YER';
    final targetAmount = t['target_amount'];
    final targetCurrency = t['target_currency'];
    final exchangeRate = t['exchange_rate'];
    final dateValue = t['created_at'] ?? DateTime.now().toIso8601String();
    final refNo = t['reference_number'] ?? 'TRX-${t['id']}';
    final status = t['status'] ?? 'SUCCESS';
    final desc = t['description'] ?? '';
    final opType = t['operation_type'] ?? '';

    final String refLabel = OperationHistoryModel.remittanceTypes.contains(opType)
        ? 'remittance_number_label'.tr()
        : 'ref_label'.tr();

    final otherName = _maskName(t['other_party_name']?.toString());
    final otherPhone = t['other_party_phone']?.toString() ?? '';

    // Determine colors/icons
    Color statusColor = Colors.green;
    String typeText = 'transaction_type_operation'.tr();
    IconData typeIcon = Icons.cached;

    if (type == 'TRANSFER') {
      typeText = 'transaction_type_transfer'.tr();
      typeIcon = Icons.send_rounded;
      statusColor = Colors.orange;
    } else if (type == 'EXCHANGE') {
      typeText = 'transaction_type_exchange'.tr();
      typeIcon = Icons.currency_exchange_rounded;
      statusColor = Colors.green;
    } else if (type == 'DEPOSIT') {
      typeText = 'transaction_type_deposit'.tr();
      typeIcon = Icons.add_circle_outline_rounded;
      statusColor = Colors.blue;
    } else if (type == 'WITHDRAW') {
      typeText = 'transaction_type_withdrawal'.tr();
      typeIcon = Icons.remove_circle_outline_rounded;
      statusColor = Colors.red;
    }

    final dateFormatted = intl.DateFormat(
      'yyyy/MM/dd hh:mm a',
      'en_US',
    ).format(DateTime.parse(dateValue).toLocal());

    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode
                                  ? AppColors.cardDark
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 
                                widget.isDarkMode ? 0.3 : 0.05,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color:
                                widget.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header Status with Gradient
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withValues(alpha: 0.15),
                                    statusColor.withValues(alpha: 0.02),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      size: 50,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    typeText,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          widget.isDarkMode
                                              ? Colors.white
                                              : AppColors.textBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status == 'SUCCESS'
                                          ? 'status_success'.tr()
                                          : 'status_processing'.tr(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Amount Section
                            if (type == 'EXCHANGE' && targetAmount != null)
                              Column(
                                children: [
                                  Text(
                                    '${formatAmountDisplay(amount)} $currency',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                    size: 30,
                                  ),
                                  Text(
                                    '${formatAmountDisplay(targetAmount)} $targetCurrency',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  Text(
                                    'receipt_amount_label'.tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          widget.isDarkMode
                                              ? Colors.white54
                                              : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${formatAmountDisplay(amount)} $currency',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          widget.isDarkMode
                                              ? Colors.white
                                              : AppColors.textBlack,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                              ),
                              child: Divider(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                height: 1,
                              ),
                            ),

                            // Details List
                            _buildDetailRow(refLabel, refNo),
                            _buildDetailRow(
                              'date_time_label'.tr(),
                              dateFormatted,
                            ),
                            if (type == 'EXCHANGE' && exchangeRate != null) ...[
                              _buildDetailRow(
                                'exchange_rate_label'.tr(),
                                '1 $currency = $exchangeRate $targetCurrency',
                              ),
                              _buildDetailRow(
                                'sent_amount_label'.tr(),
                                '${formatAmountDisplay(amount)} $currency',
                              ),
                              _buildDetailRow(
                                'received_amount_label'.tr(),
                                '${formatAmountDisplay(targetAmount)} $targetCurrency',
                              ),
                            ],
                            if (otherName.isNotEmpty) ...[
                              _buildDetailRow(
                                'other_party_label'.tr(),
                                otherName,
                              ),
                              if (otherPhone.isNotEmpty)
                                _buildDetailRow(
                                  'other_party_phone_label'.tr(),
                                  otherPhone,
                                ),
                            ],
                            if (desc.isNotEmpty)
                              _buildDetailRow('description_label'.tr(), desc),

                            // Balance removed per user request
                            const SizedBox(height: 30),

                            // Footer Logo
                            Padding(
                              padding: const EdgeInsets.only(bottom: 25),
                              child: Opacity(
                                opacity: 0.6,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.adaptiveIcon(
                                          widget.isDarkMode,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(
                                        'pr_logo.png',
                                        errorBuilder:
                                            (_, __, ___) => Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              color: AppColors.adaptiveIcon(
                                                widget.isDarkMode,
                                              ),
                                              size: 20,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'receipt_brand'.tr(),
                                      style: TextStyle(
                                        fontSize: 12,
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
                            ),
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
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
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
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'operation_details_title'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: AppColors.adaptiveIcon(widget.isDarkMode),
                ),
                onPressed: _shareScreenshot,
              ),
              IconButton(
                icon: Icon(
                  Icons.print_rounded,
                  color: AppColors.adaptiveIcon(widget.isDarkMode),
                ),
                onPressed: () => _generatePdfAndPrint(widget.transaction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.01),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color:
                    widget.isDarkMode
                        ? AppColors.textGreyDark
                        : AppColors.textGreyLight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color:
                    widget.isDarkMode
                        ? AppColors.textWhite
                        : AppColors.textBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

 Future<void> _shareScreenshot() async {
  try {
    final Uint8List? imageBytes = await _screenshotController.capture();

    if (imageBytes != null && mounted) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              imageBytes,
              name: 'transaction_share.png',
              mimeType: 'image/png',
            ),
          ],
          text: 'share_transaction_text'.tr(),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'share_screenshot_error'.tr()}: $e')),
      );
    }
  }
}


  Future<void> _generatePdfAndPrint(Map<String, dynamic> t) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoMedium();
    final image = await rootBundle.load('pr_logo.png');
    final imageBytes = image.buffer.asUint8List();

    final type = t['type'] ?? 'unknown';
    String typeText = 'transaction_type_unknown'.tr();
    if (type == 'TRANSFER') {
      typeText = 'transaction_type_transfer'.tr();
    } else if (type == 'EXCHANGE') {
      typeText = 'transaction_type_exchange'.tr();
    } else if (type == 'DEPOSIT') {
      typeText = 'transaction_type_deposit'.tr();
    } else if (type == 'WITHDRAW') {
      typeText = 'transaction_type_withdraw'.tr();
    }



    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'نظام صيفي باي',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'تفاصيل العملية',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Image(pw.MemoryImage(imageBytes), width: 60, height: 60),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 30),

              // Summary
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      typeText,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    if (type == 'EXCHANGE' && t['target_amount'] != null) ...[
                      pw.Text(
                        '${formatAmountDisplay(t['amount'])} ${t['currency']} -> ${formatAmountDisplay(t['target_amount'])} ${t['target_currency']}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.ltr,
                      ),
                    ] else ...[
                      pw.Text(
                        '${formatAmountDisplay(t['amount'])} ${t['currency']}',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.ltr,
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Details Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: null,
                headerAlignment: pw.Alignment.centerRight,
                cellAlignment: pw.Alignment.centerRight,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
                cellStyle: pw.TextStyle(font: arabicFont),
                data: <List<String>>[
                  ['القيمة', 'البيان'],
                  [
                    t['reference_number'] ?? t['id'].toString(),
                    OperationHistoryModel.remittanceTypes.contains(t['operation_type'])
                        ? 'remittance_number_label'.tr()
                        : 'رقم المرجع'
                  ],
                  [
                    intl.DateFormat(
                      'yyyy/MM/dd hh:mm a',
                      'en_US',
                    ).format(DateTime.parse(t['created_at']).toLocal()),
                    'التاريخ',
                  ],
                  [
                    t['status'] == 'SUCCESS' ? 'ناجحة' : 'قيد المعالجة',
                    'الحالة',
                  ],
                  if (type == 'EXCHANGE' && t['target_amount'] != null) ...[
                    [
                      '${formatAmountDisplay(t['amount'])} ${t['currency']}',
                      'المبلغ المرسل',
                    ],
                    [
                      '${formatAmountDisplay(t['target_amount'])} ${t['target_currency']}',
                      'المبلغ المستلم',
                    ],
                    // [t['exchange_rate'].toString(), 'سعر الصرف'],
                  ],
                  if (t['other_party_name'] != null &&
                      t['other_party_name'].toString().isNotEmpty)
                    [
                      _maskName(t['other_party_name']?.toString()),
                      'الطرف الآخر',
                    ],
                  [t['description'] ?? '-', 'الوصف'],
                ],
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'نظام صيفي باي - خدمات مصرفية متكاملة',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Transaction_${t['reference_number'] ?? t['id']}.pdf',
    );
  
  }
}
