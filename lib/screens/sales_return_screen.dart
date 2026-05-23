import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import 'financial_transfers/all_transactions_screen.dart';
import '../services/api_service.dart';
import 'account_confirmation_screen.dart';

class SalesReturnScreen extends StatefulWidget {
  final bool isDarkMode;
  const SalesReturnScreen({super.key, required this.isDarkMode});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;

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
                  'sales_return'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                _buildSearchHeader(),
                Expanded(
                  child:
                      _isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : _searchResults.isEmpty
                          ? _buildEmptyState()
                          : _buildSearchResults(),
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
              borderRadius: BorderRadius.circular(10),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    final bool isDark = widget.isDarkMode;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'search_return'.tr(),
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
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
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textBlack,
              ),
              decoration: InputDecoration(
                hintText: 'enter_ref_or_phone'.tr(),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white70 : AppColors.primaryBlue,
                  ),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color:
                widget.isDarkMode
                    ? Colors.white10
                    : Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'no_search_results'.tr(),
            style: GoogleFonts.cairo(
              color: widget.isDarkMode ? Colors.white54 : Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AllTransactionsScreen(isDarkMode: widget.isDarkMode),
                ),
              );
            },
            child: Text(
              'browse_all_transactions'.tr(),
              style: GoogleFonts.cairo(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade();
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final bool isDark = widget.isDarkMode;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
            title: Text(
              item['title'] ?? 'transaction_default'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              item['ref'] ?? '',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
            trailing: ElevatedButton(
              onPressed: () => _requestReturn(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'return_request'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ).animate().fade(delay: (index * 100).ms).slideX();
      },
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      // Mock search or actual API call
      await Future.delayed(const Duration(seconds: 1));
      // For now, empty results to show "search off" state or dummy data
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _requestReturn(dynamic item) async {
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

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('return_request_title'.tr()),
            content: Text('return_request_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('return_request_sent'.tr())),
                  );
                },
                child: Text('confirm'.tr()),
              ),
            ],
          ),
    );
  }
}
