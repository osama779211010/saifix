import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../components/security_verification_dialog.dart';
import '../account_confirmation_screen.dart';
import '../../helper/arabic_numbers_helper.dart';

class LocalTransferStatusCancelScreen extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final IconData icon;
  final List<String> rules;

  const LocalTransferStatusCancelScreen({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.icon,
    this.rules = const [],
  });

  @override
  State<LocalTransferStatusCancelScreen> createState() =>
      _LocalTransferStatusCancelScreenState();
}

class _LocalTransferStatusCancelScreenState
    extends State<LocalTransferStatusCancelScreen> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _remittanceData;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchRemittance() async {
    final number = _controller.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'enter_remittance_number_hint'.tr(),
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _remittanceData = null;
    });

    try {
      final result = await ApiService.queryRemittance(number);
      setState(() {
        _remittanceData = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: ${e.toString().replaceAll('Exception: ', '')}',
              style: const TextStyle(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelRemittance() async {
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

    if (_remittanceData == null) return;
    final data = _remittanceData!;

    try {
      if (!mounted) return;
      // 1. طلب التحقق الأمني والحصول على كلمة المرور
      final result = await SecurityVerificationDialog.showWithPassword(
        context,
        isDarkMode: widget.isDarkMode,
        title: 'cancel_remittance_confirm_title'.tr(),
        description: 'cancel_remittance_confirm_desc'.tr(),
      );

      if (result == null || result == false) return;
      final String password = result is String ? result : '';

      if (password.isEmpty && result != true) return;

      setState(() => _isLoading = true);

      // 2. استدعاء API الإلغاء
      await ApiService.cancelRemittance(
        data['remittance_number'],
        password,
        operationId: data['operation_id']?.toString() ?? '',
      );

      setState(() {
        _isLoading = false;
        // تحديث البيانات محلياً لتظهر أنها ملغية
        _remittanceData!['status'] = 'CANCELLED';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cancel_remittance_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'cancel_remittance_error_prefix'.tr()} $errorMessage',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                _buildPremiumHeader(context),
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
                            // Icon with styling
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
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
                                  widget.icon,
                                  color: AppColors.accentBlue,
                                  size: 30,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Rules Card
                            if (widget.rules.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.adaptiveIcon(
                                    widget.isDarkMode,
                                  ).withValues(alpha: widget.isDarkMode ? 0.1 : 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: AppColors.accentBlue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'instructions_title'.tr(),
                                          style: TextStyle(
                                            color: AppColors.accentBlue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    ...widget.rules.map(
                                      (rule) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ',
                                              style: TextStyle(
                                                color: AppColors.accentBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                rule.toString().tr(),
                                                style: TextStyle(
                                                  color:
                                                      widget.isDarkMode
                                                          ? Colors.white70
                                                          : AppColors.textBlack,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (widget.rules.isNotEmpty)
                              const SizedBox(height: 30),

                            // Input Field
                            _buildPremiumTextField(
                              controller: _controller,
                              label: 'remittance_number_label'.tr(),
                              hint: 'remittance_number_hint'.tr(),
                              icon: Icons.numbers_rounded,
                            ),

                            const SizedBox(height: 25),

                            // Action Button
                            _buildPremiumSubmitButton(), // ensure this uses a translatable label internally

                            if (_remittanceData != null) ...[
                              const SizedBox(height: 30),
                              _buildRemittanceDetailsCard(),
                            ],
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
              color: AppColors.adaptiveIcon(
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
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
              color: AppColors.adaptiveIcon(
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
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
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [ArabicToEnglishNumbersFormatter()],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: AppColors.accentBlue, size: 22),
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
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _searchRemittance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child:
            _isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'search_remittance_button'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
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
                'remittance_details'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: AppColors.accentBlue,
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: data['remittance_number']?.toString() ?? '',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('copied_remittance_number'.tr())),
                  );
                },
                tooltip: 'copy_remittance_tooltip'.tr(),
              ),
            ],
          ),
          const Divider(height: 30),
          _buildDetailRow(
            'label_sender'.tr(),
            data['sender_name'] ?? 'unknown'.tr(),
          ),
          _buildDetailRow(
            'label_amount'.tr(),
            '${formatAmountDisplay(double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0)} ${data['currency'] ?? ''}',
          ),
          _buildDetailRow(
            'label_recipient'.tr(),
            data['recipient_name'] ?? 'unknown'.tr(),
          ),
          _buildDetailRow(
            'label_phone'.tr(),
            data['recipient_phone'] ?? 'not_available'.tr(),
          ),
          _buildDetailRow(
            'label_status'.tr(),
            _translateStatus(data['status']),
          ),
          if (data['date'] != null)
            _buildDetailRow('label_date'.tr(), data['date'] ?? ''),
          const SizedBox(height: 10),
          if (widget.title.contains('الغاء') &&
              data['status'] == 'PENDING') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _cancelRemittance,
                icon: const Icon(Icons.cancel_rounded, color: Colors.white),
                label: Text(
                  'cancel_remittance_and_refund'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusMessage(data['status']),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getStatusColor(data['status']),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'PENDING':
        return 'status_pending'.tr();
      case 'RECEIVED':
        return 'status_received'.tr();
      case 'CANCELLED':
        return 'status_cancelled'.tr();
      default:
        return (status ?? 'status_unknown').toString().tr();
    }
  }

  String _getStatusMessage(String? status) {
    switch (status) {
      case 'PENDING':
        return 'status_msg_pending'.tr();
      case 'RECEIVED':
        return 'status_msg_received'.tr();
      case 'CANCELLED':
        return 'status_msg_cancelled'.tr();
      default:
        return 'status_msg_unknown'.tr();
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return Colors.green;
      case 'RECEIVED':
        return AppColors.adaptiveIcon(widget.isDarkMode);
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
