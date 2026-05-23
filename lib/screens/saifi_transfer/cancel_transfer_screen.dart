import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:saifix/services/sound_service.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../account_confirmation_screen.dart';
import '../../components/security_verification_dialog.dart';
import '../../widgets/receipt_dialog.dart';
import '../../helper/counvert_amunt_helper.dart';

class CancelTransferScreen extends StatefulWidget {
  final bool isDarkMode;
  const CancelTransferScreen({super.key, required this.isDarkMode});

  @override
  State<CancelTransferScreen> createState() => _CancelTransferScreenState();
}

class _CancelTransferScreenState extends State<CancelTransferScreen> {
  final _transferIdController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _remittanceData;
  String? _errorMessage;

  Future<void> _searchRemittance() async {
    final transferId = _transferIdController.text.trim();
    if (transferId.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رقم الحوالة');
      return;
    }

    FocusScope.of(context).unfocus();

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _remittanceData = null;
    });

    try {
      final data = await ApiService.queryRemittance(transferId);
      setState(() {
        _remittanceData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCancel() async {
    if (_remittanceData == null) return;

    final transferId = _transferIdController.text.trim();
    final amount =
        double.tryParse(_remittanceData!['amount']?.toString() ?? '0') ?? 0;
    final currency = _remittanceData!['currency'] ?? '';
    final receiverName = _remittanceData!['receiver_name'] ?? 'مستخدم';

    Widget detailsWidget = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المبلغ', style: TextStyle(color: Colors.grey)),
            Text(
              '${formatAmountDisplay(amount)} $currency',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المستفيد', style: TextStyle(color: Colors.grey)),
            Text(
              receiverName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );

    final password = await SecurityVerificationDialog.showWithPassword(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'تأكيد إلغاء الحوالة',
      description:
          'يرجى إدخال كلمة المرور لتأكيد إلغاء الحوالة رقم $transferId',
      content: detailsWidget,
    );

    if (password == null || password == false) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.cancelRemittance(
        transferId,
        password.toString(),
      );

      setState(() {
        _isLoading = false;
        _remittanceData = null;
        _transferIdController.clear();
      });

      if (mounted) {
        SoundService.playSuccessSound();
        await ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'تم إلغاء الحوالة بنجاح',
          mainAmount: formatAmountDisplay(amount),
          mainCurrency: currency,
          details: [
            ReceiptRowData(
              label: 'رقم الحوالة',
              value: transferId,
              isCopyable: true,
            ),
            ReceiptRowData(label: 'المستفيد', value: receiverName),
            ReceiptRowData(
              label: 'تاريخ الإلغاء',
              value: intl.DateFormat(
                'yyyy-MM-dd (hh:mm a)',
                'en_US',
              ).format(DateTime.now()),
            ),
            if (response['reference_number'] != null)
              ReceiptRowData(
                label: 'رقم العملية',
                value: response['reference_number'],
                isCopyable: true,
              ),
          ],
          shareText:
              'تم إلغاء حوالة - صيفي باي\nرقم الحوالة: $transferId\nالمبلغ: ${formatAmountDisplay(amount)} $currency\nالمستفيد: $receiverName',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode
                                  ? AppColors.cardDark
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                widget.isDarkMode
                                    ? Colors.white10
                                    : Colors.black12,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color:
                              widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.textBlack,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'cancel_transfer_title'.tr(),
                    style: TextStyle(
                      color:
                          widget.isDarkMode
                              ? Colors.white
                              : AppColors.textBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
            ),

            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        // Service Icon
                        Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.cancel_outlined,
                                  color: AppColors.adaptiveIcon(
                                    widget.isDarkMode,
                                  ),
                                  size: 24,
                                ),
                              ),
                            )
                            .animate()
                            .scale(duration: 400.ms, curve: Curves.easeOutBack)
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 40),

                        // Notification Message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(right: 5, bottom: 15),
                          child: Text(
                            'cancel_transfer_notice'.tr(),
                            style: TextStyle(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white70
                                      : AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Transfer ID Input
                        TextField(
                          controller: _transferIdController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color:
                                widget.isDarkMode
                                    ? Colors.white
                                    : AppColors.textBlack,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                          onChanged: (v) {
                            if (_remittanceData != null) {
                              setState(() => _remittanceData = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'transfer_id_hint'.tr(),
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.adaptiveIcon(
                                  widget.isDarkMode,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              right: 8.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ).animate().fade(),

                        const SizedBox(height: 20),

                        if (_remittanceData != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white10
                                        : Colors.black12,
                              ),
                            ),
                            child: Column(
                              children: [
                                  _buildDetailRow(
                                    'المبلغ',
                                    '${formatAmountDisplay(double.tryParse(_remittanceData!['amount']?.toString() ?? '0') ?? 0)} ${_remittanceData!['currency']}',
                                  ),
                                const Divider(),
                                _buildDetailRow(
                                  'المستفيد',
                                  _remittanceData!['receiver_name'] ?? 'مستخدم',
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  'تاريخ الإرسال',
                                  _remittanceData!['created_at'] != null
                                      ? intl.DateFormat('yyyy-MM-dd', 'en_US').format(
                                        DateTime.parse(
                                          _remittanceData!['created_at'],
                                        ),
                                      )
                                      : 'غير محدد',
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 20),
                        ],

                        // Action Button
                        Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient:
                                    _remittanceData != null
                                        ? const LinearGradient(
                                          colors: [
                                            Colors.redAccent,
                                            Colors.red,
                                          ],
                                        )
                                        : AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_remittanceData != null
                                            ? Colors.red
                                            : AppColors.primaryBlue)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : (_remittanceData != null
                                            ? _confirmCancel
                                            : _searchRemittance),
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
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          _remittanceData != null
                                              ? 'تأكيد إلغاء الحوالة'
                                              : 'search_transfer'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
