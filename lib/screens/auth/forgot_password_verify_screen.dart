import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import 'otp_verification_screen.dart';
import '../../components/qr_scanner_screen.dart';

class ForgotPasswordVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isDarkMode;

  const ForgotPasswordVerifyScreen({
    super.key,
    required this.phoneNumber,
    required this.isDarkMode,
  });

  @override
  State<ForgotPasswordVerifyScreen> createState() => _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState extends State<ForgotPasswordVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _idNumberController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _showWheelDatePicker() {
    final now = DateTime.now();
    int selectedY = _selectedDate?.year ?? 2000;
    int selectedM = _selectedDate?.month ?? 1;
    int selectedD = _selectedDate?.day ?? 1;

    final FixedExtentScrollController yearController =
        FixedExtentScrollController(initialItem: selectedY - 1940);
    final FixedExtentScrollController monthController =
        FixedExtentScrollController(initialItem: selectedM - 1);
    final FixedExtentScrollController dayController =
        FixedExtentScrollController(initialItem: selectedD - 1);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysCount = _daysInMonth(selectedY, selectedM);

            return Material(
              color: Colors.transparent,
              child: Container(
                height: 350,
                padding: const EdgeInsets.only(top: 6.0),
                color: widget.isDarkMode ? AppColors.scaffoldDark : Colors.white,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'cancel_button'.tr(),
                                style: GoogleFonts.cairo(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            Text(
                              'select_dob_title'.tr(),
                              style: GoogleFonts.cairo(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(selectedY, selectedM, selectedD);
                                  _dobController.text =
                                      "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
                                });
                                Navigator.pop(context);
                              },
                              child: Text(
                                'done_button'.tr(),
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  // السنة
                                  Expanded(
                                    flex: 3,
                                    child: _buildWheel(
                                      count: now.year - 1939,
                                      controller: yearController,
                                      onChanged: (index) {
                                        setModalState(() {
                                          selectedY = 1940 + index;
                                          final maxD = _daysInMonth(selectedY, selectedM);
                                          if (selectedD > maxD) selectedD = maxD;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final y = 1940 + index;
                                        final isSelected = y == selectedY;
                                        return _buildWheelItem(y.toString(), isSelected);
                                      },
                                    ),
                                  ),
                                  // الشهر
                                  Expanded(
                                    flex: 2,
                                    child: _buildWheel(
                                      count: 12,
                                      controller: monthController,
                                      onChanged: (index) {
                                        setModalState(() {
                                          selectedM = index + 1;
                                          final maxD = _daysInMonth(selectedY, selectedM);
                                          if (selectedD > maxD) selectedD = maxD;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final m = index + 1;
                                        final isSelected = m == selectedM;
                                        return _buildWheelItem(m.toString(), isSelected);
                                      },
                                    ),
                                  ),
                                  // اليوم
                                  Expanded(
                                    flex: 2,
                                    child: _buildWheel(
                                      count: daysCount,
                                      controller: dayController,
                                      onChanged: (index) {
                                        setModalState(() {
                                          selectedD = index + 1;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final d = index + 1;
                                        final isSelected = d == selectedD;
                                        return _buildWheelItem(d.toString(), isSelected);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) return 29;
      return 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  Widget _buildWheel({
    required int count,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: itemBuilder,
      ),
    );
  }

  Widget _buildWheelItem(String label, bool isSelected) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: isSelected
              ? AppColors.accentBlue
              : (widget.isDarkMode ? Colors.white70 : Colors.black54),
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final idNumber = _idNumberController.text.trim();
      final response = await ApiService.forgotPasswordVerify(
        username: phone, // Using phone as username
        phone: phone,
        idNumber: idNumber,
        dob: _dobController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'verification_sent_default'.tr())),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            isDarkMode: widget.isDarkMode,
            phoneNumber: phone,
            isForgotPassword: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('error_title'.tr(), e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok_button'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final cardColor = widget.isDarkMode ? AppColors.cardDark : Colors.white;
    final borderColor = widget.isDarkMode ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: widget.isDarkMode ? AppColors.scaffoldDark : Colors.grey[50],
      appBar: AppBar(
        title: Text('forgot_password_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textColor),
              const SizedBox(height: 30),
              _buildTextField(
                label: 'phone_label'.tr(),
                controller: _phoneController,
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                textColor: textColor,
                cardColor: cardColor,
                borderColor: borderColor,
                maxLength: 9,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'phone_required'.tr();
                  if (v.length != 9) return 'phone_length_error'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'id_label'.tr(),
                controller: _idNumberController,
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                textColor: textColor,
                cardColor: cardColor,
                borderColor: borderColor,
                maxLength: 11,
                suffixIcon: IconButton(
                  icon: Icon(Icons.barcode_reader, color: AppColors.primaryBlue),
                  onPressed: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => QRScannerScreen(
                        isDarkMode: widget.isDarkMode,
                        mode: ScannerMode.barcode,
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _idNumberController.text = result;
                      });
                    }
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'id_required'.tr();
                  if (v.length != 11) return 'id_length_error'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showWheelDatePicker,
                child: AbsorbPointer(
                  child: _buildTextField(
                    label: 'dob_label'.tr(),
                    controller: _dobController,
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.datetime,
                    textColor: textColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    hint: 'dob_hint'.tr(),
                    validator: (v) => (v == null || v.isEmpty) ? 'dob_required'.tr() : null,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'identity_confirmation_title'.tr(),
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'identity_confirmation_subtitle'.tr(),
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color textColor,
    required Color cardColor,
    required Color borderColor,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? hint,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: TextStyle(color: textColor),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
            filled: true,
            fillColor: cardColor,
            counterText: "",
            prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 22),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'confirm_data_button'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
