import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/receipt_dialog.dart';
import '../helper/counvert_amunt_helper.dart';
import '../models/operation_history.dart';


class TransactionReferenceDialog extends StatefulWidget {
  final bool isDarkMode;

  const TransactionReferenceDialog({super.key, required this.isDarkMode});

  @override
  State<TransactionReferenceDialog> createState() =>
      _TransactionReferenceDialogState();
}

class _TransactionReferenceDialogState
    extends State<TransactionReferenceDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSearch() async {
    final ref = _controller.text.trim();
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_enter_the_required_data'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaction = await ApiService.getOperationsReferenceHistory(
        referenceNumber: ref,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (transaction != null) {
        Navigator.pop(context); // Close search dialog

        // Fetch user identity
        final user = await ApiService.getCachedUser();
        final fullName = user?['full_name'] ?? "";
        final username = user?['username'] ?? "";

        // Prepare receipt data
        List<ReceiptRowData> details = [];
        if (transaction.referenceNumber.isNotEmpty) {
          details.add(
            ReceiptRowData(
              label: transaction.getReferenceLabelKey().tr(),
              value: transaction.referenceNumber,
              isCopyable: true,
            ),
          );
        }
        details.add(
          ReceiptRowData(
            label: 'transactionType'.tr(),
            value: transaction.operationTypeDisplay,
          ),
        );

        if (transaction.fee != '0' && transaction.fee.isNotEmpty) {
          details.add(
            ReceiptRowData(
              label: 'operation_fee'.tr(),
              value:
                  '${formatAmountDisplay(double.tryParse(transaction.fee) ?? 0)} ${transaction.currency}',
            ),
          );
        }

        final balanceBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
        final balanceAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
        final isIncoming = balanceAfter > balanceBefore;

        if (transaction.relatedUserName != null &&
            transaction.relatedUserName!.isNotEmpty) {
          if (isIncoming) {
            details.add(
              ReceiptRowData(label: 'المستفيد', value: '$fullName\n$username'),
            );
            details.add(
              ReceiptRowData(label: 'المودع', value: transaction.relatedUserName!),
            );
          } else {
            details.add(
              ReceiptRowData(
                label: 'المستفيد',
                value: transaction.relatedUserName!,
              ),
            );
            details.add(
              ReceiptRowData(label: 'المودع', value: '$fullName\n$username'),
            );
          }
        }

        details.add(
          ReceiptRowData(
            label: 'operation_date'.tr(),
            value: DateFormat('dd/MM/yyyy HH:mm', 'en_US').format(
              transaction.createdAt.toLocal(),
            ),
          ),
        );

        // Add description if available
        if (transaction.description.isNotEmpty &&
            OperationHistoryModel.remittanceTypes.contains(
              transaction.operationType,
            )) {
          details.add(
            ReceiptRowData(
              label: 'operation_description'.tr(),
              value: transaction.description,
            ),
          );
        }

        if (!mounted) return;
        ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'تفاصيل العملية',
          mainAmount: formatAmountDisplay(
            double.tryParse(transaction.amount) ?? 0,
          ),
          mainCurrency: transaction.currency,
          details: details,
          amountColor: isIncoming ? Colors.green : Colors.red,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('no_requests_label'.tr())));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'بحث بالرقم المرجعي',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textBlack,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textBlack,
            ),
            decoration: InputDecoration(
              labelText: 'رقم مرجع العملية',
              labelStyle: GoogleFonts.cairo(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              hintText: 'أدخل الرقم المرجعي هنا',
              hintStyle: GoogleFonts.cairo(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              filled: true,
              fillColor:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'بحث',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
