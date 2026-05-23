import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/receipt_dialog.dart';
import '../components/security_verification_dialog.dart';
import '../helper/counvert_amunt_helper.dart';

class CreateHassalaScreen extends StatefulWidget {
  final bool isDarkMode;

  const CreateHassalaScreen({super.key, required this.isDarkMode});

  @override
  State<CreateHassalaScreen> createState() => _CreateHassalaScreenState();
}

class _CreateHassalaScreenState extends State<CreateHassalaScreen> {
  final _nameController = TextEditingController();
  final _initialAmountController = TextEditingController();
  final _goalAmountController = TextEditingController();
  DateTime? _selectedDate;
  String _unlockType = 'limit'; // 'limit' or 'date'
  bool _isSubmitting = false;

  Future<void> _handleCreate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم الحصالة')));
      return;
    }

    final initialAmount = double.tryParse(_initialAmountController.text) ?? 0.0;
    if (initialAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المبلغ الابتدائي يجب أن يكون أكبر من صفر'),
        ),
      );
      return;
    }

    double? targetLimit;
    if (_unlockType == 'limit') {
      targetLimit = double.tryParse(_goalAmountController.text);
      if (targetLimit == null || targetLimit <= initialAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('سقف الحصالة يجب أن يكون أكبر من المبلغ الابتدائي'),
          ),
        );
        return;
      }
    } else {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار تاريخ الفتح')),
        );
        return;
      }
    }

    // 🔐 التحقق من الهوية (بصمة/كلمة مرور) قبل الإنشاء
    final authenticated = await SecurityVerificationDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
    );

    if (authenticated != true) return;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'initial_amount': initialAmount,
        'unlock_type': _unlockType,
        'currency': 'YER', // Defaulting to YER as per current UI
      };

      if (_unlockType == 'limit') {
        data['target_limit'] = targetLimit;
      } else {
        data['unlock_date'] = DateFormat('yyyy-MM-dd', 'en_US').format(_selectedDate!);
      }

      final response = await ApiService.createHassala(data);

      if (mounted) {
        await ReceiptDialog.show(
          context,
          isDarkMode: widget.isDarkMode,
          title: 'إيصال إنشاء حصالة جديدة',
          mainAmount: formatAmountDisplay(initialAmount),
          mainCurrency: 'YER',
          details: [
            ReceiptRowData(label: 'اسم الحصالة', value: _nameController.text),
            ReceiptRowData(label: 'رقم المرجع', value: response['reference_number'] ?? 'N/A', isCopyable: true),
            ReceiptRowData(
              label: 'نوع الفتح',
              value: _unlockType == 'limit' ? 'عند الوصول لمبلغ' : 'في تاريخ محدد',
            ),
            ReceiptRowData(
              label: 'الهدف',
              value: _unlockType == 'limit' 
                  ? '${_goalAmountController.text} YER' 
                  : DateFormat('yyyy-MM-dd', 'en_US').format(_selectedDate!),
            ),
            ReceiptRowData(label: 'التاريخ', value: DateFormat('yyyy-MM-dd HH:mm', 'en_US').format(DateTime.now())),
          ],
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'فشل الإنشاء',
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
                  'create_saving_title'.tr(),
                  () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('saving_name_label'.tr()),
                        _buildTextField(
                          _nameController,
                          Icons.edit_rounded,
                          'اسم الادخار...',
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('initial_amount_label'.tr()),
                        _buildTextField(
                          _initialAmountController,
                          Icons.account_balance_wallet_rounded,
                          '0.00',
                          isNumber: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'^[0.]')),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('unlock_condition'.tr()),
                        _buildUnlockSelector(),
                        const SizedBox(height: 24),

                        if (_unlockType == 'limit') ...[
                          _buildLabel('goal_amount_label'.tr()),
                          _buildTextField(
                            _goalAmountController,
                            Icons.flag_rounded,
                            '0.00',
                            isNumber: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'^[0.]')),
                            ],
                          ),
                        ] else ...[
                          _buildLabel('unlock_date_label'.tr()),
                          _buildDatePicker(),
                        ],

                        const SizedBox(height: 40),
                        _buildCreateButton(),
                      ],
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isNumber = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: inputFormatters,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            color: widget.isDarkMode ? Colors.white38 : Colors.grey.shade400,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: widget.isDarkMode ? Colors.white : AppColors.primaryBlue,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildUnlockSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectorOption(
            'limit',
            'by_goal_amount'.tr(),
            Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorOption(
            'date',
            'by_specific_date'.tr(),
            Icons.calendar_today_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorOption(String type, String title, IconData icon) {
    bool isSelected = _unlockType == type;
    return GestureDetector(
      onTap: () => setState(() => _unlockType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue
                  : (widget.isDarkMode ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primaryBlue
                    : (widget.isDarkMode ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Colors.white
                      : (widget.isDarkMode
                          ? Colors.white
                          : AppColors.primaryBlue),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                color:
                    isSelected
                        ? Colors.white
                        : (widget.isDarkMode ? Colors.white : Colors.black87),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showWheelDatePicker(
    String title,
    Function(DateTime) onSelect, {
    DateTime? initialDate,
  }) {
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 3650));

    DateTime selectedDate =
        initialDate ?? DateTime.now().add(const Duration(days: 1));
    // Ensure selected date is within bounds
    if (selectedDate.isBefore(firstDate)) selectedDate = firstDate;
    if (selectedDate.isAfter(lastDate)) selectedDate = lastDate;

    // Controllers
    final yearController = FixedExtentScrollController(
      initialItem: selectedDate.year - firstDate.year,
    );
    final monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    final dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );

    final dialogBg = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final dialogTextColor =
        widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final dialogSubTextColor =
        widget.isDarkMode ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with X
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: dialogSubTextColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: dialogTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // The 3 Wheels
                      SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            // Highlight overlay
                            Center(
                              child: Container(
                                height: 45,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Year
                                Expanded(
                                  flex: 2,
                                  child: _buildWheel(
                                    count: lastDate.year - firstDate.year + 1,
                                    controller: yearController,
                                    onChanged: (val) {
                                      final y = firstDate.year + val;
                                      final dCount = _daysInMonth(
                                        y,
                                        selectedDate.month,
                                      );
                                      if (selectedDate.day > dCount) {
                                        dayController.jumpToItem(dCount - 1);
                                      }
                                      setDialogState(
                                        () =>
                                            selectedDate = DateTime(
                                              y,
                                              selectedDate.month,
                                              selectedDate.day > dCount
                                                  ? dCount
                                                  : selectedDate.day,
                                            ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final y = firstDate.year + index;
                                      final isSelected = selectedDate.year == y;
                                      return _buildWheelItem(
                                        y.toString(),
                                        isSelected,
                                        dialogSubTextColor,
                                      );
                                    },
                                  ),
                                ),
                                // Month
                                Expanded(
                                  flex: 1,
                                  child: _buildWheel(
                                    count: 12,
                                    controller: monthController,
                                    onChanged: (val) {
                                      final m = val + 1;
                                      final dCount = _daysInMonth(
                                        selectedDate.year,
                                        m,
                                      );
                                      if (selectedDate.day > dCount) {
                                        dayController.jumpToItem(dCount - 1);
                                      }
                                      setDialogState(
                                        () =>
                                            selectedDate = DateTime(
                                              selectedDate.year,
                                              m,
                                              selectedDate.day > dCount
                                                  ? dCount
                                                  : selectedDate.day,
                                            ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final m = index + 1;
                                      final isSelected =
                                          selectedDate.month == m;
                                      return _buildWheelItem(
                                        m.toString(),
                                        isSelected,
                                        dialogSubTextColor,
                                      );
                                    },
                                  ),
                                ),
                                // Day
                                Expanded(
                                  flex: 1,
                                  child: _buildWheel(
                                    count: _daysInMonth(
                                      selectedDate.year,
                                      selectedDate.month,
                                    ),
                                    controller: dayController,
                                    onChanged: (val) {
                                      setDialogState(
                                        () =>
                                            selectedDate = DateTime(
                                              selectedDate.year,
                                              selectedDate.month,
                                              val + 1,
                                            ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final d = index + 1;
                                      final isSelected = selectedDate.day == d;
                                      return _buildWheelItem(
                                        d.toString(),
                                        isSelected,
                                        dialogSubTextColor,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Big Blue Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            onSelect(selectedDate);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'حسنًا',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
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

  Widget _buildWheelItem(String label, bool isSelected, Color subTextColor) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: isSelected ? AppColors.accentBlue : subTextColor,
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () {
        _showWheelDatePicker(
          'unlock_date_label'.tr(),
          (date) => setState(() => _selectedDate = date),
          initialDate: _selectedDate,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: widget.isDarkMode ? Colors.white : AppColors.primaryBlue,
            ),
            Text(
              _selectedDate == null
                  ? 'اختر التاريخ...'
                  : DateFormat('yyyy/MM/dd', 'en_US').format(_selectedDate!),
              style: GoogleFonts.cairo(
                color:
                    _selectedDate == null
                        ? (widget.isDarkMode
                            ? Colors.white38
                            : Colors.grey.shade400)
                        : (widget.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
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
        onPressed: _isSubmitting ? null : _handleCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'create_button'.tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
