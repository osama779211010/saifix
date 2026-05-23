import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../helper/arabic_numbers_helper.dart';
import '../../services/api_service.dart';
import '../account_confirmation_screen.dart';
import '../../widgets/receipt_dialog.dart';
import '../../services/sound_service.dart';
import '../../components/qr_scanner_screen.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/security_confirmation_dialog.dart';
import 'package:intl/intl.dart' as intl;
import '../../helper/counvert_amunt_helper.dart';
import '../../components/current_balance_card.dart';
import '../../services/balance_service.dart';
import '../../components/error_dialog.dart';
import '../../components/loading_overlay.dart';

class CashWithdrawalRequestScreen extends StatefulWidget {
  final bool isDarkMode;

  const CashWithdrawalRequestScreen({super.key, required this.isDarkMode});

  @override
  State<CashWithdrawalRequestScreen> createState() =>
      _CashWithdrawalRequestScreenState();
}

class _CashWithdrawalRequestScreenState
    extends State<CashWithdrawalRequestScreen> {
  final TextEditingController _posController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _branchName;
  String? _agentName;
  bool _isLoadingBranch = false;
  bool _isSubmitting = false;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = balanceService.selectedCurrency;
    balanceService.addListener(_onBalanceServiceChanged);
    _fetchBalances();
  }

  void _onBalanceServiceChanged() {
    if (mounted) {
      setState(() {
        _currency = balanceService.selectedCurrency;
      });
    }
  }

  @override
  void dispose() {
    balanceService.removeListener(_onBalanceServiceChanged);
    _posController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalances() async {
    await balanceService.refreshBalance();
  }

  void _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(isDarkMode: widget.isDarkMode),
      ),
    );

    if (result != null && mounted) {
      String cleanResult = result.trim();
      if (cleanResult.startsWith('POS:')) {
        cleanResult = cleanResult.substring(4);
      }

      _posController.text = cleanResult;
    }
  }

  Future<void> _fetchBranchInfo(String pos) async {
    if (pos.length < 5) return;

    setState(() => _isLoadingBranch = true);
    try {
      final info = await ApiService.getBranchInfoByPOS(pos);
      setState(() {
        _branchName = info['branch_name'];
        _agentName = info['agent_name'];
      });
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: 'invalid_pos_number'.tr());
      }
      setState(() {
        _branchName = null;
        _agentName = null;
      });
    } finally {
      setState(() => _isLoadingBranch = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    SoundService.playSuccessSound();

    final details = [
      ReceiptRowData(
        label: 'amount_label'.tr(),
        value: '${data['amount']} ${data['currency']}',
      ),
      ReceiptRowData(
        label: 'branch_label'.tr(),
        value: '${data['branch_name']}',
      ),
      ReceiptRowData(
        label: 'reference_number_label'.tr(),
        value: '${data['reference_number']}',
        isCopyable: true,
      ),
      ReceiptRowData(
        label: 'otp_label'.tr(),
        value: '${data['otp_code']}',
        isCopyable: true,
      ),
      ReceiptRowData(
        label: 'dateLabel'.tr(),
        value: intl.DateFormat(
          'dd/MM/yyyy HH:mm',
          'en_US',
        ).format(DateTime.now()),
      ),
    ];

    final shareText =
        '✅ ${"success_withdrawal_title".tr()} - ${"my_app_name".tr()} \n\n'
        '${"amount_label".tr()}: ${data['amount']} ${data['currency']}\n'
        '${"branch_label".tr()}: ${data['branch_name']}\n'
        '${"reference_number_label".tr()}: ${data['reference_number']}\n'
        '${"otp_label".tr()}: ${data['otp_code']}\n';

    ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'success_withdrawal_title'.tr(),
      mainAmount: '${data['amount']}',
      mainCurrency: '${data['currency']}',
      details: details,
      shareText: shareText,
    ).then((_) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
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
                _buildPremiumHeader(
                  'cash_withdrawal_request'.tr(),
                  () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        CurrentBalanceCard(isDarkMode: widget.isDarkMode),
                        const SizedBox(height: 20),
                        _buildModernInput(
                          label: 'pos_no_label'.tr(),
                          hint: 'pos_number_hint'.tr(),
                          controller: _posController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ArabicToEnglishNumbersFormatter()],
                          prefixIcon: Icons.storefront_rounded,
                          onChanged: (val) {
                            setState(() {
                              _branchName = null;
                              _agentName = null;
                            });
                          },
                          suffixWidget: IconButton(
                            icon: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.accentBlue,
                              size: 18,
                            ),
                            onPressed: _scanQr,
                          ),
                        ),
                        if (_isLoadingBranch)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(),
                          ),
                        if (_branchName != null)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _branchName!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        '${'agent_label'.tr()}: $_agentName',
                                        style: TextStyle(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                widget.isDarkMode
                                    ? AppColors.cardDark
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  widget.isDarkMode
                                      ? Colors.white10
                                      : Colors.grey.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              _buildModernInput(
                                label: 'withdraw_amount_label'.tr(),
                                hint: '0.00',
                                controller: _amountController,
                                onChanged: (val) => setState(() {}),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  ArabicToEnglishNumbersFormatter(),
                                ],
                                prefixIcon: Icons.money_rounded,
                                suffixWidget: Text(
                                  _currency,
                                  style: TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_amountController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 10,
                                  ),
                                  child: Text(
                                    '${formatAmountToArabicWords(double.tryParse(_amountController.text) ?? 0.0)} ${_currency == 'YER' ? 'ريال يمني' : (_currency == 'USD' ? 'دولار' : 'ريال سعودي')}',
                                    style: TextStyle(
                                      color:
                                          widget.isDarkMode
                                              ? Colors.white60
                                              : Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              _buildModernInput(
                                label: 'note_optional_label'.tr(),
                                hint: 'note_hint'.tr(),
                                controller: _noteController,
                                prefixIcon: Icons.note_add_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            LoadingOverlay(
              isDarkMode: widget.isDarkMode,
              message: 'processing_loading'.tr(),
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
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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

  // ignore: unused_element
  Widget _buildIconBox(
    IconData icon, {
    VoidCallback? onTap,
    Color? color,
    bool isTransparent = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color:
              isTransparent
                  ? Colors.white.withValues(alpha: 0.1)
                  : (widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isTransparent
                    ? Colors.white24
                    : (widget.isDarkMode
                        ? Colors.white12
                        : Colors.grey.shade200),
          ),
        ),
        child: Icon(
          icon,
          color:
              color ?? (widget.isDarkMode ? Colors.white : AppColors.textBlack),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required String hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    bool isDropdown = false,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    Widget? suffixWidget,
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: AppColors.accentBlue, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  readOnly: isDropdown,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (suffixWidget != null) ...[
                const SizedBox(width: 10),
                suffixWidget,
              ] else if (suffixIcon != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(
                    suffixIcon,
                    color: AppColors.accentBlue,
                    size: 20,
                  ),
                ),
              ] else if (isDropdown) ...[
                const SizedBox(width: 10),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.adaptiveIcon(
              widget.isDarkMode,
            ).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : () async {
          if (_posController.text.isEmpty || _amountController.text.isEmpty) {
            ErrorDialog.show(context, message: 'fill_all_fields'.tr());
            return;
          }

          if (!await ApiService.checkVerification(
            context,
            isDarkMode: widget.isDarkMode,
            onVerifyNavigate:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AccountConfirmationScreen(
                          isDarkMode: widget.isDarkMode,
                        ),
                  ),
                ),
          )) {
            return;
          }

          if (_branchName == null) {
            await _fetchBranchInfo(_posController.text);
            if (_branchName == null) {
              return;
            }
          }

          TransactionDetailsBottomSheet.show(
            // ignore: use_build_context_synchronously
            context,
            isDarkMode: widget.isDarkMode,
            amount: formatAmountDisplay(
              double.tryParse(_amountController.text) ?? 0,
            ),
            currency: _currency,
            transactionType: 'cash_withdrawal'.tr(),
            networkName:
                (_agentName != null && _branchName != null)
                    ? '$_agentName - $_branchName'
                    : null,
            recipientLabel: 'نقطة السحب',
            recipientName: _branchName ?? '',
            recipientId: _posController.text,
            onExecute: () async {
              final result = await SecurityConfirmationDialog.show(
                context,
                isDarkMode: widget.isDarkMode,
              );

              if (result != null) {
                if (mounted) {
                  setState(() => _isSubmitting = true);
                }
                _executeWithdrawal();
              }
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'send_withdrawal_request'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _executeWithdrawal() async {
    try {
      final res = await ApiService.initiateCustomerWithdrawal(
        _posController.text,
        double.parse(_amountController.text).toDouble(),
        _currency,
      );
      _showSuccessDialog(res);
    } catch (e) {
      if (mounted) {
        setState(() {
          _branchName = null;
          _agentName = null;
        });
        ErrorDialog.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
