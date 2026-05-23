import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:saifix/services/sound_service.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../components/security_verification_dialog.dart';
import '../../widgets/receipt_dialog.dart';
import '../account_confirmation_screen.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../components/qr_scanner_screen.dart';
import '../../helper/arabic_numbers_helper.dart';

class SaificashReceiveTransferScreen extends StatefulWidget {
  final bool isDarkMode;
  const SaificashReceiveTransferScreen({super.key, required this.isDarkMode});

  @override
  State<SaificashReceiveTransferScreen> createState() =>
      _SaificashReceiveTransferScreenState();
}

class _SaificashReceiveTransferScreenState
    extends State<SaificashReceiveTransferScreen> {
  final _transferIdController = TextEditingController();
  Map<String, dynamic>? _remittanceData;
  bool _isLoading = false;
  bool _isNameMatched = false;
  String? _currentUserName;

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
                            const SizedBox(height: 10),
                            // Top Icon with animation
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
                                      Icons.security_rounded,
                                      color: AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                                      size: 40,
                                    ),
                                  ),
                                )
                                .animate()
                                .scale(duration: 600.ms, curve: Curves.easeIn)
                                .fadeIn(),

                            const SizedBox(height: 30),

                            // Warning Rule Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.adaptiveIcon(
                                  widget.isDarkMode,
                                ).withValues(alpha: widget.isDarkMode ? 0.1 : 0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: AppColors.adaptiveIcon(
                                    widget.isDarkMode,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'receiverMatchingRule'.tr(),
                                      style: TextStyle(
                                        color: AppColors.adaptiveText(
                                          widget.isDarkMode,
                                          lightColor: AppColors.primaryBlue,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Transfer ID Input
                            _buildPremiumTextField(
                              controller: _transferIdController,
                              label: 'transfer_id_label'.tr(),
                              hint: 'transfer_id_hint'.tr(),
                              icon: Icons.numbers_rounded,
                            ),

                            const SizedBox(height: 25),

                            // Search Button
                            _buildPremiumSubmitButton(),

                            if (_remittanceData != null) ...[
                              const SizedBox(height: 30),
                              _buildRemittanceDetailsCard(),
                            ],

                            const SizedBox(height: 40),

                            // SaifiCash Branding Section (Similar to Networks Grid)
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
            'receive_saificash_transfer'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            inputFormatters: [ArabicToEnglishNumbersFormatter()],
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: AppColors.accentBlue, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.accentBlue,
                ),
                onPressed: _scanQr,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _scanQr() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(isDarkMode: widget.isDarkMode),
      ),
    );

    if (result != null && mounted) {
      _transferIdController.text = result.toString();
      _enquiryRemittance();
    }
  }

  Widget _buildPremiumSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _enquiryRemittance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
                  'search_button'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

  Future<void> _enquiryRemittance() async {
    final number = _transferIdController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter_transfer_id_snackbar'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _remittanceData = null;
      _isNameMatched = false;
      _currentUserName = null;
    });

    try {
      // جلب بيانات المستخدم الحالي
      final user = await ApiService.getCachedUser();
      if (user != null) {
        _currentUserName =
            user['full_name'] ??
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
      }

      final result = await ApiService.receiveSaifiCashEnquiry(number);
      if (mounted) {
        if (result['status'] == 'success') {
          final data = result['data'];
          final beneficiaryName = data['bnf_name'] ?? '';

          // مقارنة الأسماء إذا كان اسم المستخدم متوفراً
          if (_currentUserName != null && beneficiaryName.isNotEmpty) {
            _isNameMatched = _compareNames(beneficiaryName, _currentUserName!);
          }

          setState(() {
            _remittanceData = data;
            _isLoading = false;
          });
        } else {
          throw Exception(result['message'] ?? 'فشل الاستعلام');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showProfessionalError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showProfessionalError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool _compareNames(String beneficiaryName, String currentUserName) {
    // تطبيع الأسماء
    String normalize(String name) {
      return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    }

    String bnf = normalize(beneficiaryName);
    String current = normalize(currentUserName);

    // مطابقة كاملة
    if (bnf == current) return true;

    // مطابقة جزئية (يحتوي الاسم على جزء من الاسم الآخر)
    if (bnf.contains(current) || current.contains(bnf)) return true;

    // مقارنة الكلمات الفردية
    List<String> bnfWords = bnf.split(' ');
    List<String> currentWords = current.split(' ');

    int matches = 0;
    for (var word in bnfWords) {
      if (currentWords.any((w) => w.contains(word) || word.contains(w))) {
        matches++;
      }
    }

    // إذا تطابقت 50% على الأقل من الكلمات
    return matches >= (bnfWords.length / 2);
  }

  Widget _buildRemittanceDetailsCard() {
    if (_remittanceData == null) return const SizedBox.shrink();
    final data = _remittanceData!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.accentBlue.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'remittance_details_title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue,
                ),
              ),
              Icon(Icons.receipt_long_rounded, color: AppColors.accentBlue),
            ],
          ),
          const Divider(height: 30),
          _buildDetailRow('sender_label'.tr(), data['sndr_name'] ?? '---'),
          _buildDetailRow(
            'amount_label'.tr(),
            '${formatAmountDisplay(double.tryParse(data['rmt_amt']?.toString() ?? '0') ?? 0.0)} ${data['rmt_ccy'] ?? ''}',
          ),
          _buildDetailRow('recipient_label'.tr(), data['bnf_name'] ?? '---'),
          const SizedBox(height: 15),

          // مؤشر حالة المطابقة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _isNameMatched
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isNameMatched
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isNameMatched
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: _isNameMatched ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isNameMatched
                        ? 'name_matched_message'.tr()
                        : 'name_not_matched_message'.tr(),
                    style: TextStyle(
                      color: _isNameMatched ? Colors.green : Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // زر الاستلام - يظهر فقط إذا تطابق الاسم
          if (_isNameMatched)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _confirmReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'confirm_receive_button'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  'receive_disabled_message'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white60 : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReceipt() async {
    if (!await ApiService.checkVerification(
      context,
      isDarkMode: widget.isDarkMode,
      onVerifyNavigate:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AccountConfirmationScreen(isDarkMode: widget.isDarkMode),
            ),
          ),
    )) {
      return;
    }

    if (!mounted) return;

    if (_remittanceData == null) return;
    final data = _remittanceData!;

    // Create details widget for confirmation
    Widget detailsWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModernDetailRow(
          'sender_label'.tr(),
          data['sndr_name'] ?? '---',
          Icons.person_outline,
        ),
        _buildModernDetailRow(
          'amount_label'.tr(),
          '${formatAmountDisplay(double.tryParse(data['rmt_amt']?.toString() ?? '0') ?? 0.0)} ${data['rmt_ccy'] ?? ''}',
          Icons.monetization_on_outlined,
        ),
        _buildModernDetailRow(
          'transfer_id_label'.tr(),
          _transferIdController.text.trim(),
          Icons.receipt_long_outlined,
        ),
      ],
    );

    final authenticated = await SecurityVerificationDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'confirm_receive_transfer_title'.tr(),
      description: 'confirm_identity_description'.tr(),
      content: detailsWidget,
    );

    if (authenticated != true || !context.mounted) return;
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.confirmSaifiCashReceipt(
          _transferIdController.text.trim(),
          data['rcv_rqst_no'],
        );

        if (mounted) {
          setState(() => _isLoading = false);
          SoundService.playSuccessSound();

          final refNo = result['reference_number'] ?? result['ref_no'] ?? result['transaction_id'] ?? data['rcv_rqst_no'] ?? '---';
          final balanceAfter = result['balance_after'] ?? result['wallet_balance'] ?? result['balance'] ?? '';
          final feeStr = result['fee'] ?? result['commission'] ?? '0.00';

          await ReceiptDialog.show(
            context,
            isDarkMode: widget.isDarkMode,
            title: 'تم استلام الحوالة بنجاح',
            mainAmount: formatAmountDisplay(
              double.tryParse(data['rmt_amt']?.toString() ?? '0') ?? 0.0,
            ),
            mainCurrency: data['rmt_ccy'] ?? '',
            details: [
              ReceiptRowData(
                label: 'remittance_number_label'.tr(),
                value: _transferIdController.text.trim(),
                isCopyable: true,
              ),
              ReceiptRowData(
                label: 'رقم المرجع للعملية',
                value: refNo.toString(),
                isCopyable: true,
              ),
              ReceiptRowData(
                label: 'المرسل',
                value: data['sndr_name'] ?? '---',
              ),
              ReceiptRowData(
                label: 'المستفيد',
                value: data['bnf_name'] ?? '---',
              ),
              if (double.tryParse(feeStr.toString()) != null && double.parse(feeStr.toString()) > 0)
                ReceiptRowData(
                  label: 'الرسوم / العمولات',
                  value: '${formatAmountDisplay(double.parse(feeStr.toString()))} ${data['rmt_ccy'] ?? ''}',
                ),
              if (balanceAfter.toString().isNotEmpty)
                ReceiptRowData(
                  label: 'الرصيد بعد العملية',
                  value: '${formatAmountDisplay(double.tryParse(balanceAfter.toString()) ?? 0.0)} ${data['rmt_ccy'] ?? ''}',
                ),
              ReceiptRowData(
                label: 'تاريخ العملية',
                value: intl.DateFormat(
                  'yyyy-MM-dd (hh:mm a)',
                  'en_US',
                ).format(DateTime.now()),
              ),
            ],
            shareText:
                '✅ إيصال استلام حوالة - صيفي باي\n\n'
                'مبلغ الحوالة: ${formatAmountDisplay(double.tryParse(data['rmt_amt']?.toString() ?? '0') ?? 0.0)} ${data['rmt_ccy'] ?? ''}\n'
                'رقم الحوالة: ${_transferIdController.text.trim()}\n'
                'رقم المرجع: $refNo\n'
                'المرسل: ${data['sndr_name'] ?? '---'}\n'
                'المستفيد: ${data['bnf_name'] ?? '---'}\n',
          );

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showProfessionalError(e.toString().replaceAll('Exception: ', ''));
        }
      }
  }
}
