import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../models/operation_history.dart';
import '../utils/operation_type_helper.dart';
import '../services/api_service.dart';
import '../widgets/transaction_item.dart';
import '../widgets/wheel_date_picker.dart';

class CustomSearchScreen extends StatefulWidget {
  const CustomSearchScreen({super.key});

  @override
  State<CustomSearchScreen> createState() => _CustomSearchScreenState();
}

class _CustomSearchScreenState extends State<CustomSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<OperationHistoryModel> _results = [];
  List<OperationHistoryModel> _filteredResults = [];
  bool _isLoading = false;
  String? _selectedType = '';

  final List<Map<String, String>> _types = [
    {'label': 'all'.tr(), 'value': ''},
    ...OperationTypeHelper.getOperationTypeLabels().entries.map(
      (e) => {'label': e.value, 'value': e.key},
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default to last 2 months
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 60));
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    String? formatDateOnly(DateTime? date, {bool useUtc = false}) {
      if (date == null) return null;
      final d = useUtc ? date.toUtc() : date.toLocal();
      // Ensure English numerals by using 'en' locale
      return intl.DateFormat('yyyy-MM-dd', 'en_US').format(d);
    }

    // استبدال السطور القديمة بهذه السطور البسيطة
    final startStr = formatDateOnly(_startDate);
    final endStr = formatDateOnly(_endDate);

    // final startStr =
    //     _startDate != null
    //         ? intl.DateFormat('yyyy-MM-dd').format(_startDate!)
    //         : null;
    // final endStr =
    //     _endDate != null
    //         ? intl.DateFormat('yyyy-MM-dd').format(_endDate!)
    //         : null;

    final response = await ApiService.getOperationsHistory(
      query: '', // We will filter locally now
      startDate: startStr,
      endDate: endStr,
      operationType: _selectedType == '' ? null : _selectedType,
      pageSize: 200, // Fetch more records to allow better local searching
    );

    setState(() {
      _results = response.results;
      _filterResults(); // Apply local filter immediately
      _isLoading = false;
    });
  }

  void _filterResults() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredResults = List.from(_results);
      } else {
        _filteredResults =
            _results.where((op) {
              final type = op.operationTypeDisplay.toLowerCase();
              final desc = op.description.toLowerCase();
              final user = op.relatedUserName?.toLowerCase() ?? '';
              final amount = op.amount.toString();
              final ref = op.referenceNumber.toLowerCase();

              return type.contains(query) ||
                  desc.contains(query) ||
                  user.contains(query) ||
                  amount.contains(query) ||
                  ref.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await WheelDatePicker.show(
      context,
      title: isStart ? 'from_date'.tr() : 'to_date'.tr(),
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      isDarkMode: isDark,
    );

    if (picked != null) {
      DateTime newStart =
          isStart
              ? picked
              : (_startDate ?? picked.subtract(const Duration(days: 60)));
      DateTime newEnd =
          isStart ? (_endDate ?? picked.add(const Duration(days: 60))) : picked;

      // Enforce 2 months range
      if (newEnd.difference(newStart).inDays > 60) {
        if (isStart) {
          // If start moved too far back, move end accordingly or clamp
          newEnd = newStart.add(const Duration(days: 60));
          if (newEnd.isAfter(DateTime.now())) {
            newEnd = DateTime.now();
            newStart = newEnd.subtract(const Duration(days: 60));
          }
        } else {
          // If end moved too far forward, move start accordingly
          newStart = newEnd.subtract(const Duration(days: 60));
        }

        if (mounted) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('range_limited'.tr()),
              backgroundColor: AppColors.accentBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      setState(() {
        _startDate = newStart;
        _endDate = newEnd;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(
                  'custom_search_title'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                _buildSearchHeader(isDark),
                _buildTypeFilter(isDark),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredResults.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.builder(
                            itemCount: _filteredResults.length,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemBuilder: (context, index) {
                              return TransactionItem(
                                model: _filteredResults[index],
                              ).animate().fade(delay: (index * 50).ms).slideX();
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _searchController.clear();
            _startDate = null;
            _endDate = null;
            _selectedType = '';
            _results = [];
            _filteredResults = [];
          });
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.refresh, color: Colors.white),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDark ? Colors.white : AppColors.textBlack,
                  size: 18,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterResults(),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textBlack,
              ),
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white70 : AppColors.primaryBlue,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDateButton(isDark, true),
              const SizedBox(width: 8),
              _buildDateButton(isDark, false),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDateButton(bool isDark, bool isStart) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectDate(context, isStart),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: isDark ? Colors.white70 : AppColors.primaryBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (isStart ? _startDate : _endDate) == null
                      ? (isStart ? 'from_date'.tr() : 'to_date'.tr())
                      : intl.DateFormat(
                        'yyyy/MM/dd',
                        'en_US',
                      ).format(isStart ? _startDate! : _endDate!),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _types.map((type) {
                final isSelected =
                    _selectedType == (type['value'] == '' ? '' : type['value']);
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(type['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType =
                            type['value'] == '' ? '' : type['value'];
                      });
                      _performSearch();
                    },
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.primaryBlue
                                : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'no_results'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fade();
  }
}
