import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/operation_type_helper.dart';
import '../../models/operation_history.dart';
import '../account_confirmation_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../widgets/wheel_date_picker.dart';
import '../../widgets/receipt_dialog.dart';
import '../../helper/counvert_amunt_helper.dart';

class AllTransactionsScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool isOpenFilter;
  final String? title;

  const AllTransactionsScreen({
    super.key,
    required this.isDarkMode,
    this.isOpenFilter = false,
    this.title,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  List<OperationHistoryModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int? _lastRequestedPage;
  final ScrollController _scrollController = ScrollController();

  // Filter state
  String _filterType = 'all';
  String _filterCurrency = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    // Default to last 2 months
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 60));

    if (widget.isOpenFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFilterSheet();
      });
    } else {
      _fetchTransactions();
    }

    _fetchUserData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchTransactions(loadMore: true);
      }
    }
  }

  String? _formatDateOnly(DateTime? d) {
    if (d == null) return null;
    return intl.DateFormat('yyyy-MM-dd', 'en_US').format(d);
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (_isLoading || (loadMore && _lastRequestedPage == _currentPage)) return;

    setState(() => _isLoading = true);
    if (loadMore) _lastRequestedPage = _currentPage;

    try {
      if (!loadMore) {
        _currentPage = 1;
        _transactions.clear();
      }

      final response = await ApiService.getOperationsHistory(
        page: _currentPage,
        pageSize: 15,
        operationType: _filterType == 'all' ? null : _filterType,
        currency: _filterCurrency == 'all' ? null : _filterCurrency,
        startDate: _formatDateOnly(_startDate),
        endDate: _formatDateOnly(_endDate),
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            // Prevent duplicates by checking reference_number or id
            for (var tx in response.results) {
              bool exists = _transactions.any(
                (existing) =>
                    (existing.referenceNumber == tx.referenceNumber) ||
                    (existing.id == tx.id),
              );
              if (!exists) {
                _transactions.add(tx);
              }
            }
          } else {
            _transactions = response.results;
            _lastRequestedPage = null; // Reset on refresh
          }

          _hasMore = response.results.length >= 15;
          if (_hasMore) {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'fetch_transactions_error'.tr().replaceFirst(
                '{error}',
                e.toString(),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _fetchTransactions();
  }

  void _applyFilter() {
      if (mounted) Navigator.pop(context);
      
    _fetchTransactions();
  }

  Future<void> _selectFilterDate(
    bool isStart,
    Function(void Function()) setModalState,
  ) async {
    final DateTime? picked = await WheelDatePicker.show(
      context,
      title: isStart ? 'wheel_date_from'.tr() : 'wheel_date_to'.tr(),
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      isDarkMode: widget.isDarkMode,
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
          newEnd = newStart.add(const Duration(days: 60));
          if (newEnd.isAfter(DateTime.now())) {
            newEnd = DateTime.now();
            newStart = newEnd.subtract(const Duration(days: 60));
          }
        } else {
          newStart = newEnd.subtract(const Duration(days: 60));
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('max_range_two_months'.tr()),
            backgroundColor: AppColors.accentBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setModalState(() {
        _startDate = newStart;
        _endDate = newEnd;
      });
    }
  }

  Future<void> _selectQuickDate(bool isStart) async {
    final DateTime? picked = await WheelDatePicker.show(
      context,
      title: isStart ? 'wheel_date_from'.tr() : 'wheel_date_to'.tr(),
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      isDarkMode: widget.isDarkMode,
    );

    if (picked != null) {
      if (!mounted) return;

      DateTime newStart =
          isStart
              ? picked
              : (_startDate ?? picked.subtract(const Duration(days: 60)));
      DateTime newEnd =
          isStart ? (_endDate ?? picked.add(const Duration(days: 60))) : picked;

      if (newEnd.difference(newStart).inDays > 60) {
        if (isStart) {
          newEnd = newStart.add(const Duration(days: 60));
          if (newEnd.isAfter(DateTime.now())) {
            newEnd = DateTime.now();
            newStart = newEnd.subtract(const Duration(days: 60));
          }
        } else {
          newStart = newEnd.subtract(const Duration(days: 60));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('max_range_two_months'.tr()),
            backgroundColor: AppColors.accentBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _startDate = newStart;
        _endDate = newEnd;
      });
      _fetchTransactions();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  decoration: BoxDecoration(
                    color:
                        widget.isDarkMode ? AppColors.cardDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header handle
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Title and close
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'filter_transactions_title'.tr(),
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white
                                        : AppColors.textBlack,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'close'.tr(),
                              icon: Icon(
                                Icons.close_rounded,
                                color:
                                    widget.isDarkMode
                                        ? Colors.white54
                                        : Colors.black54,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        const SizedBox(height: 15),
                        _buildFilterLabel('currency_label'.tr()),
                        _buildDropdown(
                          value: _filterCurrency,
                          items: ['all', 'YER', 'USD', 'SAR'],
                          labels: [
                            'filter_all'.tr(),
                            'yer'.tr(),
                            'usd'.tr(),
                            'sar'.tr(),
                          ],
                          onChanged:
                              (val) =>
                                  setModalState(() => _filterCurrency = val!),
                        ),
                        const SizedBox(height: 20),

                        _buildFilterLabel('filter_type_label'.tr()),
                        _buildDropdown(
                          value: _filterType,
                          items: [
                            'all',
                            ...OperationTypeHelper.getAllOperationTypes(),
                          ],
                          labels: [
                            'filter_all'.tr(),
                            ...OperationTypeHelper.getOperationTypeLabels()
                                .values
                                ,
                          ],
                          onChanged:
                              (val) => setModalState(() => _filterType = val!),
                        ),
                        const SizedBox(height: 20),

                        // Date Range
                        _buildFilterLabel('filter_date_range_label'.tr()),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 10,
                                      bottom: 5,
                                    ),
                                    child: Text(
                                      'from_label'.tr(),
                                      style: TextStyle(
                                        color:
                                            widget.isDarkMode
                                                ? Colors.white54
                                                : Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildDatePicker(
                                    context,
                                    _startDate,
                                    true,
                                    setModalState,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 10,
                                      bottom: 5,
                                    ),
                                    child: Text(
                                      'to_label'.tr(),
                                      style: TextStyle(
                                        color:
                                            widget.isDarkMode
                                                ? Colors.white54
                                                : Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildDatePicker(
                                    context,
                                    _endDate,
                                    false,
                                    setModalState,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.adaptiveIcon(
                                  widget.isDarkMode,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _applyFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'filter_apply'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white70 : AppColors.textBlack,

          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required List<String> labels,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color:
            widget.isDarkMode ? const Color(0xFF2A2A3A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor:
              widget.isDarkMode ? const Color(0xFF2A2A3A) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.adaptiveIcon(widget.isDarkMode),
          ),
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,

            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          items: List.generate(items.length, (index) {
            return DropdownMenuItem(
              value: items[index],
              child: Text(labels[index]),
            );
          }),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    DateTime? date,
    bool isStart,
    Function(void Function()) setModalState,
  ) {
    final String formattedDate =
        date != null
            ? intl.DateFormat('yyyy/MM/dd', 'en_US').format(date)
            : 'choose_date'.tr();

    return GestureDetector(
      onTap: () => _selectFilterDate(isStart, setModalState),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color:
              widget.isDarkMode
                  ? const Color(0xFF2A2A3A)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.adaptiveIcon(widget.isDarkMode),
            ),
            const SizedBox(width: 10),
            Text(
              formattedDate,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
                _buildQuickDateFilter(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.adaptiveIcon(widget.isDarkMode),
                    child:
                        _transactions.isEmpty && !_isLoading
                            ? _buildEmptyState()
                            : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount:
                                  _transactions.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _transactions.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildTransactionItem(
                                  _transactions[index],
                                );
                              },
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
          Text(
            widget.title ?? 'recent_transactions'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.adaptiveIcon(widget.isDarkMode),
                ),
                onPressed: _showFilterSheet,
              ),
              IconButton(
                icon: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.adaptiveIcon(widget.isDarkMode),
                ),
                onPressed: () async {
                  final verified = await ApiService.checkVerification(
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
                  );
                  if (!mounted) return;
                  if (!verified) return;
                  _generatePDF(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('no_transactions_to_export'.tr())));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userData = await ApiService.getMe();
      final String fullName =
          '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
              .trim();
      final String accountName =
          fullName.isNotEmpty ? fullName : (userData['username'] ?? 'مستخدم');
      final String accountNumber = userData['username']?.toString() ?? '-';

      final pdf = pw.Document();
      final arabicFont = await PdfGoogleFonts.cairoMedium();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();
      final logoImage = await rootBundle.load('assets/images/logo_circle.png');
      final logoBytes = logoImage.buffer.asUint8List();

      Map<String, List<OperationHistoryModel>> groupedTransactions = {};
      for (var tx in _transactions) {
        String currency = tx.currency.toUpperCase();

        if (!groupedTransactions.containsKey(currency)) {
          groupedTransactions[currency] = [];
        }
        groupedTransactions[currency]!.add(tx);
      }

      String getCurrencyNameAr(String code) {
        if (code == 'YER') return 'ريال يمني';
        if (code == 'SAR') return 'ريال سعودي';
        if (code == 'USD') return 'دولار امريكي';
        return code;
      }

      String maskName(String? name) {
        if (name == null || name.trim().isEmpty || name == '-') return '';
        final parts = name.trim().split(' ');
        List<String> maskedParts = [];
        for (var p in parts) {
          if (p.length <= 2) {
            maskedParts.add('**');
          } else {
            maskedParts.add('${p.substring(0, p.length - 2)}**');
          }
        }
        return maskedParts.join(' ');
      }



      List<pw.Widget> contentWidgets = [];

      contentWidgets.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(pw.MemoryImage(logoBytes), width: 80, height: 80),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'اسم العميل: $accountName',
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      );
      contentWidgets.add(pw.SizedBox(height: 15));

      contentWidgets.add(
        pw.Center(
          child: pw.Text(
            'كشف حساب بأخر العمليات / رقم الحساب $accountNumber',
            style: pw.TextStyle(font: arabicFontBold, fontSize: 14),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      );
      contentWidgets.add(pw.SizedBox(height: 15));

      pw.Widget buildCustomTable(
        List<OperationHistoryModel> txList,
        String currName,
      ) {
        double totalCredit = 0.0;
        double totalDebit = 0.0;

        List<pw.TableRow> rows = [];

        rows.add(
          pw.TableRow(
            children:
                [
                      'البيان',
                      'الرقم\nالمرجع',
                      'العملية',
                      'التاريخ',
                      'الرصيد',
                      'العملة',
                      'دائن',
                      'مدين',
                    ]
                    .map(
                      (e) => pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                          child: pw.Text(
                            e,
                            style: pw.TextStyle(
                              font: arabicFontBold,
                              fontSize: 10,
                              color: PdfColors.blue900,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        );

        for (var tx in txList) {
          final type = tx.operationType.toUpperCase();

          double amount = double.tryParse(tx.amount) ?? 0.0;
          double fee = double.tryParse(tx.fee) ?? 0.0;
          bool credit =
              type.contains('RECV') ||
              type.contains('DEPOSIT') ||
              type.contains('EARN');

          if (credit) {
            totalCredit += amount;
          } else {
            totalDebit += amount;
          }

          final partyName = maskName(tx.relatedUserName);
          final description = tx.description;
          final fullDescription =
              (partyName.isNotEmpty &&
                      partyName != '-' &&
                      !description.contains(partyName))
                  ? '$description - $partyName'
                  : description;

          // Add fee to description if present
          final descriptionWithFee =
              fee > 0
                  ? '$fullDescription (رسوم: ${formatAmountDisplay(fee)})'
                  : fullDescription;

          String createdAtStr = '-';
          try {
            createdAtStr = intl.DateFormat(
              '(HH:mm) yyyy-MM-dd',
              'en_US',
            ).format(tx.createdAt.toLocal());
          } catch (_) {}

          final operationTitle = tx.operationTypeDisplay;

          rows.add(
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    descriptionWithFee,
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      tx.referenceNumber.isNotEmpty
                          ? tx.referenceNumber
                          : 'N/A',
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      operationTitle,
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      createdAtStr,
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      formatAmountDisplay(
                        double.tryParse(tx.balanceAfter) ?? 0.0,
                      ),
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      currName,
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      credit ? formatAmountDisplay(amount) : '0',
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      !credit ? formatAmountDisplay(amount) : '0',
                      style: pw.TextStyle(font: arabicFont, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        rows.add(
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    'اجمالي الدائن',
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontSize: 10,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    formatAmountDisplay(totalCredit),
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    '0',
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        );

        rows.add(
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  '',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    'اجمالي المدين',
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontSize: 10,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    '0',
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    formatAmountDisplay(totalDebit),
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        );

        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(1),
            7: const pw.FlexColumnWidth(1),
          },
          children: rows,
        );
      }

      final currencies = ['YER', 'SAR', 'USD'];
      for (var curr in currencies) {
        if (!groupedTransactions.containsKey(curr)) continue;
        contentWidgets.add(
          buildCustomTable(groupedTransactions[curr]!, getCurrencyNameAr(curr)),
        );
        contentWidgets.add(pw.SizedBox(height: 15));
      }

      // Add any other unexpected currencies
      for (var curr in groupedTransactions.keys) {
        if (!currencies.contains(curr)) {
          contentWidgets.add(
            buildCustomTable(
              groupedTransactions[curr]!,
              getCurrencyNameAr(curr),
            ),
          );
          contentWidgets.add(pw.SizedBox(height: 15));
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont),
          textDirection: pw.TextDirection.rtl,
          build: (context) => contentWidgets,
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName =
          'كشف_حساب_${intl.DateFormat('yyyyMMdd_HHmm', 'en_US').format(DateTime.now())}.pdf';

      if (context.mounted) {
        Navigator.pop(context);

        // Save to temporary file for direct opening
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        // Direct Open only
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل إنشاء التقرير: $e')));
      }
    }
  }

 
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'no_previous_transactions'.tr(),
            style: TextStyle(
              fontSize: 18,
              color: widget.isDarkMode ? Colors.white60 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserData() async {
    final user = await ApiService.getCachedUser();
    if (mounted) {
      setState(() {
        _userData = user;
      });
    }
  }

  void _showOperationDetails(OperationHistoryModel transaction) {
    final dateFormat = intl.DateFormat('dd/MM/yyyy HH:mm', 'en_US');

    List<ReceiptRowData> details = [];
    if (transaction.referenceNumber.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: transaction.getReferenceLabelKey().tr(),
          value: transaction.referenceNumber,
          isCopyable: true,
        ),
      );
    }
    details.add(
      ReceiptRowData(
        label: 'transactionType'.tr(),
        value: transaction.operationTypeDisplay,
      ),
    );
    // details.add(
    //   ReceiptRowData(
    //     label: 'operation_amount'.tr(),
    //     value:
    //         '${amountFormatter.format(double.tryParse(transaction.amount) ?? 0)} ${transaction.currency}',
    //     isCopyable: true,
    //   ),
    // );
    if (transaction.fee != '0' && transaction.fee.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: 'operation_fee'.tr(),
          value:
              '${formatAmountDisplay(double.tryParse(transaction.fee) ?? 0)} ${transaction.currency}',
        ),
      );
    }
    // if (transaction.balanceBefore.isNotEmpty &&
    //     transaction.balanceBefore != '0') {
    //   details.add(
    //     ReceiptRowData(
    //       label: 'operation_balance_before'.tr(),
    //       value:
    //           '${amountFormatter.format(double.tryParse(transaction.balanceBefore) ?? 0)} ${transaction.currency}',
    //     ),
    //   );
    // }
    // if (transaction.balanceAfter.isNotEmpty &&
    //     transaction.balanceAfter != '0') {
    //   details.add(
    //     ReceiptRowData(
    //       label: 'operation_balance_after'.tr(),
    //       value:
    //           '${amountFormatter.format(double.tryParse(transaction.balanceAfter) ?? 0)} ${transaction.currency}',
    //     ),
    //   );
    // }
    final balanceBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
    final balanceAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
    final isIncoming = balanceAfter > balanceBefore;

    if (transaction.relatedUserName != null &&
        transaction.relatedUserName!.isNotEmpty) {
      final fullName =
          _userData != null
              ? (_userData!['full_name'] ??
                  "${_userData!['first_name'] ?? ''} ${_userData!['last_name'] ?? ''}"
                      .trim())
              : 'مستخدم صيفي';
      final username =
          _userData != null
              ? (_userData!['username'] ?? _userData!['phone_number'])
              : '';

      if (isIncoming) {
        details.add(
          ReceiptRowData(label: 'المستفيد', value: '$fullName\n$username'),
        );
        details.add(
          ReceiptRowData(label: 'المودع', value: transaction.relatedUserName!),
        );
      } else {
        details.add(
          ReceiptRowData(
            label: 'المستفيد',
            value: transaction.relatedUserName!,
          ),
        );
        details.add(
          ReceiptRowData(label: 'المودع', value: '$fullName\n$username'),
        );
      }
    }
    details.add(
      ReceiptRowData(
        label: 'operation_date'.tr(),
        value: dateFormat.format(transaction.createdAt.toLocal()),
      ),
    );
    if (transaction.description.isNotEmpty &&
        OperationHistoryModel.remittanceTypes.contains(
          transaction.operationType,
        )) {
      details.add(
        ReceiptRowData(
          label: 'operation_description'.tr(),
          value: transaction.description,
        ),
      );
    }
    if (transaction.extraData != null && transaction.extraData!.isNotEmpty) {
      // details.add(ReceiptRowData(label: 'operation_extra_data'.tr(), value: ''));
      // for (var entry in transaction.extraData!.entries) {
      //   details.add(ReceiptRowData(label: entry.key, value: entry.value.toString()));
      // }
    }

    ReceiptDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      title: 'operation_details_title'.tr(),
      mainAmount:
          formatAmountDisplay(double.tryParse(transaction.amount) ?? 0),
      mainCurrency: transaction.currency,
      details: details,
      amountColor: isIncoming ? Colors.green : Colors.red,
    );
  }

  Widget _buildTransactionItem(OperationHistoryModel transaction) {
    final type = transaction.operationType;
    final amount = double.tryParse(transaction.amount) ?? 0.0;
    final currency = transaction.currency;
    final dateStr = transaction.createdAt.toIso8601String();
    final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    final timeFormat = intl.DateFormat('hh:mm a', 'en_US');
    final dateFormat = intl.DateFormat('dd/MM/yyyy', 'en_US');

    final balanceBefore = double.tryParse(transaction.balanceBefore) ?? 0.0;
    final balanceAfter = double.tryParse(transaction.balanceAfter) ?? 0.0;
    final isPositive = balanceAfter > balanceBefore;
    final icon = OperationTypeHelper.getIcon(type);
    final iconColor = isPositive ? Colors.green : Colors.red;
    final title = transaction.operationTypeDisplay;

    String getCurrencyAr(String code) {
      if (code == 'YER') return 'ر.ي';
      if (code == 'USD') return 'دولار';
      if (code == 'SAR') return 'ر.س';
      return code;
    }

    final currencyAr = getCurrencyAr(currency);

    return GestureDetector(
      onTap: () {
        _showOperationDetails(transaction);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            // Styled Icon Container
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 15),

            // Transaction Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.textBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (transaction.description.isNotEmpty)
                        Text(
                          transaction.description,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                widget.isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: widget.isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(date)} | ${timeFormat.format(date)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isDarkMode
                                  ? Colors.white54
                                  : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Balance info below date
                  if (transaction.balanceAfter.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الرصيد الحالي:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                ),
                              ),
                              Text(
                                '${formatAmountDisplay(balanceAfter)} $currencyAr',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white
                                          : AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          if (transaction.balanceBefore.isNotEmpty &&
                              transaction.balanceBefore != '0') ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الرصيد قبل:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white54
                                            : Colors.black38,
                                  ),
                                ),
                                Text(
                                  '${formatAmountDisplay(balanceBefore)} $currencyAr',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white54
                                            : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Amount & Direction
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? "+" : "-"}${formatAmountDisplay(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  currencyAr,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (double.tryParse(transaction.fee) != null &&
                    double.tryParse(transaction.fee)! > 0)
                  Text(
                    'العمولة: ${formatAmountDisplay(double.tryParse(transaction.fee) ?? 0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildQuickDateButton(true),
          const SizedBox(width: 10),
          _buildQuickDateButton(false),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return Expanded(
      child: InkWell(
        onTap: () => _selectQuickDate(isStart),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color:
                    widget.isDarkMode ? Colors.white70 : AppColors.primaryBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date == null
                      ? (isStart ? 'from_date'.tr() : 'to_date'.tr())
                      : intl.DateFormat('yyyy/MM/dd', 'en_US').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDarkMode ? Colors.white : AppColors.textBlack,
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
}
