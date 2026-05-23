import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/remittance_networks.dart';
import '../saifi_transfer/send_network_transfer_screen.dart';

import '../../helper/custom_print_helper.dart';

class SelectLocalNetworkScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? initialPhone;
  final String? initialRecipientName;

  const SelectLocalNetworkScreen({
    super.key,
    required this.isDarkMode,
    this.initialPhone,
    this.initialRecipientName,
  });

  @override
  State<SelectLocalNetworkScreen> createState() =>
      _SelectLocalNetworkScreenState();
}

class _SelectLocalNetworkScreenState extends State<SelectLocalNetworkScreen> {
  List<RemittanceNetwork> _dynamicNetworks = [];

  final List<Map<String, String>> networks = [
    {'name': 'saifi_cash'.tr(), 'logo': 'assets/images/pr_logo.png'},
    {'name': 'saifi_pay'.tr(), 'logo': 'assets/images/logo_circle.png'},
    // {
    //   'name': 'network_almomayaz'.tr(),
    //   'logo': 'assets/images/networks/almomayaz.png',
    // },
    // {
    //   'name': 'network_alhatar'.tr(),
    //   'logo': 'assets/images/networks/alhatar.png',
    // },
    // {
    //   'name': 'network_mal_money'.tr(),
    //   'logo': 'assets/images/networks/mal_money.png',
    // },
    // {
    //   'name': 'network_albarq'.tr(),
    //   'logo': 'assets/images/networks/albarq.png',
    // },
    // {
    //   'name': 'network_alsaree'.tr(),
    //   'logo': 'assets/images/networks/alsaree.png',
    // },
    // {
    //   'name': 'network_alnasser'.tr(),
    //   'logo': 'assets/images/networks/alnasser.png',
    // },
    // {
    //   'name': 'network_alocean'.tr(),
    //   'logo': 'assets/images/networks/alocean.png',
    // },
    // {
    //   'name': 'network_alamri'.tr(),
    //   'logo': 'assets/images/networks/alamri.png',
    // },
    // {
    //   'name': 'network_yea_money'.tr(),
    //   'logo': 'assets/images/networks/yea_money.png',
    // },
    // {'name': 'network_hazmi'.tr(), 'logo': 'assets/images/networks/hazmi.png'},
    // {
    //   'name': 'network_alemtiyaz'.tr(),
    //   'logo': 'assets/images/networks/alemtiyaz.png',
    // },
    // {
    //   'name': 'network_alnajm'.tr(),
    //   'logo': 'assets/images/networks/alnajm.png',
    // },
    // {
    //   'name': 'network_yemen_express'.tr(),
    //   'logo': 'assets/images/networks/yemen_express.png',
    // },
    // {
    //   'name': 'network_alhoushabi'.tr(),
    //   'logo': 'assets/images/networks/alhoushabi.png',
    // },
    // {
    //   'name': 'network_alakwa'.tr(),
    //   'logo': 'assets/images/networks/alakwa.png',
    // },
    // {
    //   'name': 'network_yemeni'.tr(),
    //   'logo': 'assets/images/networks/yemeni_network.png',
    // },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDynamicNetworks();
    });
  }

  Future<void> _loadDynamicNetworks() async {
    try {
      // final String lang =
      //     (intl.Intl.getCurrentLocale().startsWith('ar')) ? 'ar' : 'en';
      String lang = context.locale.languageCode;
      final dynNets = await ApiService.getRemittanceNetworks(lang);
      if (mounted) {
        setState(() {
          // Filter out Saifi Cash/Pay if they are already in the hardcoded list
          _dynamicNetworks =
              dynNets.where((net) {
                final code = net.networkCode.toUpperCase();
                return !code.contains('SAIFI') &&
                    !code.contains('CASH') &&
                    !code.contains('PAY');
              }).toList();
        });
      }
    } catch (e) {
      customPrint('DEBUG: Error loading networks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> allNetworks = [
      ...networks,
      ..._dynamicNetworks.where((net) => net.isActive && net.isLocal),
    ];

    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader(context),
                const SizedBox(height: 5),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: allNetworks.length,
                        itemBuilder: (context, index) {
                          final network = allNetworks[index];
                          final bool isModel = network is RemittanceNetwork;

                          final String name =
                              isModel ? network.name : (network['name'] ?? '');
                          final String logo =
                              isModel ? network.icon : (network['logo'] ?? '');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color:
                                  widget.isDarkMode
                                      ? AppColors.cardDark
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade100,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 
                                    widget.isDarkMode ? 0.3 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              SendNetworkTransferScreen(
                                                isDarkMode: widget.isDarkMode,
                                                networkName: name,
                                                networkLogo: logo,
                                                initialPhone:
                                                    widget.initialPhone,
                                                initialRecipientName:
                                                    widget.initialRecipientName,
                                              ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'logo_$name',
                                        child: Container(
                                          width: 50,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 
                                                  0.1,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: _buildNetworkLogo(logo),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            color:
                                                widget.isDarkMode
                                                    ? Colors.white
                                                    : AppColors.textBlack,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color:
                                            widget.isDarkMode
                                                ? Colors.white24
                                                : Colors.black26,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          // .animate(delay: (index * 50).ms)
                          // .fadeIn(duration: 400.ms)
                          // .slideX(begin: 0.1, end: 0);
                        },
                      ),
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

  Widget _buildNetworkLogo(String logo) {
    if (logo.isEmpty) return _buildDefaultIcon();

    if (logo.startsWith('http')) {
      return Image.network(
        logo,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    } else if (logo.startsWith('/') || logo.startsWith('media/')) {
      // Handle relative paths from server
      String cleanBase = ApiService.baseUrl;
      if (cleanBase.endsWith('/')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 1);
      }
      final String fullUrl =
          logo.startsWith('/') ? '$cleanBase$logo' : '$cleanBase/$logo';
      return Image.network(
        fullUrl,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    } else if (logo.startsWith('assets/') || logo.contains('.png')) {
      final String path =
          logo.startsWith('assets/') ? logo : 'assets/images/$logo';
      return Image.asset(
        path,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.business_rounded,
      color: AppColors.adaptiveIcon(widget.isDarkMode),
      size: 24,
    );
  }

  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.adaptiveIcon(
                widget.isDarkMode,
              ).withValues(alpha: widget.isDarkMode ? 0.05 : 0.03),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
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

  Widget _buildPremiumHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'send_networks_title'.tr(),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
