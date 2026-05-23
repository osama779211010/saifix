import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../helper/counvert_amunt_helper.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../models/operation_history.dart';
import '../utils/operation_type_helper.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/wheel_date_picker.dart';
import 'account_confirmation_screen.dart';

class CurrencyTransactionsScreen extends StatefulWidget {
  final bool isDarkMode;
  final String currency;
  final String initialBalance;

  const CurrencyTransactionsScreen({
    super.key,
    required this.isDarkMode,
    required this.currency,
    required this.initialBalance,
  });

  @override
  State<CurrencyTransactionsScreen> createState() =>
      _CurrencyTransactionsScreenState();
}

class _CurrencyTransactionsScreenState
    extends State<CurrencyTransactionsScreen> {
  List<OperationHistoryModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int? _lastRequestedPage;
  final ScrollController _scrollController = ScrollController();

  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _userData;

  int _loadCount = 0;
  final List<String> _logos = ['logo_circle.png', 'pr_logo.png'];
  String get _currentLogo => _logos[_loadCount % _logos.length];

  @override
  void initState() {
    super.initState();
    // Default to last 2 months
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 60));
    _fetchTransactions();
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

  Future<void> _fetchUserData() async {
    final user = await ApiService.getCachedUser();
    if (mounted) {
      setState(() {
        _userData = user;
      });
    }
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (_isLoading || (loadMore && _lastRequestedPage == _currentPage)) return;

    setState(() => _isLoading = true);
    if (loadMore) _lastRequestedPage = _currentPage;

    try {
      if (!loadMore) {
        _currentPage = 1;
        _transactions.clear();
        _totalIncome = 0.0;
        _totalExpenses = 0.0;
        _loadCount = 0;
      }

      final response = await ApiService.getOperationsHistory(
        page: _currentPage,
        pageSize: 15,
        currency: widget.currency,
        startDate: _formatDateOnly(_startDate),
        endDate: _formatDateOnly(_endDate),
      );

      if (mounted) {
        setState(() {
          if (loadMore && response.results.isNotEmpty) {
            _loadCount++;
          }

          if (loadMore) {
            // Prevent duplicates
            for (var tx in response.results) {
              bool exists = _transactions.any(
                (existing) =>
                    (existing.referenceNumber.isNotEmpty &&
                        existing.referenceNumber == tx.referenceNumber) ||
                    (existing.id == tx.id),
              );
              if (!exists) {
                _transactions.add(tx);
                _updateTotals(tx);
              }
            }
          } else {
            _transactions = response.results;
            for (var tx in _transactions) {
              _updateTotals(tx);
            }
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

  void _updateTotals(OperationHistoryModel tx) {
    final balanceBefore = double.tryParse(tx.balanceBefore) ?? 0.0;
    final balanceAfter = double.tryParse(tx.balanceAfter) ?? 0.0;
    final amount = double.tryParse(tx.amount) ?? 0.0;
    final isPositive = balanceAfter > balanceBefore;
    if (isPositive) {
      _totalIncome += amount;
    } else {
      _totalExpenses += amount;
    }
  }

  Future<void> _refresh() async {
    await _fetchTransactions();
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('max_range_two_months'.tr()),
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
      _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
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
                    color: AppColors.adaptiveIcon(isDark),
                    child:
                        _transactions.isEmpty && !_isLoading
                            ? _buildEmptyState()
                            : CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                SliverPersistentHeader(
                                  pinned: false,
                                  delegate: StickyStatsDelegate(
                                    isDark: isDark,
                                    currency: widget.currency,
                                    totalIncome: _totalIncome,
                                    totalExpenses: _totalExpenses,
                                    currentLogo: _currentLogo,
                                    transactions: _transactions,
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index == _transactions.length) {
                                          if (!_hasMore) {
                                            return const SizedBox();
                                          }
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        return _buildTransactionItem(
                                          _transactions[index],
                                        );
                                      },
                                      childCount:
                                          _transactions.length +
                                          (_hasMore ? 1 : 0),
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
    final currencyText = _getCurrencyNameAr(widget.currency);
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
            'transactions_title'.tr(args: [currencyText]),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.adaptiveIcon(widget.isDarkMode),
            ),
            onPressed: () async {
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
              if (!mounted) return;
              _generatePDF(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateFilter() {
    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'en_US');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectQuickDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.adaptiveIcon(widget.isDarkMode),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null
                          ? dateFormat.format(_startDate!)
                          : 'from_label'.tr(),
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.white70
                                : AppColors.textBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectQuickDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.adaptiveIcon(widget.isDarkMode),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _endDate != null
                          ? dateFormat.format(_endDate!)
                          : 'to_label'.tr(),
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.white70
                                : AppColors.textBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

      final currencyName = _getCurrencyNameAr(widget.currency);
      contentWidgets.add(
        pw.Center(
          child: pw.Text(
            'كشف حساب بأخر العمليات ($currencyName) / رقم الحساب $accountNumber',
            style: pw.TextStyle(font: arabicFontBold, fontSize: 14),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      );
      contentWidgets.add(pw.SizedBox(height: 15));

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

      for (var tx in _transactions) {
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
                    tx.referenceNumber.isNotEmpty ? tx.referenceNumber : 'N/A',
                    style: pw.TextStyle(font: arabicFont, fontSize: 9),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Center(
                  child: pw.Text(
                    tx.operationTypeDisplay,
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
              child: pw.Center(
                child: pw.Text(
                  'الإجمالي:',
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 9),
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
                  formatAmountDisplay(totalDebit),
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      );

      final table = pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.2),
          5: const pw.FlexColumnWidth(1),
          6: const pw.FlexColumnWidth(1),
        },
        children: rows,
      );

      contentWidgets.add(table);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont),
          textDirection: pw.TextDirection.rtl,
          build: (context) => contentWidgets,
        ),
      );

      final pdfBytes = await pdf.save();
      if (!context.mounted) return;
      final fileName =
          'كشف_حساب_${widget.currency}_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().minute.toString().padLeft(2, '0')}.pdf';

      Navigator.pop(context);

      if (mounted) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء التقرير: $e')),
        );
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

  void _showOperationDetails(OperationHistoryModel transaction) {

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

    if (transaction.fee != '0' && transaction.fee.isNotEmpty) {
      details.add(
        ReceiptRowData(
          label: 'operation_fee'.tr(),
          value:
              '${formatAmountDisplay(double.tryParse(transaction.fee) ?? 0)} ${transaction.currency}',
        ),
      );
    }

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
        value: '${transaction.createdAt.toLocal().day.toString().padLeft(2, '0')}/${transaction.createdAt.toLocal().month.toString().padLeft(2, '0')}/${transaction.createdAt.toLocal().year} ${transaction.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${transaction.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
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
                      if (transaction.relatedUserName != null &&
                          transaction.relatedUserName!.isNotEmpty)
                        Text(
                          'المستخدم: ${transaction.relatedUserName}',
                          style: TextStyle(
                            fontSize: 10,
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
                      Flexible(
                        child: Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} | ${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                widget.isDarkMode
                                    ? Colors.white54
                                    : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

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

  String _getCurrencyNameAr(String code) {
    if (code == 'YER') return 'currency_yer'.tr();
    if (code == 'SAR') return 'currency_sar'.tr();
    if (code == 'USD') return 'currency_usd'.tr();
    return code;
  }
}

class StickyStatsDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final String currency;
  final double totalIncome;
  final double totalExpenses;
  final String currentLogo;
  final List<OperationHistoryModel> transactions;

  StickyStatsDelegate({
    required this.isDark,
    required this.currency,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentLogo,
    required this.transactions,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // Background handled by stack
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Donut Chart with Dynamic Logo
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: PremiumDonutChartPainter(
                      income: totalIncome,
                      expenses: totalExpenses,
                      isDark: isDark,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.asset(
                    'assets/images/$currentLogo',
                    key: ValueKey(currentLogo),
                    width: 35,
                    height: 35,
                    errorBuilder:
                        (c, e, s) => Icon(
                          Icons.stars_rounded,
                          color: AppColors.primaryBlue,
                          size: 25,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Statistics and Sparkline
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatRow(
                    'income_label'.tr(),
                    totalIncome,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    'expenses_label'.tr(),
                    totalExpenses,
                    const Color(0xFFF43F5E),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 35,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: SparklinePainter(
                        data:
                            transactions
                                .map((e) => double.tryParse(e.amount) ?? 0.0)
                                .toList()
                                .reversed
                                .toList(),
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          '${formatAmountDisplay(amount)} $currency',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textDirection: ui.TextDirection.ltr,
        ),
      ],
    );
  }

  @override
  double get maxExtent => 180.0;

  @override
  double get minExtent => 180.0;

  @override
  bool shouldRebuild(covariant StickyStatsDelegate oldDelegate) =>
      oldDelegate.totalIncome != totalIncome ||
      oldDelegate.totalExpenses != totalExpenses ||
      oldDelegate.currentLogo != currentLogo ||
      oldDelegate.transactions.length != transactions.length;
}

class PremiumDonutChartPainter extends CustomPainter {
  final double income;
  final double expenses;
  final bool isDark;

  PremiumDonutChartPainter({
    required this.income,
    required this.expenses,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    final strokeWidth = radius * 0.25;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    double total = income + expenses;
    if (total == 0) {
      paint.color =
          isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05);
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    double expenseAngle = (expenses / total) * 2 * math.pi;
    double incomeAngle = (income / total) * 2 * math.pi;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    paint.color = const Color(0xFFF43F5E); // Solid Red
    canvas.drawArc(rect, -math.pi / 2, expenseAngle, false, paint);

    paint.color = const Color(0xFF10B981); // Solid Green
    canvas.drawArc(
      rect,
      -math.pi / 2 + expenseAngle,
      incomeAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();

    final xStep = size.width / (data.length - 1);

    double getY(double val) {
      return size.height - ((val - minVal) / range) * size.height;
    }

    path.moveTo(0, getY(data[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      final x = i * xStep;
      final y = getY(data[i]);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}
