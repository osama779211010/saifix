import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/recharge_service.dart';
import '../models/recharge_offer.dart';

class PaymentConfirmationDialog extends StatelessWidget {
  final RechargeService service;
  final RechargeOffer? offer;
  final String subscriberNumber;
  final double amount;
  final int subscriberType;
  final VoidCallback onConfirm;

  const PaymentConfirmationDialog({
    super.key,
    required this.service,
    this.offer,
    required this.subscriberNumber,
    required this.amount,
    required this.subscriberType,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'تأكيد عملية الدفع',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow('الخدمة:', service.nameAr),
            const SizedBox(height: 12),
            if (offer != null) ...[
              _buildDetailRow('الباقة:', offer!.nameAr),
              const SizedBox(height: 12),
            ],
            _buildDetailRow('رقم المشترك:', subscriberNumber),
            const SizedBox(height: 12),
            _buildDetailRow(
              'النوع:',
              subscriberType == 1 ? 'سبق دفع' : 'فاتورة',
            ),
            const SizedBox(height: 12),

            // Amount (Highlighted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المبلغ:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(2)} ريال',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم خصم المبلغ من محفظتك فوراً',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.primaryBlue),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
      ],
    );
  }
}
