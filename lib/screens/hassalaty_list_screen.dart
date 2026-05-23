import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../components/security_verification_dialog.dart';
import 'create_hassala_screen.dart';
import '../widgets/receipt_dialog.dart';
import 'package:intl/intl.dart' as intl;
import '../helper/counvert_amunt_helper.dart';

class HassalatyListScreen extends StatefulWidget {
  final bool isDarkMode;

  const HassalatyListScreen({super.key, required this.isDarkMode});

  @override
  State<HassalatyListScreen> createState() => _HassalatyListScreenState();
}

class _HassalatyListScreenState extends State<HassalatyListScreen> {
  List<dynamic> _savings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHassalas();
  }

  Future<void> _fetchHassalas() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHassalas();
      setState(() {
        _savings = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل جلب البيانات: $e', style: GoogleFonts.cairo()),
          ),
        );
      }
    }
  }

  void _showDepositDialog(Map<String, dynamic> saving) {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'deposit_label'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${'saving_details'.tr()}: ${saving['name']}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      autofocus: true,
                      style: GoogleFonts.cairo(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أدخل المبلغ...',
                        hintStyle: GoogleFonts.cairo(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_rounded,
                          color:
                              widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى إدخال مبلغ صحيح'),
                            ),
                          );
                          return;
                        }

                        // 🔐 التحقق من الهوية (بصمة/كلمة مرور) قبل الإيداع
                        final authenticated =
                            await SecurityVerificationDialog.show(
                              context,
                              isDarkMode: widget.isDarkMode,
                            );

                        if (authenticated == true) {
                          if (context.mounted) {
                            Navigator.of(context).popUntil(
                              (route) => route.isFirst,
                            ); // Close bottom sheet
                          }
                          _performDeposit(saving['id'], amount);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'confirm'.tr(),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _performDeposit(int id, double amount) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.depositToHassala(id, amount);
      if (mounted) {
        Navigator.of(
          context,
        ).popUntil((route) => route.isFirst); // Remove loading dialog

        await ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'إيصال إيداع في الحصالة',
          mainAmount: formatAmountDisplay(amount),
          mainCurrency: 'YER',
          details: [
            ReceiptRowData(
              label: 'رقم العملية',
              value: response['reference_number'] ?? 'N/A',
              isCopyable: true,
            ),
            ReceiptRowData(
              label: 'التاريخ',
              value: intl.DateFormat(
                'yyyy-MM-dd HH:mm',
                'en_US',
              ).format(DateTime.now()),
            ),
            ReceiptRowData(label: 'نوع العملية', value: 'إيداع في الحصالة'),
          ],
        );

        _fetchHassalas(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(
          context,
        ).popUntil((route) => route.isFirst); // Remove loading dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'خطأ في الإيداع',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('حسناً', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
        );
      }
    }
  }

  void _showUnlockDialog(Map<String, dynamic> saving) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor:
                widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: Text(
              'فتح الحصالة',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'لقد استوفيت شروط الفتح! هل تريد فتح الحصالة الآن وإعادة المبلغ إلى محفظتك؟',
                  style: GoogleFonts.cairo(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'المبلغ المسترد: ${saving['current_amount']} ${saving['currency']}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ليس الآن',
                  style: GoogleFonts.cairo(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final authenticated = await SecurityVerificationDialog.show(
                    context,
                    isDarkMode: widget.isDarkMode,
                  );

                  if (authenticated == true) {
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                    _performUnlock(saving);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'فتح الآن',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _performUnlock(Map<String, dynamic> saving) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.unlockHassala(saving['id']);
      if (mounted) {
        Navigator.of(
          context,
        ).popUntil((route) => route.isFirst); // Remove loading

        final double amount =
            double.tryParse(
              response['amount']?.toString() ??
                  saving['current_amount']?.toString() ??
                  '0',
            ) ??
            0;
        final String currency =
            response['currency'] ?? saving['currency'] ?? 'YER';

        await ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'إيصال كسر الحصالة',
          mainAmount: formatAmountDisplay(amount),
          mainCurrency: currency,
          details: [
            ReceiptRowData(
              label: 'رقم العملية',
              value: response['reference_number'] ?? 'N/A',
              isCopyable: true,
            ),
            ReceiptRowData(
              label: 'المبلغ المسترد',
              value: '${formatAmountDisplay(amount)} $currency',
            ),
            ReceiptRowData(
              label: 'التاريخ',
              value: intl.DateFormat(
                'yyyy-MM-dd HH:mm',
                'en_US',
              ).format(DateTime.now()),
            ),
          ],
        );

        _fetchHassalas(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الفتح: $e', style: GoogleFonts.cairo())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'my_savings_list'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),

                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _savings.isEmpty
                          ? _buildEmptyState()
                          : _buildSavingsList(),
                ),

                _buildBottomAddButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
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
                color: AppColors.accentBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  size: 18,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings_outlined,
              size: 80,
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'no_savings_found'.tr(),
            style: GoogleFonts.cairo(
              color: widget.isDarkMode ? Colors.white70 : Colors.black45,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fade(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildSavingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savings.length,
      itemBuilder: (context, index) {
        final item = _savings[index];
        return _buildSavingCard(item);
      },
    );
  }

  Widget _buildSavingCard(Map<String, dynamic> item) {
    double target =
        double.tryParse(item['target_limit']?.toString() ?? '1') ?? 1;
    double current =
        double.tryParse(item['current_amount']?.toString() ?? '0') ?? 0;
    double progress = (current / target).clamp(0.0, 1.0);
    bool isByLimit = item['unlock_type'] == 'limit';
    bool canUnlock = item['can_unlock'] ?? false;
    bool isOpened = item['is_opened'] ?? false;

    return GestureDetector(
      onTap: () {
        if (isOpened) return;
        if (canUnlock) {
          _showUnlockDialog(item);
        } else {
          _showDepositDialog(item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isOpened
                        ? Icons.lock_open_rounded
                        : (canUnlock
                            ? Icons.lock_open_rounded
                            : (isByLimit
                                ? Icons.account_balance_rounded
                                : Icons.calendar_month_rounded)),
                    color:
                        isOpened
                            ? Colors.green
                            : (canUnlock
                                ? Colors.green
                                : (widget.isDarkMode
                                    ? Colors.white
                                    : AppColors.primaryBlue)),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.cairo(
                          color:
                              widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.textBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isByLimit
                                ? Icons.flag_rounded
                                : Icons.calendar_month_rounded,
                            size: 12,
                            color:
                                widget.isDarkMode ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isByLimit
                                  ? '${'goal_amount_label'.tr()}: ${item['target_limit']} ${item['currency']}'
                                  : '${'unlock_date_label'.tr()}: ${item['unlock_date']}',
                              style: GoogleFonts.cairo(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.grey,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOpened
                            ? Colors.green.withValues(alpha: 0.1)
                            : (canUnlock
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isOpened
                        ? 'تم الفتح'
                        : (canUnlock ? 'جاهزة للفتح' : 'saving_locked'.tr()),
                    style: GoogleFonts.cairo(
                      color:
                          isOpened
                              ? Colors.green
                              : (canUnlock ? Colors.green : Colors.orange),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    widget.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildBottomAddButton() {
    return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            CreateHassalaScreen(isDarkMode: widget.isDarkMode),
                  ),
                ).then((_) => _fetchHassalas()); // Refresh after return
              },
              icon: Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'add_new_saving'.tr(),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
