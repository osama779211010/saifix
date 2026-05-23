import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import '../core/app_colors.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isDarkMode;
  const NotificationsScreen({super.key, required this.isDarkMode});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        ApiService.markNotificationsRead();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final DateTime date = DateTime.parse(dateString.toString());
      return intl.DateFormat('dd/MM/yyyy hh:mm a', 'en_US').format(date);
    } catch (e) {
      return '';
    }
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'alerts'.tr(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
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
          left: -50,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 80,
            color: widget.isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
          // .animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(
            'no_new_alerts'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white54 : Colors.grey,
            ),
          ),
          // .animate().fade(delay: 200.ms),
        ],
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
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.adaptiveIcon(widget.isDarkMode),
                            ),
                          )
                          : RefreshIndicator(
                            onRefresh: _fetchNotifications,
                            color: AppColors.adaptiveIcon(widget.isDarkMode),
                            child:
                                _notifications.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      itemCount: _notifications.length,
                                      itemBuilder: (context, index) {
                                        final n = _notifications[index];
                                        final bool isUnread =
                                            n['is_read'] == false;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 15,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                widget.isDarkMode
                                                    ? (isUnread
                                                        ? AppColors.cardDark
                                                            .withValues(alpha: 0.9)
                                                        : AppColors.cardDark
                                                            .withValues(alpha: 0.5))
                                                    : (isUnread
                                                        ? Colors.white
                                                        : Colors.grey.shade50),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isUnread
                                                      ? AppColors.primaryBlue
                                                          .withValues(alpha: 0.3)
                                                      : (widget.isDarkMode
                                                          ? Colors.white10
                                                          : Colors.black
                                                              .withValues(alpha: 
                                                                0.05,
                                                              )),
                                              width: isUnread ? 1.5 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 
                                                  widget.isDarkMode
                                                      ? 0.2
                                                      : 0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.adaptiveIcon(
                                                          widget.isDarkMode,
                                                        ).withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .notifications_active_rounded,
                                                    color:
                                                        AppColors.adaptiveIcon(
                                                          widget.isDarkMode,
                                                        ),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              n['title'] ??
                                                                  'warning'
                                                                      .tr(),
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color:
                                                                    widget.isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : AppColors
                                                                            .textBlack,
                                                              ),
                                                            ),
                                                          ),
                                                          if (n['created_at'] !=
                                                              null)
                                                            Text(
                                                              _formatDate(
                                                                n['created_at'],
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    widget.isDarkMode
                                                                        ? Colors
                                                                            .white54
                                                                        : Colors
                                                                            .grey,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        n['message'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              widget.isDarkMode
                                                                  ? Colors
                                                                      .white70
                                                                  : Colors
                                                                      .black87,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        // .animate().fade(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
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
}
