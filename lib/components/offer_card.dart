import 'package:flutter/material.dart';
import '../models/recharge_offer.dart';
import '../core/app_colors.dart';

class OfferCard extends StatelessWidget {
  final RechargeOffer offer;
  final bool isSelected;
  final VoidCallback onTap;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.1),
                        AppColors.secondaryBlue.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Offer Name
              Text(
                offer.nameAr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryBlue : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${offer.amount.toStringAsFixed(0)} ريال',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textBlack,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                ],
              ),

              // Subscriber Type Badge
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSubscriberTypeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  offer.subscriberTypeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getSubscriberTypeColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubscriberTypeColor() {
    switch (offer.subscriberType) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
