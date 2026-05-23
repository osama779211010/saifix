import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';

class DeviceManagementScreen extends StatefulWidget {
  final bool isDarkMode;
  const DeviceManagementScreen({super.key, required this.isDarkMode});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  String _deviceModel = "جاري التحميل...";
  String _deviceType = "أندرويد";
  List<dynamic> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getDeviceInfo();
    await _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      final devices = await ApiService.getDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deactivateDevice(int id) async {
    try {
      await ApiService.deactivateDevice(id);
      await _fetchDevices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('device_deactivated_success'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('device_deactivate_failed'.tr(args: [e.toString()])),
          ),
        );
      }
    }
  }

  Future<void> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        setState(() {
          _deviceModel = "${webInfo.browserName.name} on ${webInfo.platform}";
          _deviceType = "ويب";
        });
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        setState(() {
          _deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
          _deviceType = "أندرويد";
        });
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        setState(() {
          _deviceModel = iosInfo.name;
          _deviceType = "iOS";
        });
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        setState(() {
          _deviceModel = windowsInfo.computerName;
          _deviceType = "ويندوز";
        });
      }
    } catch (e) {
      setState(() {
        _deviceModel = "غير معروف";
      });
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
                _buildPremiumHeader(
                  'device_management_title'.tr(),
                  () => Navigator.pop(context),
                ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 20),

                // Devices List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildSectionTitle('linked_devices_title'.tr())
                          .animate()
                          .fade(delay: 200.ms)
                          .slideX(begin: 0.1, end: 0),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_devices.isEmpty)
                        _buildDeviceCard(
                          isPrimary: true,
                          model: _deviceModel,
                          type: _deviceType,
                          lastLogin: DateTime.now(),
                          id: -1,
                        )
                      else
                        ..._devices.map((device) {
                          final String dName =
                              device['device_name'] ?? 'غير معروف';
                          final bool isThisDevice = dName == _deviceModel;

                          return _buildDeviceCard(
                            isPrimary: isThisDevice,
                            model: dName,
                            type:
                                dName.toLowerCase().contains('iphone')
                                    ? 'iOS'
                                    : 'أندرويد',
                            lastLogin: DateTime.parse(device['last_login']),
                            isActive: device['is_active'] ?? true,
                            id: device['id'],
                          );
                        }),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 5),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          color: widget.isDarkMode ? Colors.white70 : AppColors.textGreyDark,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required bool isPrimary,
    required String model,
    required String type,
    required DateTime lastLogin,
    bool isActive = true,
    required int id,
  }) {
    final bgColor = widget.isDarkMode ? AppColors.cardDark : Colors.white;
    final borderColor =
        isPrimary
            ? AppColors.primaryBlue
            : (isActive
                ? (widget.isDarkMode ? Colors.white10 : Colors.black12)
                : Colors.red.withValues(alpha: 0.3));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isPrimary ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isPrimary
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == 'iOS'
                      ? Icons.phone_iphone_rounded
                      : type == 'ويندوز'
                      ? Icons.laptop_windows_rounded
                      : Icons.android_rounded,
                  color:
                      isPrimary
                          ? AppColors.primaryBlue
                          : (widget.isDarkMode
                              ? Colors.white70
                              : AppColors.textGreyDark),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      style: GoogleFonts.cairo(
                        color:
                            widget.isDarkMode
                                ? Colors.white
                                : AppColors.textBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        color:
                            widget.isDarkMode
                                ? Colors.white38
                                : AppColors.textGreyLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'this_device_label'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isPrimary
                    ? 'active_now'.tr()
                    : (isActive ? 'linked'.tr() : 'deactivated'.tr()),
                style: GoogleFonts.cairo(
                  color:
                      isPrimary
                          ? Colors.green
                          : (isActive ? Colors.grey : Colors.red),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isPrimary && isActive && id != -1)
                TextButton.icon(
                  onPressed: () => _deactivateDevice(id),
                  icon: const Icon(
                    Icons.block_flipped,
                    size: 14,
                    color: Colors.red,
                  ),
                  label: Text(
                    'deactivate_device'.tr(),
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              if (!isActive)
                Text(
                  'access_disabled'.tr(),
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                )
              else
                Text(
                  'last_seen_label'.tr(
                    args: [
                      intl.DateFormat('yyyy/MM/dd HH:mm', 'en_US').format(lastLogin),
                    ],
                  ),
                  style: TextStyle(
                    color:
                        widget.isDarkMode
                            ? Colors.white38
                            : AppColors.textGreyLight,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
