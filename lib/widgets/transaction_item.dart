import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:saifix/core/app_colors.dart';
import '../models/operation_history.dart';
import '../utils/operation_type_helper.dart';
import '../widgets/receipt_dialog.dart';
import '../helper/counvert_amunt_helper.dart';
import '../services/api_service.dart';


class TransactionItem extends StatelessWidget {
  final Map<String, dynamic>? transaction;
  final OperationHistoryModel? model;

  const TransactionItem({super.key, this.transaction, this.model});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract data based on whether we have a model or a map
    final String type;
    final double amount;
    final String currency;
    final DateTime date;
    final String title;
    final String description;
    final String balanceBefore;
    final String balanceAfter;

    if (model != null) {
      type = model!.operationType;
      amount = double.tryParse(model!.amount) ?? 0.0;
      currency = model!.currency;
      date = model!.createdAt.toLocal();
      title = model!.operationTypeDisplay;
      description = model!.description;
      balanceBefore = model!.balanceBefore;
      balanceAfter = model!.balanceAfter;
    } else if (transaction != null) {
      type =
          (transaction!['transaction_type'] ?? transaction!['type'] ?? '')
              .toString();
      amount =
          double.tryParse((transaction!['amount'] ?? '0').toString()) ?? 0.0;
      currency = (transaction!['currency'] ?? '').toString();
      final dateStr = transaction!['created_at'] ?? '';
      date =
          dateStr.isNotEmpty
              ? (DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now())
              : DateTime.now();
      title = transaction!['title']?.toString() ?? 'عملية';
      description = (transaction!['description'] ?? '').toString();
      balanceBefore = (transaction!['balance_before'] ?? '0').toString();
      balanceAfter = (transaction!['balance_after'] ?? '0').toString();
    } else {
      return const SizedBox.shrink();
    }

    final bBefore = double.tryParse(balanceBefore) ?? 0.0;
    final bAfter = double.tryParse(balanceAfter) ?? 0.0;
    final isPositive = bAfter > bBefore;

    final icon = OperationTypeHelper.getIcon(type);
    final iconColor = isPositive ? Colors.green : Colors.red;



    return GestureDetector(
      onTap: () async {
        if (model != null) {
          await _showOperationDetails(context, model!, isDark);
        } else if (transaction != null) {
          // Fallback for old map-based transactions if needed
          // Or just show a generic receipt
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            // Styled Icon Container
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 15),

            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${intl.DateFormat('dd/MM/yyyy', 'en_US').format(date)} | ${intl.DateFormat('hh:mm a', 'en_US').format(date)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? "+" : "-"}${formatAmountDisplay(amount)}',
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  currency,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOperationDetails(
    BuildContext context,
    OperationHistoryModel model,
    bool isDarkMode,
  ) async {
    final dateFormat = intl.DateFormat('dd/MM/yyyy HH:mm', 'en_US');
    final user = await ApiService.getCachedUser();
    final fullName = user?['full_name'] ?? "";
    final username = user?['username'] ?? "";

    List<ReceiptRowData> details = [];
    if (model.referenceNumber.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: model.getReferenceLabelKey().tr(),
          value: model.referenceNumber,
          isCopyable: true,
        ),
      );
    }
    details.add(
      ReceiptRowData(
        label: 'transactionType'.tr(),
        value: model.operationTypeDisplay,
      ),
    );

    if (model.fee != '0' && model.fee.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: 'operation_fee'.tr(),
          value:
              '${formatAmountDisplay(double.tryParse(model.fee) ?? 0)} ${model.currency}',
        ),
      );
    }

    final balanceBefore = double.tryParse(model.balanceBefore) ?? 0.0;
    final balanceAfter = double.tryParse(model.balanceAfter) ?? 0.0;
    final isIncoming = balanceAfter > balanceBefore;

    if (model.relatedUserName != null && model.relatedUserName!.isNotEmpty) {
      if (isIncoming) {
        details.add(
          ReceiptRowData(label: 'المستفيد', value: '$fullName\n$username'),
        );
        details.add(
          ReceiptRowData(label: 'المودع', value: model.relatedUserName!),
        );
      } else {
        details.add(
          ReceiptRowData(label: 'المستفيد', value: model.relatedUserName!),
        );
        details.add(
          ReceiptRowData(label: 'المودع', value: '$fullName\n$username'),
        );
      }
    }

    details.add(
      ReceiptRowData(
        label: 'operation_date'.tr(),
        value: dateFormat.format(model.createdAt.toLocal()),
      ),
    );

    if (model.description.isNotEmpty &&
        OperationHistoryModel.remittanceTypes.contains(model.operationType)) {
      details.add(
        ReceiptRowData(
          label: 'operation_description'.tr(),
          value: model.description,
        ),
      );
    }

    if (!context.mounted) return;
    ReceiptDialog.show(
      context,
      isDarkMode: isDarkMode,
      title: 'operation_details_title'.tr(),
      mainAmount: formatAmountDisplay(double.tryParse(model.amount) ?? 0),
      mainCurrency: model.currency,
      details: details,
      amountColor: isIncoming ? Colors.green : Colors.red,
    );
  }
}
