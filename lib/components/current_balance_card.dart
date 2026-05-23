import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/balance_service.dart';
import '../helper/counvert_amunt_helper.dart';

class CurrentBalanceCard extends StatelessWidget {
  final bool isDarkMode;
  final String? forceCurrency;

  const CurrentBalanceCard({
    super.key,
    required this.isDarkMode,
    this.forceCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListenableBuilder(
      listenable: balanceService,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ), // More compact padding
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18), // Slightly smaller radius
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr, // Force LTR for layout order
            child: Row(
              children: [
                // Currency Selector (Left side)
                _buildCurrencySelector(screenWidth),
                const SizedBox(width: 8),
                // Balance Info (Right side)
                Expanded(child: _buildBalanceInfo(screenWidth)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencySelector(double screenWidth) {
    if (forceCurrency != null) return const SizedBox.shrink();
    final currencies = ['SAR', 'USD', 'YER'];
    return Container(
      height: 36, // Smaller height
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            currencies.map((c) {
              final isSelected = balanceService.selectedCurrency == c;
              return GestureDetector(
                onTap: () => balanceService.setCurrency(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 8 : 12,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                            : null,
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : (isDarkMode
                                  ? Colors.white38
                                  : const Color(0xFFA0AEC0)),
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth < 360 ? 9.5 : 10.5, // Smaller font
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildBalanceInfo(double screenWidth) {
    final String currency = forceCurrency ?? balanceService.selectedCurrency;
    final String balance = balanceService.balances[currency] ?? '0.00';
    
    final currencyText =
        currency == 'YER'
            ? 'ريال يمني'
            : (currency == 'USD'
                ? 'دولار'
                : 'ريال سعودي');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => balanceService.toggleVisibility(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                balanceService.isHidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20, // Smaller icon
                color: isDarkMode ? Colors.white30 : const Color(0xFFA0AEC0),
              ),
              const SizedBox(width: 6),
              Text(
                'حساب المحفظة',
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : const Color(0xFF718096),
                  fontSize: screenWidth < 360 ? 11 : 12, // Smaller font
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            balanceService.isHidden
                ? '****** $currencyText'
                : '${formatAmountDisplay(double.tryParse(balance) ?? 0.0)} $currencyText',
            textDirection:
                TextDirection.rtl, // Keep text RTL for proper Arabic display
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.primaryBlue,
              fontWeight: FontWeight.w800,
              fontSize: screenWidth < 360 ? 14 : 16, // Smaller font
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
