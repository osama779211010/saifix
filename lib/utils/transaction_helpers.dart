import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/operation_history.dart';
import '../widgets/receipt_dialog.dart';
import '../helper/counvert_amunt_helper.dart';

class TransactionHelpers {
  static String getDetailedTitle(Map<String, dynamic> transaction) {
    final type =
        transaction['transaction_type']?.toString().toLowerCase() ??
        transaction['type']?.toString().toLowerCase() ??
        '';
    final direction = transaction['direction']?.toString().toUpperCase() ?? '';
    final serviceName = transaction['service_name']?.toString() ?? '';
    final providerName = transaction['provider_name']?.toString() ?? '';
    final agentName = transaction['agent_name']?.toString() ?? '';
    final description = transaction['description']?.toString() ?? '';
    final backendTitle = transaction['title']?.toString() ?? '';

    // P2P Transfers from Accounting Journal Entries
    if (description.contains('P2P') ||
        description.contains('تحويل من') ||
        description.contains('تحويل إلى') ||
        description.contains('تحويل داخلي')) {
      if (type == 'withdraw' ||
          type == 'withdrawal' ||
          direction == 'OUT' ||
          description.contains('خصم')) {
        return 'تحويل الى مشترك';
      } else {
        return 'استلام من مشترك';
      }
    }

    // Network Transfers (Remittances) - e.g. Saifi Cash
    if (serviceName == 'SAIFI_CASH' ||
        backendTitle.contains('حوالة') ||
        description.contains('حوالة')) {
      final networkName =
          serviceName == 'SAIFI_CASH'
              ? 'صيفي كاش'
              : (serviceName.isNotEmpty ? serviceName : 'الشبكة');
      if (direction == 'IN' ||
          description.contains('استلام') ||
          description.contains('إيداع')) {
        return 'إستلام حوالة من $networkName';
      } else {
        return 'إرسال حوالة عبر $networkName';
      }
    }

    // إيداع حصالة / فتح حصالة / مقابل قسمك
    if (description.contains('حصالة') ||
        serviceName.contains('HASSALA') ||
        backendTitle.contains('حصالة')) {
      if (description.contains('فتح') || backendTitle.contains('فتح')) {
        return 'فتح حصاله';
      }
      if (type == 'withdraw' || type == 'withdrawal' || direction == 'OUT') {
        // Out of wallet -> Into Hassala
        return 'إيداع حصالة';
      }
      // Into wallet -> From Hassala (e.g. Breaking the Hassala)
      return 'كسر حصالة';
    }

    if (description.contains('قسمك') || backendTitle.contains('قسمك')) {
      return 'مقابل قسمك';
    }

    // Fallback Transfers
    if (type == 'transfer') {
      if (serviceName.isNotEmpty && serviceName != 'INTERNAL') {
        final networkName =
            serviceName == 'SAIFI_CASH' ? 'صيفي كاش' : serviceName;
        if (direction == 'IN') {
          return 'إستلام حوالة من $networkName';
        } else {
          return 'إرسال حوالة عبر $networkName';
        }
      } else {
        if (direction == 'IN') {
          return 'إستلام من مشترك';
        } else {
          return 'تحويل الى مشترك';
        }
      }
    }

    // Exchange
    if (type == 'exchange' ||
        description.contains('صرف') ||
        description.contains('مصارفة') ||
        backendTitle.contains('صرف')) {
      return 'مصارفة عملة';
    }

    // Payments / Recharge
    if (type == 'payment' ||
        description.contains('سداد') ||
        description.contains('شحن') ||
        backendTitle.contains('سداد') ||
        backendTitle.contains('شحن')) {
      if (serviceName == 'YEMEN_4G' ||
          backendTitle.contains('4G') ||
          description.contains('4G')) {
        return 'سداد يمن 4G';
      }
      if (serviceName == 'LANDLINE' ||
          backendTitle.contains('الهاتف') ||
          backendTitle.contains('الثابت') ||
          description.contains('الهاتف') ||
          description.contains('الثابت')) {
        return 'سداد الهاتف الثابت';
      }
      if (serviceName == 'GAMES' ||
          backendTitle.contains('ألعاب') ||
          backendTitle.contains('العاب') ||
          description.contains('العاب')) {
        return 'سداد الالعاب';
      }
      if (serviceName == 'PACKAGES' ||
          backendTitle.contains('باقات') ||
          description.contains('باقات')) {
        return 'سداد باقات';
      }

      // Try to extract provider from description if it's "يمن موبايل", "يو", "سبأفون" etc.
      String provider =
          providerName.isNotEmpty
              ? providerName
              : (serviceName.isNotEmpty ? serviceName : 'المزود');
      if (description.contains('يمن موبايل')) {
        provider = 'يمن موبايل';
      } else if (description.contains('يو') || description.contains('YOU')) {
        provider = 'يو';
      } else if (description.contains('سبأفون') || description.contains('سبافون')) {
        provider = 'سبأفون';
      } else if (description.contains('واي')) {
        provider = 'واي';
      }

      if (serviceName == 'RECHARGE' ||
          backendTitle.contains('شحن') ||
          backendTitle.contains('رصيد') ||
          description.contains('شحن') ||
          description.contains('رصيد')) {
        return 'شحن رصيد من $provider';
      }

      // Fallback for payment
      return 'سداد عبر $provider';
    }

    // Purchases
    if (type == 'purchase' ||
        serviceName == 'MERCHANT_PAYMENT' ||
        backendTitle.contains('مشتريات') ||
        description.contains('مشتريات')) {
      return 'دفع مشتريات';
    }

    // Withdrawals
    if (type == 'withdrawal' || type == 'withdraw') {
      final agent =
          agentName.isNotEmpty
              ? agentName
              : (serviceName.isNotEmpty ? serviceName : 'الوكيل');
      return 'سحب نقدي عبر $agent';
    }

    // Deposit
    if (type == 'deposit') {
      return 'إيداع';
    }

    // Fallback
    if (backendTitle.isNotEmpty) {
      return backendTitle;
    }

    return 'عملية';
  }

  static IconData getTransactionIcon(String type) {
    final t = type.toLowerCase();
    if (t == 'exchange') return Icons.currency_exchange_rounded;
    if (t == 'transfer') return Icons.send_rounded;
    if (t == 'deposit') return Icons.add_circle_outline_rounded;
    if (t == 'withdrawal' || t == 'withdraw') {
      return Icons.remove_circle_outline_rounded;
    }
    if (t == 'payment') return Icons.payment_rounded;
    if (t == 'purchase') return Icons.shopping_bag_rounded;
    return Icons.swap_horiz_rounded;
  }

  static Color getTransactionColor(String type) {
    final t = type.toLowerCase();
    if (t == 'exchange') return Colors.green;
    if (t == 'transfer') return Colors.orange;
    if (t == 'deposit') return Colors.blue;
    if (t == 'withdrawal' || t == 'withdraw') return Colors.red;
    if (t == 'payment') return Colors.purple;
    if (t == 'purchase') return Colors.teal;
    return Colors.grey;
  }

  static void showTransactionReceipt(
    BuildContext context,
    Map<String, dynamic> transaction,
    bool isDarkMode,
  ) {


    final type =
        transaction['transaction_type']?.toString().toLowerCase() ??
        transaction['type']?.toString().toLowerCase() ??
        'unknown';
    final amount = transaction['amount'] ?? 0.0;
    final currency = transaction['currency'] ?? 'YER';
    final targetAmount = transaction['target_amount'];
    final targetCurrency = transaction['target_currency'];
    final exchangeRate = transaction['exchange_rate'];
    final dateValue =
        transaction['created_at'] ?? DateTime.now().toIso8601String();
    final refNo = transaction['reference_number'] ?? 'TRX-${transaction['id']}';
    final status = transaction['status'] ?? 'SUCCESS';
    final desc = transaction['description'] ?? '';

    final otherName = transaction['other_party_name']?.toString() ?? '';
    final otherPhone = transaction['other_party_phone']?.toString() ?? '';

    String getCurrencyAr(String code) {
      if (code == 'YER') return 'ر.ي';
      if (code == 'USD') return 'دولار';
      if (code == 'SAR') return 'ر.س';
      return code;
    }

    final dateFormatted = intl.DateFormat(
      'yyyy/MM/dd hh:mm a',
      'en_US',
    ).format(DateTime.parse(dateValue).toLocal());

    final opType = transaction['operation_type']?.toString() ?? '';
    final String refLabelKey = OperationHistoryModel.remittanceTypes.contains(opType)
        ? 'remittance_number_label'
        : 'operation_reference';

    List<ReceiptRowData> details = [
      ReceiptRowData(label: refLabelKey.tr(), value: refNo, isCopyable: true),
      ReceiptRowData(label: 'operation_date'.tr(), value: dateFormatted),
      ReceiptRowData(
        label: 'label_status'.tr(),
        value: status == 'SUCCESS' ? 'status_success'.tr() : 'status_processing'.tr(),
      ),
    ];

    if ((type == 'exchange' ||
            desc.contains('صرف') ||
            desc.contains('مصارفة')) &&
        targetAmount != null) {
      details.add(
        ReceiptRowData(
          label: 'sent_amount_label'.tr(),
          value: '${formatAmountDisplay(amount)} ${getCurrencyAr(currency)}',
        ),
      );
      details.add(
        ReceiptRowData(
          label: 'received_amount_label'.tr(),
          value:
              '${formatAmountDisplay(targetAmount)} ${getCurrencyAr(targetCurrency.toString())}',
        ),
      );
      if (exchangeRate != null) {
        details.add(
          ReceiptRowData(label: 'exchange_rate_label'.tr(), value: exchangeRate.toString()),
        );
      }
    }

    if (otherName.isNotEmpty && otherName != '-') {
      details.add(ReceiptRowData(label: 'other_party_label'.tr(), value: otherName));
    }
    if (otherPhone.isNotEmpty && otherPhone != '-') {
      details.add(
        ReceiptRowData(
          label: 'other_party_phone_label'.tr(),
          value: otherPhone,
          isCopyable: true,
        ),
      );
    }
    if (desc.isNotEmpty) {
      details.add(ReceiptRowData(label: 'operation_description'.tr(), value: desc));
    }

    String mainAmountStr = formatAmountDisplay(amount);
    String mainCurrencyStr = getCurrencyAr(currency);

    ReceiptDialog.show(
      context,
      isDarkMode: isDarkMode,
      title: 'operation_details_title'.tr(),
      mainAmount: mainAmountStr,
      mainCurrency: mainCurrencyStr,
      details: details,
    );
  }
}
