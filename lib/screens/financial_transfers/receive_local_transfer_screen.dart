import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:saifix/helper/custom_print_helper.dart';
import '../account_confirmation_screen.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/remittance_networks.dart';
import '../../components/security_confirmation_dialog.dart';
import '../../components/transaction_details_bottom_sheet.dart';
import '../../components/loading_overlay.dart';
import '../../services/sound_service.dart';
import '../../widgets/receipt_dialog.dart';
import '../../helper/counvert_amunt_helper.dart';
import '../../helper/arabic_numbers_helper.dart';
import 'request_transfer_screen.dart';

class ReceiveLocalTransferScreen extends StatefulWidget {
  final bool isDarkMode;
  const ReceiveLocalTransferScreen({super.key, required this.isDarkMode});

  @override
  State<ReceiveLocalTransferScreen> createState() =>
      _ReceiveLocalTransferScreenState();
}

class _ReceiveLocalTransferScreenState
    extends State<ReceiveLocalTransferScreen> {
  final _transferIdController = TextEditingController();
  Map<String, dynamic>? _remittanceData;
  bool _isLoading = false;
  bool _isSaifiCash = false;
  Map<String, String>? _detectedNetwork;
  List<RemittanceNetwork> _dynamicNetworks = [];

  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _transferIdController.addListener(_onTransferIdChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDynamicNetworks();
    });
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _transferIdController.removeListener(_onTransferIdChanged);
    _transferIdController.dispose();
    super.dispose();
  }

  void _onTransferIdChanged() {
    final text = _transferIdController.text.trim();
    final network = _detectNetwork(text);
    if (mounted) {
      setState(() {
        _detectedNetwork = network;
      });
    }
  }

  Map<String, String>? _detectNetwork(String value) {
    if (value.isEmpty) return null;

    if (value.startsWith('SP-')) {
      return {'name': 'الصيفي كاش', 'logo': 'assets/images/logo_circle.png'};
    }

    if (value.startsWith('11')) {
      return {
        'name': 'شبكة الامتياز',
        'logo': 'assets/images/networks/alemtiyaz.png',
      };
    }
    if (value.startsWith('22')) {
      return {
        'name': 'شبكة المميز',
        'logo': 'assets/images/networks/almomayaz.png',
      };
    }
    if (value.startsWith('33')) {
      return {'name': 'البرق', 'logo': 'assets/images/networks/albarq.png'};
    }
    if (value.startsWith('400') || value.startsWith('402')) {
      return {'name': 'الاكوع', 'logo': 'assets/images/networks/alakwa.png'};
    }
    if (value.startsWith('55')) {
      return {'name': 'الحزمي', 'logo': 'assets/images/networks/hazmi.png'};
    }
    if (value.startsWith('88')) {
      return {'name': 'الناصر', 'logo': 'assets/images/networks/alnasser.png'};
    }
    if (value.startsWith('99')) {
      return {'name': 'دادية', 'logo': 'assets/images/networks/alhatar.png'};
    }
    if (value.startsWith('10')) {
      return {'name': 'العامري', 'logo': 'assets/images/networks/alamri.png'};
    }
    if (value.startsWith('304')) {
      return {
        'name': 'مال موني',
        'logo': 'assets/images/networks/mal_money.png',
      };
    }
    if (value.startsWith('50')) {
      return {
        'name': 'ايمن اكسبرس',
        'logo': 'assets/images/networks/yemen_express.png',
      };
    }
    if (value.startsWith('25')) {
      return {
        'name': 'الشركة اليمنيه',
        'logo': 'assets/images/networks/yemeni_network.png',
      };
    }
    if (value.startsWith('2004') || value.startsWith('2005')) {
      return {
        'name': 'اتش بي فاست',
        'logo': 'assets/images/networks/alhoushabi.png',
      };
    }
    if (value.startsWith('3') && value.length >= 2) {
      // Assuming it detects "Ocean" if it starts with 3 and potentially reaches 10 digits as requested
      return {'name': 'المحيط', 'logo': 'assets/images/networks/alocean.png'};
    }

    return null;
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await ApiService.getMe();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      customPrint('Error fetching current user: $e');
    }
  }

  Future<void> _loadDynamicNetworks() async {
    // final String lang =
    //     (intl.Intl.getCurrentLocale().startsWith('ar')) ? 'ar' : 'en';
    String lang = context.locale.languageCode;
    final dynamicNets = await ApiService.getRemittanceNetworks(lang);
    if (mounted && dynamicNets.isNotEmpty) {
      setState(() {
        // Filter out Saifi Cash/Pay if they are already in the hardcoded list
        _dynamicNetworks =
            dynamicNets.where((net) {
              final code = net.networkCode.toUpperCase();
              return !code.contains('SAIFI') &&
                  !code.contains('CASH') &&
                  !code.contains('PAY');
            }).toList();
      });
    }
  }

  final List<Map<String, String>> networks = [
    {'name': 'saifi_cash'.tr(), 'logo': 'assets/images/pr_logo.png'},
    {'name': 'saifi_pay'.tr(), 'logo': 'assets/images/logo_circle.png'},
  ];

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
                                      Icons.security_rounded,
                                      color: AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                                      size: 30,
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
                                      'warning_rule_text'.tr(),
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

                            if (_detectedNetwork != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: AppColors.accentBlue.withValues(alpha: 
                                      0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 
                                              0.05,
                                            ),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: _buildNetworkLogo(
                                        _detectedNetwork!['logo']!,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'network_detected'.tr(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _detectedNetwork!['name']!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  widget.isDarkMode
                                                      ? Colors.white
                                                      : AppColors.textBlack,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green.shade400,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ).animate().fade().slideY(begin: 0.1, end: 0),
                            ],

                            const SizedBox(height: 25),

                            // Search Button
                            _buildPremiumSubmitButton(),

                            if (_remittanceData != null) ...[
                              const SizedBox(height: 30),
                              _buildRemittanceDetailsCard(),
                            ],

                            const SizedBox(height: 40),

                            // Helper Text
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.adaptiveIcon(
                                      widget.isDarkMode,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'networks_header'.tr(),
                                  style: TextStyle(
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white
                                            : AppColors.textBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            // Networks Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 1.3,
                                  ),
                              itemCount:
                                  networks.length + _dynamicNetworks.length,
                              itemBuilder: (context, index) {
                                final bool isHardcoded =
                                    index < networks.length;
                                final network =
                                    isHardcoded
                                        ? networks[index]
                                        : _dynamicNetworks[index -
                                            networks.length];

                                final String logo =
                                    isHardcoded
                                        ? (network
                                                as Map<
                                                  String,
                                                  String
                                                >)['logo'] ??
                                            ''
                                        : (network as RemittanceNetwork).icon;
                                return Container(
                                      decoration: BoxDecoration(
                                        color:
                                            widget.isDarkMode
                                                ? AppColors.cardDark
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white.withValues(alpha: 
                                                    0.05,
                                                  )
                                                  : Colors.grey.shade100,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 
                                              widget.isDarkMode ? 0.2 : 0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Center(
                                        child: _buildNetworkLogo(logo),
                                      ),
                                    )
                                    .animate(delay: (index * 50).ms)
                                    .fade(duration: 400.ms)
                                    .scale(begin: const Offset(0.9, 0.9));
                              },
                            ),
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
          if (_isLoading)
            LoadingOverlay(
              isDarkMode: widget.isDarkMode,
              message: 'receiving_overlay_message'.tr(),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkLogo(String logo) {
    if (logo.isEmpty) return _buildDefaultIcon();

    if (logo.startsWith('http')) {
      return Image.network(
        logo,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    } else if (logo.startsWith('assets/') || logo.contains('.png')) {
      // Handle the case where hardcoded logos might be just filename or full path
      final String path =
          logo.startsWith('assets/') ? logo : 'assets/images/$logo';
      return Image.asset(
        path,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.business_rounded,
      color: AppColors.adaptiveIcon(widget.isDarkMode),
      size: 30,
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
            'screen_title'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
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
            inputFormatters: [
              ArabicToEnglishNumbersFormatter(),
              FilteringTextInputFormatter.digitsOnly,
            ],
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
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Future<void> _searchRemittance() async {
    final number = _transferIdController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'enter_transfer_id_snackbar'.tr(),
            style: const TextStyle(),
          ),
        ),
      );
      return;
    }

    final isSaifiCash = number.startsWith('SP-');

    if (!isSaifiCash && _detectedNetwork == null) {
      _showUnrecognizedNetworkDialog(number);
      return;
    }

    setState(() {
      _isLoading = true;
      _remittanceData = null;
      _isSaifiCash = isSaifiCash;
    });

    try {
      if (_isSaifiCash) {
        final result = await ApiService.receiveSaifiCashEnquiry(number);
        if (result['status'] == 'success') {
          setState(() {
            _remittanceData = result['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(result['message'] ?? 'فشل الاستعلام');
        }
      } else {
        final result = await ApiService.queryRemittance(number);
        setState(() {
          _remittanceData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showProfessionalError(e.toString().replaceAll('Exception: ', ''));
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
                    SnackBar(
                      content: Text(
                        'remittance_copied_snackbar'.tr(),
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                },
                tooltip: 'copy_remittance_tooltip'.tr(),
              ),
            ],
          ),
          const Divider(height: 30),
          _buildDetailRow(
            'sender_label'.tr(),
            _isSaifiCash
                ? (data['sndr_name'] ?? '---')
                : (data['sender_name'] ?? 'unknown'.tr()),
          ),
          _buildDetailRow(
            'amount_label'.tr(),
            _isSaifiCash
                ? '${formatAmountDisplay(double.tryParse(data['rmt_amt']?.toString() ?? '0') ?? 0.0)} ${data['rmt_ccy'] ?? ''}'
                : '${formatAmountDisplay(double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0)} ${data['currency'] ?? ''}',
          ),
          _buildDetailRow(
            'recipient_label'.tr(),
            _isSaifiCash
                ? (data['bnf_name'] ?? '---')
                : (data['recipient_name'] ?? 'unknown'.tr()),
          ),
          if (!_isSaifiCash)
            _buildDetailRow(
              'status_label'.tr(),
              _translateStatus(data['status']),
            ),
          if (!_isSaifiCash && data['operation_id'] != null)
            _buildDetailRow(
              'operation_id_label'.tr(),
              data['operation_id'].toString(),
            ),
          const SizedBox(height: 25),
          () {
            bool matches = false;
            if (_currentUser != null) {
              final userName = _currentUser?['full_name']?.toString() ?? '';
              final userPhone = _currentUser?['phone_number']?.toString() ?? '';

              String clean(String s) => s.replaceAll(RegExp(r'\D'), '');

              if (_isSaifiCash) {
                final bnfName = data['bnf_name']?.toString() ?? '';
                final bnfPhone = data['bnf_phone']?.toString() ?? '';
                matches =
                    (bnfName.isNotEmpty && bnfName == userName) ||
                    (clean(bnfPhone).isNotEmpty &&
                        clean(bnfPhone) == clean(userPhone));
              } else {
                final recipientName = data['recipient_name']?.toString() ?? '';
                final recipientPhone =
                    data['recipient_phone']?.toString() ?? '';
                matches =
                    (recipientName.isNotEmpty && recipientName == userName) ||
                    (clean(recipientPhone).isNotEmpty &&
                        clean(recipientPhone) == clean(userPhone));
              }
            }

            if (matches && (_isSaifiCash || data['status'] == 'PENDING')) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _receiveRemittance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'confirm_receive_button'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            } else if (data['status'] == 'RECEIVED') {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'already_received_text'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            } else {
              // No match or not pending
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'mismatch_error_content'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            }
          }(),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
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
        return status ?? 'unknown'.tr();
    }
  }

  Future<void> _receiveRemittance() async {
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

    if (_isSaifiCash) {
      if (!mounted) return;
      TransactionDetailsBottomSheet.show(
        context,
        isDarkMode: widget.isDarkMode,
        amount: data['rmt_amt']?.toString() ?? '0.00',
        currency: data['rmt_ccy'] ?? '',
        transactionType: 'confirm_receive_transfer_title'.tr(),
        networkName: 'الصيفي كاش',
        recipientName:
            _currentUser?['full_name'] ?? _currentUser?['username'] ?? '---',
        recipientId:
            _currentUser?['phone_number'] ?? _currentUser?['username'] ?? '',
        senderName: data['sndr_name'] ?? '---',
        senderId: '',
        onExecute: () async {
          final result = await SecurityConfirmationDialog.show(
            context,
            isDarkMode: widget.isDarkMode,
          );

          if (result != null) {
            _executeReceiveRemittance(result is String ? result : null);
          }
        },
      );
      return;
    }

    try {
      final userData = await ApiService.getMe();
      final userPhone = userData['phone_number'] ?? userData['username'];
      final recipientPhone = data['recipient_phone'];

      if (!mounted) return;
      String clean(String p) => p.replaceAll(RegExp(r'\D'), '');

      if (clean(userPhone) != clean(recipientPhone)) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'mismatch_error_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                content: Text(
                  'mismatch_error_content'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('close_button'.tr()),
                  ),
                ],
              ),
        );
        return;
      }

      if (!mounted) return;
      TransactionDetailsBottomSheet.show(
        context,
        isDarkMode: widget.isDarkMode,
        amount: data['amount']?.toString() ?? '0.00',
        currency: data['currency'] ?? '',
        transactionType: 'confirm_receive_title'.tr(),
        networkName: _detectedNetwork?['name'] ?? 'شبكات محلية',
        recipientName: data['recipient_name'] ?? 'unknown'.tr(),
        recipientId: data['recipient_phone'] ?? '',
        senderName: data['sender_name'] ?? 'unknown'.tr(),
        senderId: '',
        onExecute: () async {
          final result = await SecurityConfirmationDialog.show(
            context,
            isDarkMode: widget.isDarkMode,
          );

          if (result != null) {
            _executeReceiveRemittance(
              result is String ? result : null,
              userData: userData,
            );
          }
        },
      );
    } catch (e) {
      _showProfessionalError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _executeReceiveRemittance(
    String? password, {
    Map<String, dynamic>? userData,
  }) async {
    if (_remittanceData == null) return;
    final data = _remittanceData!;
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> result;
      if (_isSaifiCash) {
        result = await ApiService.confirmSaifiCashReceipt(
          _transferIdController.text.trim(),
          data['rcv_rqst_no'],
        );
      } else {
        final payoutData = {
          "id_type": "WALLET_VR",
          "id_number": userData?['wallet_id'] ?? "0000000",
        };

        result = await ApiService.receiveRemittance(
          data['remittance_number'],
          payoutData,
          password ?? '',
          operationId: data['operation_id']?.toString() ?? '',
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        SoundService.playSuccessSound();

        final refNo = result['reference_number'] ?? result['ref_no'] ?? result['transaction_id'] ?? (_isSaifiCash ? data['rcv_rqst_no'] : data['remittance_number']) ?? '---';
        final balanceAfter = result['balance_after'] ?? result['wallet_balance'] ?? result['balance'] ?? '';
        final feeStr = result['fee'] ?? result['commission'] ?? '0.00';

        await ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title:
              _isSaifiCash ? 'تم استلام الحوالة بنجاح' : 'receipt_title'.tr(),
          mainAmount: formatAmountDisplay(
            double.tryParse(
                  (_isSaifiCash ? data['rmt_amt'] : data['amount'])
                          ?.toString() ??
                      '0',
                ) ??
                0.0,
          ),
          mainCurrency:
              (_isSaifiCash ? data['rmt_ccy'] : data['currency']) ?? '',
          details: [
            ReceiptRowData(
              label: 'المستفيد',
              value:
                  '${_currentUser?['full_name'] ?? _currentUser?['username'] ?? '---'}\n${_currentUser?['phone_number'] ?? _currentUser?['username'] ?? ''}',
            ),
            ReceiptRowData(
              label: 'المودع',
              value:
                  _isSaifiCash
                      ? (data['sndr_name'] ?? '---')
                      : (data['sender_name'] ?? 'unknown'.tr()),
            ),
            if (!_isSaifiCash)
              ReceiptRowData(
                label: 'system_prefix'.tr(),
                value: 'receipt_subtitle'.tr(),
              ),
            ReceiptRowData(
              label:
                  _isSaifiCash ? 'رقم الحوالة' : 'remittance_number_label'.tr(),
              value:
                  _isSaifiCash
                      ? _transferIdController.text.trim()
                      : (data['remittance_number']?.toString() ?? '---'),
              isCopyable: true,
            ),
            ReceiptRowData(
              label: 'رقم المرجع للعملية',
              value: refNo.toString(),
              isCopyable: true,
            ),
            if (double.tryParse(feeStr.toString()) != null && double.parse(feeStr.toString()) > 0)
              ReceiptRowData(
                label: 'الرسوم / العمولات',
                value: '${formatAmountDisplay(double.parse(feeStr.toString()))} ${(_isSaifiCash ? data['rmt_ccy'] : data['currency']) ?? ''}',
              ),
            if (balanceAfter.toString().isNotEmpty)
              ReceiptRowData(
                label: 'الرصيد بعد العملية',
                value: '${formatAmountDisplay(double.tryParse(balanceAfter.toString()) ?? 0.0)} ${(_isSaifiCash ? data['rmt_ccy'] : data['currency']) ?? ''}',
              ),
            ReceiptRowData(
              label: 'receipt_date_label'.tr(),
              value: intl.DateFormat(
                'dd/MM/yyyy HH:mm',
                'en_US',
              ).format(DateTime.now()),
            ),
          ],
          amountColor: Colors.green,
          shareText:
              _isSaifiCash
                  ? '✅ إيصال استلام حوالة - صيفي باي\n\n'
                    'مبلغ الحوالة: ${formatAmountDisplay(double.tryParse(data['rmt_amt']?.toString() ?? '0') ?? 0.0)} ${data['rmt_ccy'] ?? ''}\n'
                    'رقم الحوالة: ${_transferIdController.text.trim()}\n'
                    'رقم المرجع: $refNo\n'
                    'المرسل: ${data['sndr_name'] ?? '---'}\n'
                    'المستفيد: ${_currentUser?['full_name'] ?? _currentUser?['username'] ?? '---'}\n'
                  : '${'share_receipt_text'.tr()}\n\n'
                    '${'receipt_amount_label'.tr()}: ${formatAmountDisplay(double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0)} ${data['currency'] ?? ''}\n'
                    'رقم الحوالة: ${data['remittance_number']?.toString() ?? '---'}\n'
                    'رقم المرجع: $refNo\n'
                    '${'receipt_sender_label'.tr()}: ${data['sender_name'] ?? 'unknown'.tr()}\n'
                    '${'receipt_recipient_label'.tr()}: ${data['recipient_name'] ?? 'unknown'.tr()}\n',
        );
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showProfessionalError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showUnrecognizedNetworkDialog(String number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        title: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 50),
            const SizedBox(height: 10),
            Text(
              'لم يتم التعرف على شبكة الحوالات',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'يرجى رفع طلب استلام حوالة\n\nهل تريد الانتقال الى نافذه طلب استلام حوالة؟',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestTransferScreen(
                    isDarkMode: widget.isDarkMode,
                    title: 'request_local_title'.tr(),
                    services: [
                      'service_saifi_cash'.tr(),
                      'service_other_local'.tr(),
                    ],
                    initialId: number,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('موافق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
