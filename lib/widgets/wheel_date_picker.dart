import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class WheelDatePicker extends StatefulWidget {
  final String title;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool isDarkMode;

  const WheelDatePicker({
    super.key,
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.isDarkMode,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isDarkMode = false,
  }) async {
    return showDialog<DateTime>(
      context: context,
      builder:
          (context) => WheelDatePicker(
            title: title,
            initialDate: initialDate ?? DateTime.now(),
            firstDate: firstDate ?? DateTime(1950),
            lastDate: lastDate ?? DateTime(2100),
            isDarkMode: isDarkMode,
          ),
    );
  }

  @override
  State<WheelDatePicker> createState() => _WheelDatePickerState();
}

class _WheelDatePickerState extends State<WheelDatePicker> {
  late DateTime selectedDate;
  late FixedExtentScrollController yearController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController dayController;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;

    // Ensure initial date is within bounds
    if (selectedDate.isBefore(widget.firstDate)) {
      selectedDate = widget.firstDate;
    }
    if (selectedDate.isAfter(widget.lastDate)) selectedDate = widget.lastDate;

    yearController = FixedExtentScrollController(
      initialItem: selectedDate.year - widget.firstDate.year,
    );
    monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );
  }

  @override
  void dispose() {
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) return 29;
      return 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: textColor.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: GoogleFonts.cairo(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 40), // Balance the X icon
                        ],
                      ),
            const SizedBox(height: 30),

            SizedBox(
              height: 180,
              child: Stack(
                children: [
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
                          count:
                              widget.lastDate.year - widget.firstDate.year + 1,
                          controller: yearController,
                          onChanged: (val) {
                            setState(() {
                              final y = widget.firstDate.year + val;
                              final dCount = _daysInMonth(
                                y,
                                selectedDate.month,
                              );
                              if (selectedDate.day > dCount) {
                                dayController.jumpToItem(dCount - 1);
                              }
                              selectedDate = DateTime(
                                y,
                                selectedDate.month,
                                selectedDate.day > dCount
                                    ? dCount
                                    : selectedDate.day,
                              );
                            });
                          },
                          itemBuilder: (context, index) {
                            final y = widget.firstDate.year + index;
                            final isSelected = selectedDate.year == y;
                            return _buildWheelItem(
                              y.toString(),
                              isSelected,
                              textColor,
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
                            setState(() {
                              final m = val + 1;
                              final dCount = _daysInMonth(selectedDate.year, m);
                              if (selectedDate.day > dCount) {
                                dayController.jumpToItem(dCount - 1);
                              }
                              selectedDate = DateTime(
                                selectedDate.year,
                                m,
                                selectedDate.day > dCount
                                    ? dCount
                                    : selectedDate.day,
                              );
                            });
                          },
                          itemBuilder: (context, index) {
                            final m = index + 1;
                            final isSelected = selectedDate.month == m;
                            return _buildWheelItem(
                              m.toString(),
                              isSelected,
                              textColor,
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
                            setState(() {
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                val + 1,
                              );
                            });
                          },
                          itemBuilder: (context, index) {
                            final d = index + 1;
                            final isSelected = selectedDate.day == d;
                            return _buildWheelItem(
                              d.toString(),
                              isSelected,
                              textColor,
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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedDate),
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

  Widget _buildWheelItem(String label, bool isSelected, Color textColor) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: isSelected ? AppColors.accentBlue : textColor.withValues(alpha: 0.5),
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
