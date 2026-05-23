import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class DetailItem {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;
  DetailItem({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });
}

class TransactionDetailsBottomSheet extends StatelessWidget {
  final bool isDarkMode;
  final String amount;
  final String currency;
  final String transactionType;
  final String recipientName;
  final String recipientId;
  final String? recipientLabel;
  final String? exchangeRate;
  final String? receiveAmount;
  final String? fee;
  final String? totalAmount;
  final String? senderName;
  final String? senderId;
  final String? networkName;
  final List<DetailItem>? details;
  final VoidCallback onExecute;

  const TransactionDetailsBottomSheet({
    super.key,
    required this.isDarkMode,
    required this.amount,
    required this.currency,
    required this.transactionType,
    required this.recipientName,
    required this.recipientId,
    this.recipientLabel,
    this.exchangeRate,
    this.receiveAmount,
    this.fee,
    this.totalAmount,
    this.senderName,
    this.senderId,
    this.networkName,
    this.details,
    required this.onExecute,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    required String amount,
    required String currency,
    required String transactionType,
    required String recipientName,
    required String recipientId,
    String? recipientLabel,
    String? exchangeRate,
    String? receiveAmount,
    String? fee,
    String? totalAmount,
    String? senderName,
    String? senderId,
    String? networkName,
    List<DetailItem>? details,
    required VoidCallback onExecute,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TransactionDetailsBottomSheet(
            isDarkMode: isDarkMode,
            amount: amount,
            currency: currency,
            transactionType: transactionType,
            recipientName: recipientName,
            recipientId: recipientId,
            recipientLabel: recipientLabel,
            exchangeRate: exchangeRate,
            receiveAmount: receiveAmount,
            fee: fee,
            totalAmount: totalAmount,
            senderName: senderName,
            senderId: senderId,
            networkName: networkName,
            details: details,
            onExecute: onExecute,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textBlack;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final dividerColor = isDarkMode ? Colors.white10 : Colors.grey[200];

    final bool isExchange = exchangeRate != null;
    final String displayAmount =
        isExchange ? (receiveAmount ?? amount) : (totalAmount ?? amount);
    String currencycode = 'YER';
    switch (currency) {
      case 'YER':
        currencycode = 'ريال يمني';
        break;
      case 'USD':
        currencycode = 'دولار';
        break;
      case 'SAR':
        currencycode = 'ريال سعودي';
        break;
      default:
        currencycode = 'ريال يمني';
        break;
    }
    final String displayCurrency =
        isExchange ? (receiveAmount != null ? "" : currency) : currencycode;
    // final String displayCurrency =
    //     isExchange ? (receiveAmount != null ? "" : currency) : currencycode;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textColor),
              ),
              Text(
                'بيانات الحركة',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  // fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          SizedBox(),

          // Main Amount Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                if (isExchange)
                  if (!isExchange && totalAmount != null)
                    Text(
                      'المبلغ الإجمالي',
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayAmount,
                      style: TextStyle(
                        color: isExchange ? AppColors.primaryBlue : textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (displayCurrency.isNotEmpty) const SizedBox(width: 5),
                    if (displayCurrency.isNotEmpty)
                      Text(
                        displayCurrency,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    // if (displayCurrency.isNotEmpty) const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Rows with Dividers
          _buildDetailRow(
            'العملية',
            networkName != null
                ? '$transactionType عبر $networkName'
                : transactionType,
            textColor,
            secondaryTextColor,
            dividerColor!,
          ),

          // Fee right after Amount/Process
          if (fee != null)
            _buildDetailRow(
              'العمولة',
              fee!,
              AppColors.primaryBlue,
              secondaryTextColor,
              dividerColor,
            ),

          if (!isExchange && senderName != null)
            _buildDetailRow(
              'المودع',
              '$senderName\n${senderId ?? ""}',
              textColor,
              secondaryTextColor,
              dividerColor,
            ),

          if (!isExchange && recipientName.isNotEmpty)
            _buildDetailRow(
              recipientLabel ?? 'المستفيد',
              '$recipientName\n$recipientId',
              textColor,
              secondaryTextColor,
              dividerColor,
            ),

          if (isExchange && exchangeRate != null)
            _buildDetailRow(
              'سعر الصرف',
              exchangeRate!,
              textColor,
              secondaryTextColor,
              dividerColor,
            ),

          // Additional Details
          if (details != null)
            ...details!.map(
              (d) => _buildDetailRow(
                d.label,
                d.value,
                d.color ?? textColor,
                secondaryTextColor,
                dividerColor,
                isBold: d.isBold,
              ),
            ),

          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Center(
              child: Text(
                'يرجى التحقق من البيانات  كون العملية لا يمكن إلغائها',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  // fontFamily: 'Cairo',
                ),
              ),
            ),
          ),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onExecute();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey[400]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color labelColor,
    Color dividerColor, {
    bool isBold = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: dividerColor, height: 1),
      ],
    );
  }
}
