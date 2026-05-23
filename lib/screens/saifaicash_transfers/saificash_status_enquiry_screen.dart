import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import 'package:flutter/services.dart';
import '../../helper/arabic_numbers_helper.dart';

class SaificashStatusEnquiryScreen extends StatefulWidget {
  final bool isDarkMode;
  const SaificashStatusEnquiryScreen({super.key, required this.isDarkMode});

  @override
  State<SaificashStatusEnquiryScreen> createState() =>
      _SaificashStatusEnquiryScreenState();
}

class _SaificashStatusEnquiryScreenState
    extends State<SaificashStatusEnquiryScreen> {
  final _rmtNoController = TextEditingController();
  Map<String, dynamic>? _enquiryResult;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Top Icon
                            Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color:
                                          widget.isDarkMode
                                              ? AppColors.cardDark
                                              : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 
                                            widget.isDarkMode ? 0.3 : 0.05,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.fact_check_rounded,
                                      color: AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                                      size: 40,
                                    ),
                                  ),
                                )
                                .animate()
                                .scale(
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                )
                                .fadeIn(),

                            const SizedBox(height: 40),

                            // Input Field
                            _buildPremiumTextField(
                              controller: _rmtNoController,
                              label: 'rmt_no_label'.tr(),
                              hint: 'saificash_enquiry_hint'.tr(),
                              icon: Icons.numbers_rounded,
                              inputFormatters: [
                                ArabicToEnglishNumbersFormatter(),
                              ],
                            ),

                            const SizedBox(height: 25),

                            // Submit Button
                            _buildPremiumSubmitButton(),

                            if (_enquiryResult != null) ...[
                              const SizedBox(height: 30),
                              _buildResultCard(),
                            ],

                            const SizedBox(height: 40),
                            _buildSaifiCashBranding(),
                            const SizedBox(height: 40),
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

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
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
            'saificash_enquiry_title'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  widget.isDarkMode
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: Icon(
                icon,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSubmitButton() {
    return Container(
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
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEnquiry,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'search_transfer'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildResultCard() {
    final status = _enquiryResult?['rmt_status'] ?? 'notfound';
    final message = _enquiryResult?['message'] ?? '';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    // تطبيع حالة الحوالة للتعامل مع القيم العربية والإنجليزية
    String normalizedStatus = status.toString().toLowerCase();

    if (normalizedStatus == 'paid' ||
        normalizedStatus.contains('مدفوعة للمستفيد')) {
      statusColor = Colors.green;
      statusText = 'status_paid'.tr();
      statusIcon = Icons.check_circle_rounded;
    } else if (normalizedStatus == 'unpaid' ||
        normalizedStatus.contains('غير مدفوعة')) {
      statusColor = Colors.orange;
      statusText = 'ready_for_payout'.tr(); // جاهزة للاستلام
      statusIcon = Icons.pending_rounded;
    } else {
      statusColor = Colors.red;
      statusText = 'status_notfound'.tr();
      statusIcon = Icons.error_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 30),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
          const SizedBox(height: 10),
          _buildDetailRow(
            'rmt_no_label'.tr(),
            _rmtNoController.text,
            Icons.numbers_rounded,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'rmt_status_label'.tr(),
            statusText,
            Icons.info_outline_rounded,
            valueColor: statusColor,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('التفاصيل:', message, Icons.message_rounded),
          ],
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.adaptiveIcon(widget.isDarkMode),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white54 : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color:
                      valueColor ??
                      (widget.isDarkMode ? Colors.white : AppColors.textBlack),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
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
              color: AppColors.primaryBlue.withValues(alpha: 
                widget.isDarkMode ? 0.05 : 0.03,
              ),
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
              color: AppColors.primaryBlue.withValues(alpha: 
                widget.isDarkMode ? 0.05 : 0.03,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEnquiry() async {
    final rmtNo = _rmtNoController.text.trim();
    if (rmtNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter_transfer_id_snackbar'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _enquiryResult = null;
    });

    try {
      final result = await ApiService.enquireSaifiCashStatus(rmtNo);
      setState(() {
        _enquiryResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showProfessionalError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showProfessionalError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor:
                widget.isDarkMode ? AppColors.cardDark : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'خطأ في الاستعلام',
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.white70
                              : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          color: Colors.red,
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

  Widget _buildSaifiCashBranding() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.adaptiveIcon(widget.isDarkMode),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'saifi_cash'.tr(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: 120,
          height: 90,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Image.asset(
              'assets/images/logo_circle.png',
              height: 50,
              errorBuilder:
                  (context, error, stackTrace) => Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primaryBlue,
                    size: 40,
                  ),
            ),
          ),
        ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }
}
