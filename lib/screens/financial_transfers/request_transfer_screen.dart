import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import 'package:flutter/services.dart';
import '../../helper/arabic_numbers_helper.dart';
import '../account_confirmation_screen.dart';

class RequestTransferScreen extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final List<String> services;
  final String? initialId;

  const RequestTransferScreen({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.services,
    this.initialId,
  });

  @override
  State<RequestTransferScreen> createState() => _RequestTransferScreenState();
}

class _RequestTransferScreenState extends State<RequestTransferScreen> {
  final _idController = TextEditingController();
  final _notesController = TextEditingController();
  late String _selectedService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedService =
        widget.services.isNotEmpty ? widget.services[0] : 'select_service'.tr();
    if (widget.initialId != null) {
      _idController.text = widget.initialId!;
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
                            const SizedBox(height: 5),
                            // Top Icon with styling
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
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
                                  size: 35,
                                ),
                              ),
                            ),
      
                            const SizedBox(height: 15),
      
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(10),
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
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'info_only_receive_yours'.tr(),
                                      style: TextStyle(
                                        color: AppColors.adaptiveText(
                                          widget.isDarkMode,
                                          lightColor: AppColors.primaryBlue,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
      
                            const SizedBox(height: 20),
      
                            // Service Dropdown
                            _buildPremiumDropdownField(
                              label: 'service_label'.tr(),
                              value: _selectedService,
                              items: widget.services,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedService = val);
                                }
                              },
                            ),
      
                            const SizedBox(height: 8),
      
                            // ID Field
                            _buildPremiumTextField(
                              controller: _idController,
                              label: 'remittance_id_label'.tr(),
                              hint: 'remittance_id_hint'.tr(),
                              icon: Icons.numbers_rounded,
                              inputFormatters: [
                                ArabicToEnglishNumbersFormatter(),
                              ],
                            ),
      
                            const SizedBox(height: 8),
      
                            // Notes Field
                            _buildPremiumTextField(
                              controller: _notesController,
                              label: 'notes_label'.tr(),
                              hint: 'notes_hint'.tr(),
                              icon: Icons.notes_rounded,
                              maxLines: 2,
                            ),
      
                            const SizedBox(height: 15),
      
                            // Continue Button
                            _buildPremiumSubmitButton(),
                            const SizedBox(height: 10),
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
          Expanded(
            child: Text(
              widget.title.tr(),
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

  Widget _buildPremiumDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
          padding: const EdgeInsets.symmetric(horizontal: 15),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor:
                  widget.isDarkMode ? AppColors.cardDark : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
              ),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              items:
                  items.map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val.tr()),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.adaptiveIcon(widget.isDarkMode),
                size: 22,
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

  Widget _buildPremiumSubmitButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () async {
          if (_idController.text.trim().isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('enter_remittance_id_snackbar'.tr()))
             );
             return;
          }

          if (!await ApiService.checkVerification(
            context,
            isDarkMode: widget.isDarkMode,
            onVerifyNavigate: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountConfirmationScreen(
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            ),
          )) {
            return;
          }

          setState(() => _isLoading = true);

          try {
            final remittanceType = widget.title.contains('دولية') ? 'INTERNATIONAL' : 'LOCAL';
            
            final Map<String, dynamic> data = {
              'remittance_number': _idController.text.trim(),
              'code_name_network': 'S', // Default character as requested
              'remittance_type': remittanceType,
            };

            if (_notesController.text.trim().isNotEmpty) {
              data['notes'] = _notesController.text.trim();
            }

            final result = await ApiService.submitReceiptRequest(data);
            
            if (mounted) {
               showDialog(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                   title: const Icon(Icons.check_circle_outline, color: Colors.green, size: 50),
                   content: Text(
                     result['message'] ?? 'request_sent_success'.tr(),
                     textAlign: TextAlign.center,
                     style: TextStyle(
                       color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                       fontWeight: FontWeight.bold
                     ),
                   ),
                   actions: [
                     Center(
                       child: ElevatedButton(
                         onPressed: () {
                           Navigator.pop(ctx);
                           Navigator.of(context).popUntil((route) => route.isFirst);
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primaryBlue,
                         ),
                         child: Text('ok_button'.tr(), style: const TextStyle(color: Colors.white)),
                       )
                     )
                   ]
                 )
               );
            }
          } catch (e) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                 ),
               );
             }
          } finally {
             if (mounted) {
                setState(() => _isLoading = false);
             }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading 
            ? const SizedBox(
                width: 22, height: 22, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              ) 
            : Text(
          'continue_button'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
