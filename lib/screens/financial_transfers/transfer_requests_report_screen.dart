import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class TransferRequestsReportScreen extends StatefulWidget {
  final bool isDarkMode;

  const TransferRequestsReportScreen({super.key, required this.isDarkMode});

  @override
  State<TransferRequestsReportScreen> createState() =>
      _TransferRequestsReportScreenState();
}

class _TransferRequestsReportScreenState
    extends State<TransferRequestsReportScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _selectedStatus = 'PENDING';
  final List<String> _statuses = [
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      // Format date as YYYY-MM-DD for API
      final dateFilter =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final data = await ApiService.getMyReceiptRequests(
        dateFilter: dateFilter,
        statusFilter: _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _requests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('fetch_requests_error'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: widget.isDarkMode ? AppColors.cardDark : Colors.white,
              onSurface: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchRequests();
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
                  child: Column(
                    children: [
                      // Search and Date Filter
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Search Icon Toggle
                            _buildActionButton(
                              icon: Icons.search_rounded,
                              onTap: () {
                                // Open search logic
                              },
                            ),
                            const SizedBox(width: 10),
                            // Date Field
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.isDarkMode
                                            ? AppColors.cardDark
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 
                                          widget.isDarkMode ? 0.3 : 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                    border: Border.all(
                                      color:
                                          widget.isDarkMode
                                              ? Colors.white10
                                              : Colors.black.withValues(alpha: 0.03),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: AppColors.adaptiveIcon(
                                          widget.isDarkMode,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white
                                                  : AppColors.textBlack,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'date_label'.tr(),
                                        style: TextStyle(
                                          color:
                                              widget.isDarkMode
                                                  ? Colors.white54
                                                  : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Filter Chips
                      _buildStatusFilter(),

                      // List / Loading / Empty State
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchRequests,
                          color: AppColors.primaryBlue,
                          child:
                              _isLoading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.adaptiveIcon(
                                        widget.isDarkMode,
                                      ),
                                    ),
                                  )
                                  : _requests.isEmpty
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.2,
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(30),
                                              decoration: BoxDecoration(
                                                color: AppColors.adaptiveIcon(
                                                  widget.isDarkMode,
                                                ).withValues(alpha: 0.05),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.description_rounded,
                                                size: 80,
                                                color:
                                                    widget.isDarkMode
                                                        ? Colors.white12
                                                        : Colors.black
                                                            .withValues(alpha: 0.05),
                                              ),
                                            ),
                                            const SizedBox(height: 25),
                                            Text(
                                              'no_requests_label'.tr(),
                                              style: TextStyle(
                                                color:
                                                    widget.isDarkMode
                                                        ? Colors.white60
                                                        : Colors.grey,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  : ListView.builder(
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    itemCount: _requests.length,
                                    itemBuilder: (context, index) {
                                      final req = _requests[index];
                                      return _buildRequestCard(req);
                                    },
                                  ),
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
            'transfer_requests_report_title'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color:
                widget.isDarkMode
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.adaptiveIcon(widget.isDarkMode),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text('status_${status.toLowerCase()}'.tr()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                      _fetchRequests();
                    },
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : (widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor:
                        widget.isDarkMode ? AppColors.cardDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.primaryBlue
                                : (widget.isDarkMode
                                    ? Colors.white10
                                    : Colors.black12),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    bool isApproved = req['status'] == 'APPROVED';
    bool isRejected = req['status'] == 'REJECTED';

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time_rounded;
    if (isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color:
              widget.isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'request_number_label'.tr(
                  args: [req['operation_number'] ?? ''],
                ),
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.grey[700]!,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      req['status_display'] ?? req['status'] ?? '',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.adaptiveIcon(
                    widget.isDarkMode,
                  ).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.adaptiveIcon(widget.isDarkMode),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'remittance_number_label2'.tr(
                        args: [req['remittance_number'] ?? ''],
                      ),
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.white
                                : AppColors.textBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'remittance_type_label'.tr(
                        args: [
                          req['remittance_type_display'] ??
                              req['remittance_type'] ??
                              '',
                        ],
                      ),
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.white54
                                : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (req['amount'] != null)
                Text(
                  '${req['amount']}',
                  style: TextStyle(
                    color: AppColors.adaptiveText(
                      widget.isDarkMode,
                      lightColor: AppColors.primaryBlue,
                    ),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          if (isRejected && req['rejection_reason'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                'rejection_reason_label'.tr(args: [req['rejection_reason']]),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import '../../services/api_service.dart';
// import '../../core/app_colors.dart';

// class TransferRequestsReportScreen extends StatefulWidget {
//   final bool isDarkMode;

//   const TransferRequestsReportScreen({super.key, required this.isDarkMode});

//   @override
//   State<TransferRequestsReportScreen> createState() =>
//       _TransferRequestsReportScreenState();
// }

// class _TransferRequestsReportScreenState
//     extends State<TransferRequestsReportScreen> {
//   final DateTime _selectedDate = DateTime.now();
//   List<Map<String, dynamic>> _requests = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchRequests();
//   }

//   Future<void> _fetchRequests() async {
//     setState(() => _isLoading = true);
//     try {
//       final data = await ApiService.getMyReceiptRequests();
//       if (mounted) {
//         setState(() {
//           _requests = data;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('fetch_requests_error'.tr(args: [e.toString()])), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
//       body: Stack(
//         children: [
//           _buildPremiumBackground(),
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildPremiumHeader(),
//                 Expanded(
//                   child: Column(
//                     children: [
//                       // Search and Date Filter
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                         child: Row(
//                           children: [
//                             // Search Icon Toggle
//                             _buildActionButton(
//                               icon: Icons.search_rounded,
//                               onTap: () {
//                                 // Open search logic
//                               },
//                             ),
//                             const SizedBox(width: 10),
//                             // Date Field
//                             Expanded(
//                               child: GestureDetector(
//                                 onTap: () {
//                                   // Open date picker
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 15,
//                                     vertical: 12,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color:
//                                         widget.isDarkMode
//                                             ? AppColors.cardDark
//                                             : Colors.white,
//                                     borderRadius: BorderRadius.circular(15),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withValues(alpha: 
//                                           widget.isDarkMode ? 0.3 : 0.05,
//                                         ),
//                                         blurRadius: 10,
//                                         offset: const Offset(0, 5),
//                                       ),
//                                     ],
//                                     border: Border.all(
//                                       color:
//                                           widget.isDarkMode
//                                               ? Colors.white10
//                                               : Colors.black.withValues(alpha: 
//                                                 0.03,
//                                               ),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         Icons.calendar_today_rounded,
//                                         size: 18,
//                                         color: AppColors.adaptiveIcon(
//                                           widget.isDarkMode,
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
//                                         style: TextStyle(
//                                           color:
//                                               widget.isDarkMode
//                                                   ? Colors.white
//                                                   : AppColors.textBlack,
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         'date_label'.tr(),
//                                         style: TextStyle(
//                                           color:
//                                               widget.isDarkMode
//                                                   ? Colors.white54
//                                                   : Colors.grey,
//                                           fontSize: 12,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
      
//                       // List / Loading / Empty State
//                       Expanded(
//                         child: RefreshIndicator(
//                           onRefresh: _fetchRequests,
//                           color: AppColors.primaryBlue,
//                           child: _isLoading
//                               ? Center(
//                                   child: CircularProgressIndicator(
//                                     color: AppColors.adaptiveIcon(widget.isDarkMode),
//                                   ),
//                                 )
//                               : _requests.isEmpty
//                                   ? ListView(
//                                       physics: const AlwaysScrollableScrollPhysics(),
//                                       children: [
//                                         SizedBox(height: MediaQuery.of(context).size.height * 0.2),
//                                         Center(
//                                           child: Column(
//                                             mainAxisAlignment: MainAxisAlignment.center,
//                                             children: [
//                                               Container(
//                                                 padding: const EdgeInsets.all(30),
//                                                 decoration: BoxDecoration(
//                                                   color: AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.05),
//                                                   shape: BoxShape.circle,
//                                                 ),
//                                                 child: Icon(
//                                                   Icons.description_rounded,
//                                                   size: 80,
//                                                   color: widget.isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 25),
//                                               Text(
//                                                 'no_requests_label'.tr(),
//                                                 style: TextStyle(
//                                                   color: widget.isDarkMode ? Colors.white60 : Colors.grey,
//                                                   fontSize: 16,
//                                                   fontWeight: FontWeight.bold,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     )
//                                   : ListView.builder(
//                                       physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
//                                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                                       itemCount: _requests.length,
//                                       itemBuilder: (context, index) {
//                                         final req = _requests[index];
//                                         return _buildRequestCard(req);
//                                       },
//                                     ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPremiumBackground() {
//     return Stack(
//       children: [
//         Positioned(
//           top: -100,
//           left: -100,
//           child: Container(
//             width: 300,
//             height: 300,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: AppColors.adaptiveIcon(
//                 widget.isDarkMode,
//               ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
//             ),
//           ),
//         ),
//         Positioned(
//           bottom: -50,
//           right: -50,
//           child: Container(
//             width: 200,
//             height: 200,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: AppColors.adaptiveIcon(
//                 widget.isDarkMode,
//               ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPremiumHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: Icon(
//               Icons.arrow_back_ios,
//               color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
//             ),
//             onPressed: () => Navigator.pop(context),
//           ),
//           Text(
//             'transfer_requests_report_title'.tr(),
//             style: TextStyle(
//               color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(width: 48), // Spacer
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//           border: Border.all(
//             color:
//                 widget.isDarkMode
//                     ? Colors.white10
//                     : Colors.black.withValues(alpha: 0.03),
//           ),
//         ),
//         child: Icon(
//           icon,
//           color: AppColors.adaptiveIcon(widget.isDarkMode),
//           size: 22,
//         ),
//       ),
//     );
//   }

//   Widget _buildRequestCard(Map<String, dynamic> req) {
//     bool isPending = req['status'] == 'PENDING';
//     bool isApproved = req['status'] == 'APPROVED';
//     bool isRejected = req['status'] == 'REJECTED';

//     Color statusColor = Colors.orange;
//     IconData statusIcon = Icons.access_time_rounded;
//     if (isApproved) {
//       statusColor = Colors.green;
//       statusIcon = Icons.check_circle_outline_rounded;
//     } else if (isRejected) {
//       statusColor = Colors.red;
//       statusIcon = Icons.cancel_outlined;
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 15),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//         border: Border.all(
//           color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'request_number_label'.tr(args: [req['operation_number'] ?? '']),
//                 style: TextStyle(
//                   color: widget.isDarkMode ? Colors.white70 : Colors.grey[700]!,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: statusColor.withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: statusColor.withValues(alpha: 0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(statusIcon, size: 14, color: statusColor),
//                     const SizedBox(width: 4),
//                     Text(
//                       req['status_display'] ?? req['status'] ?? '',
//                       style: TextStyle(
//                         color: statusColor,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.05),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.receipt_long_rounded,
//                   color: AppColors.adaptiveIcon(widget.isDarkMode),
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'remittance_number_label2'.tr(args: [req['remittance_number'] ?? '']),
//                       style: TextStyle(
//                         color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
//                         fontSize: 15,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'remittance_type_label'.tr(args: [req['remittance_type_display'] ?? req['remittance_type'] ?? '']),
//                       style: TextStyle(
//                         color: widget.isDarkMode ? Colors.white54 : Colors.grey[600],
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (req['amount'] != null)
//                 Text(
//                   '${req['amount']}',
//                   style: TextStyle(
//                     color: AppColors.adaptiveText(widget.isDarkMode, lightColor: AppColors.primaryBlue),
//                     fontSize: 16,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//             ],
//           ),
//           if (isRejected && req['rejection_reason'] != null) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(8),
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.red.withValues(alpha: 0.05),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
//               ),
//               child: Text(
//                 'rejection_reason_label'.tr(args: [req['rejection_reason']]),
//                 style: const TextStyle(
//                   color: Colors.red,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }


// // import 'package:flutter/material.dart';
// // import '../../services/api_service.dart';
// // import '../../core/app_colors.dart';

// // class TransferRequestsReportScreen extends StatefulWidget {
// //   final bool isDarkMode;

// //   const TransferRequestsReportScreen({super.key, required this.isDarkMode});

// //   @override
// //   State<TransferRequestsReportScreen> createState() =>
// //       _TransferRequestsReportScreenState();
// // }

// // class _TransferRequestsReportScreenState
// //     extends State<TransferRequestsReportScreen> {
// //   final DateTime _selectedDate = DateTime.now();
// //   List<Map<String, dynamic>> _requests = [];
// //   bool _isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchRequests();
// //   }

// //   Future<void> _fetchRequests() async {
// //     setState(() => _isLoading = true);
// //     try {
// //       final data = await ApiService.getMyReceiptRequests();
// //       if (mounted) {
// //         setState(() {
// //           _requests = data;
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() => _isLoading = false);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('خطأ في جلب الطلبات: $e'), backgroundColor: Colors.red),
// //         );
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor:
// //           widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
// //       body: Directionality(
// //         textDirection: TextDirection.rtl,
// //         child: Stack(
// //           children: [
// //             _buildPremiumBackground(),
// //             SafeArea(
// //               child: Column(
// //                 children: [
// //                   _buildPremiumHeader(),
// //                   Expanded(
// //                     child: Column(
// //                       children: [
// //                         // Search and Date Filter
// //                         Padding(
// //                           padding: const EdgeInsets.symmetric(
// //                             horizontal: 20,
// //                             vertical: 10,
// //                           ),
// //                           child: Row(
// //                             children: [
// //                               // Search Icon Toggle
// //                               _buildActionButton(
// //                                 icon: Icons.search_rounded,
// //                                 onTap: () {
// //                                   // Open search logic
// //                                 },
// //                               ),
// //                               const SizedBox(width: 10),
// //                               // Date Field
// //                               Expanded(
// //                                 child: GestureDetector(
// //                                   onTap: () {
// //                                     // Open date picker
// //                                   },
// //                                   child: Container(
// //                                     padding: const EdgeInsets.symmetric(
// //                                       horizontal: 15,
// //                                       vertical: 12,
// //                                     ),
// //                                     decoration: BoxDecoration(
// //                                       color:
// //                                           widget.isDarkMode
// //                                               ? AppColors.cardDark
// //                                               : Colors.white,
// //                                       borderRadius: BorderRadius.circular(15),
// //                                       boxShadow: [
// //                                         BoxShadow(
// //                                           color: Colors.black.withValues(alpha: 
// //                                             widget.isDarkMode ? 0.3 : 0.05,
// //                                           ),
// //                                           blurRadius: 10,
// //                                           offset: const Offset(0, 5),
// //                                         ),
// //                                       ],
// //                                       border: Border.all(
// //                                         color:
// //                                             widget.isDarkMode
// //                                                 ? Colors.white10
// //                                                 : Colors.black.withValues(alpha: 
// //                                                   0.03,
// //                                                 ),
// //                                       ),
// //                                     ),
// //                                     child: Row(
// //                                       children: [
// //                                         Icon(
// //                                           Icons.calendar_today_rounded,
// //                                           size: 18,
// //                                           color: AppColors.adaptiveIcon(
// //                                             widget.isDarkMode,
// //                                           ),
// //                                         ),
// //                                         const Spacer(),
// //                                         Text(
// //                                           '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
// //                                           style: TextStyle(
// //                                             color:
// //                                                 widget.isDarkMode
// //                                                     ? Colors.white
// //                                                     : AppColors.textBlack,
// //                                             fontSize: 14,
// //                                             fontWeight: FontWeight.bold,
// //                                           ),
// //                                         ),
// //                                         const Spacer(),
// //                                         Text(
// //                                           'التاريخ',
// //                                           style: TextStyle(
// //                                             color:
// //                                                 widget.isDarkMode
// //                                                     ? Colors.white54
// //                                                     : Colors.grey,
// //                                             fontSize: 12,
// //                                             fontWeight: FontWeight.bold,
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),

// //                         // List / Loading / Empty State
// //                         Expanded(
// //                           child: RefreshIndicator(
// //                             onRefresh: _fetchRequests,
// //                             color: AppColors.primaryBlue,
// //                             child: _isLoading
// //                                 ? Center(
// //                                     child: CircularProgressIndicator(
// //                                       color: AppColors.adaptiveIcon(widget.isDarkMode),
// //                                     ),
// //                                   )
// //                                 : _requests.isEmpty
// //                                     ? ListView(
// //                                         physics: const AlwaysScrollableScrollPhysics(),
// //                                         children: [
// //                                           SizedBox(height: MediaQuery.of(context).size.height * 0.2),
// //                                           Center(
// //                                             child: Column(
// //                                               mainAxisAlignment: MainAxisAlignment.center,
// //                                               children: [
// //                                                 Container(
// //                                                   padding: const EdgeInsets.all(30),
// //                                                   decoration: BoxDecoration(
// //                                                     color: AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.05),
// //                                                     shape: BoxShape.circle,
// //                                                   ),
// //                                                   child: Icon(
// //                                                     Icons.description_rounded,
// //                                                     size: 80,
// //                                                     color: widget.isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
// //                                                   ),
// //                                                 ),
// //                                                 const SizedBox(height: 25),
// //                                                 Text(
// //                                                   'لا توجد طلبات للعرض',
// //                                                   style: TextStyle(
// //                                                     color: widget.isDarkMode ? Colors.white60 : Colors.grey,
// //                                                     fontSize: 16,
// //                                                     fontWeight: FontWeight.bold,
// //                                                   ),
// //                                                 ),
// //                                               ],
// //                                             ),
// //                                           ),
// //                                         ],
// //                                       )
// //                                     : ListView.builder(
// //                                         physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
// //                                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //                                         itemCount: _requests.length,
// //                                         itemBuilder: (context, index) {
// //                                           final req = _requests[index];
// //                                           return _buildRequestCard(req);
// //                                         },
// //                                       ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
 
 
// //   }

// //   Widget _buildPremiumBackground() {
// //     return Stack(
// //       children: [
// //         Positioned(
// //           top: -100,
// //           left: -100,
// //           child: Container(
// //             width: 300,
// //             height: 300,
// //             decoration: BoxDecoration(
// //               shape: BoxShape.circle,
// //               color: AppColors.adaptiveIcon(
// //                 widget.isDarkMode,
// //               ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
// //             ),
// //           ),
// //         ),
// //         Positioned(
// //           bottom: -50,
// //           right: -50,
// //           child: Container(
// //             width: 200,
// //             height: 200,
// //             decoration: BoxDecoration(
// //               shape: BoxShape.circle,
// //               color: AppColors.adaptiveIcon(
// //                 widget.isDarkMode,
// //               ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildPremiumHeader() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           IconButton(
// //             icon: Icon(
// //               Icons.arrow_back_ios,
// //               color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
// //             ),
// //             onPressed: () => Navigator.pop(context),
// //           ),
// //           Text(
// //             'تقرير طلبات التحويل',
// //             style: TextStyle(
// //               color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           const SizedBox(width: 48), // Spacer
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildActionButton({
// //     required IconData icon,
// //     required VoidCallback onTap,
// //   }) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.all(12),
// //         decoration: BoxDecoration(
// //           color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
// //           borderRadius: BorderRadius.circular(15),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
// //               blurRadius: 10,
// //               offset: const Offset(0, 5),
// //             ),
// //           ],
// //           border: Border.all(
// //             color:
// //                 widget.isDarkMode
// //                     ? Colors.white10
// //                     : Colors.black.withValues(alpha: 0.03),
// //           ),
// //         ),
// //         child: Icon(
// //           icon,
// //           color: AppColors.adaptiveIcon(widget.isDarkMode),
// //           size: 22,
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildRequestCard(Map<String, dynamic> req) {
// //     bool isPending = req['status'] == 'PENDING';
// //     bool isApproved = req['status'] == 'APPROVED';
// //     bool isRejected = req['status'] == 'REJECTED';

// //     Color statusColor = Colors.orange;
// //     IconData statusIcon = Icons.access_time_rounded;
// //     if (isApproved) {
// //       statusColor = Colors.green;
// //       statusIcon = Icons.check_circle_outline_rounded;
// //     } else if (isRejected) {
// //       statusColor = Colors.red;
// //       statusIcon = Icons.cancel_outlined;
// //     }

// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 15),
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
// //         borderRadius: BorderRadius.circular(15),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
// //             blurRadius: 10,
// //             offset: const Offset(0, 5),
// //           ),
// //         ],
// //         border: Border.all(
// //           color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               Text(
// //                 'طلب رقم: ${req['operation_number'] ?? ''}',
// //                 style: TextStyle(
// //                   color: widget.isDarkMode ? Colors.white70 : Colors.grey[700]!,
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                 decoration: BoxDecoration(
// //                   color: statusColor.withValues(alpha: 0.1),
// //                   borderRadius: BorderRadius.circular(8),
// //                   border: Border.all(color: statusColor.withValues(alpha: 0.3)),
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Icon(statusIcon, size: 14, color: statusColor),
// //                     const SizedBox(width: 4),
// //                     Text(
// //                       req['status_display'] ?? req['status'] ?? '',
// //                       style: TextStyle(
// //                         color: statusColor,
// //                         fontSize: 10,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Row(
// //             children: [
// //               Container(
// //                 padding: const EdgeInsets.all(10),
// //                 decoration: BoxDecoration(
// //                   color: AppColors.adaptiveIcon(widget.isDarkMode).withValues(alpha: 0.05),
// //                   shape: BoxShape.circle,
// //                 ),
// //                 child: Icon(
// //                   Icons.receipt_long_rounded,
// //                   color: AppColors.adaptiveIcon(widget.isDarkMode),
// //                   size: 24,
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       'رقم الحوالة: ${req['remittance_number'] ?? ''}',
// //                       style: TextStyle(
// //                         color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
// //                         fontSize: 15,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 4),
// //                     Text(
// //                       'النوع: ${req['remittance_type_display'] ?? req['remittance_type'] ?? ''}',
// //                       style: TextStyle(
// //                         color: widget.isDarkMode ? Colors.white54 : Colors.grey[600],
// //                         fontSize: 13,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               if (req['amount'] != null)
// //                 Text(
// //                   '${req['amount']}',
// //                   style: TextStyle(
// //                     color: AppColors.adaptiveText(widget.isDarkMode, lightColor: AppColors.primaryBlue),
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.w900,
// //                   ),
// //                 ),
// //             ],
// //           ),
// //           if (isRejected && req['rejection_reason'] != null) ...[
// //             const SizedBox(height: 12),
// //             Container(
// //               padding: const EdgeInsets.all(8),
// //               width: double.infinity,
// //               decoration: BoxDecoration(
// //                 color: Colors.red.withValues(alpha: 0.05),
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
// //               ),
// //               child: Text(
// //                 'سبب الرفض: ${req['rejection_reason']}',
// //                 style: const TextStyle(
// //                   color: Colors.red,
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// // }
