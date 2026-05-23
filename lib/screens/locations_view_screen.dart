import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LocationsViewScreen extends StatefulWidget {
  final bool isDarkMode;

  const LocationsViewScreen({super.key, required this.isDarkMode});

  @override
  State<LocationsViewScreen> createState() => _LocationsViewScreenState();
}

class _LocationsViewScreenState extends State<LocationsViewScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _branches = [];
  List<dynamic> _filteredBranches = [];
  bool _isLoading = true;
  bool _isListView = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    try {
      final data = await ApiService.getMapBranches();
      if (mounted) {
        setState(() {
          _branches = data;
          _filteredBranches = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterBranches(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBranches = _branches;
      } else {
        _filteredBranches = _branches.where((branch) {
          final name = (branch['name'] ?? '').toString().toLowerCase();
          final agent = (branch['agent_name'] ?? '').toString().toLowerCase();
          final gov = (branch['governorate'] ?? '').toString().toLowerCase();
          final area = (branch['area'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
              agent.contains(searchLower) ||
              gov.contains(searchLower) ||
              area.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _findNearestBranch() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خدمات الموقع معطلة')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض صلاحية الوصول للموقع')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('صلاحية الموقع مرفوضة دائماً')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);

      if (_branches.isEmpty) return;

      dynamic nearest;
      double minDistance = double.infinity;
      const distance = Distance();

      for (var branch in _branches) {
        final lat = double.tryParse(branch['lat'].toString());
        final lng = double.tryParse(branch['lng'].toString());
        if (lat != null && lng != null) {
          final branchLatLng = LatLng(lat, lng);
          final d = distance.as(LengthUnit.Meter, userLatLng, branchLatLng);
          if (d < minDistance) {
            minDistance = d;
            nearest = branch;
          }
        }
      }

      if (nearest != null) {
        _mapController.move(
          LatLng(
            double.parse(nearest['lat'].toString()),
            double.parse(nearest['lng'].toString()),
          ),
          15.0,
        );
        _showBranchDetails(nearest);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديد الموقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMap(String? urlString, String? lat, String? lng) async {
    Uri url;
    if (urlString != null && urlString.isNotEmpty) {
      url = Uri.parse(urlString);
    } else if (lat != null && lng != null) {
      url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      return;
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('could_not_open_map'.tr())),
        );
      }
    }
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse('tel:$phone');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('could_not_call'.tr())),
        );
      }
    }
  }

  void _showBranchDetails(dynamic branch) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBranchDetailSheet(branch),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : Colors.grey[50],
      body: Stack(
        children: [
          // Background/Map
          _isListView ? _buildListView() : _buildMapView(),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? AppColors.scaffoldDark.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPremiumHeader(
                      'service_points'.tr(),
                      () => Navigator.pop(context),
                    ),
                    _buildSearchBarArea(),
                  ],
                ),
              ),
            ),
          ),

          // Floating Controls
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Toggle
                FloatingActionButton.extended(
                  heroTag: 'toggle_view',
                  onPressed: () => setState(() => _isListView = !_isListView),
                  label: Text(_isListView ? 'map_view'.tr() : 'list_view'.tr()),
                  icon: Icon(_isListView ? Icons.map : Icons.list),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),

                // Re-center button (only in map view)
                if (!_isListView &&
                    !_isLoading &&
                    _filteredBranches.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'recenter_map',
                    mini: true,
                    backgroundColor: AppColors.accentBlue,
                    onPressed: () {
                      if (_filteredBranches.isNotEmpty) {
                        _mapController.move(
                          LatLng(
                            double.tryParse(
                                    _filteredBranches[0]['lat'].toString()) ??
                                15.3524,
                            double.tryParse(
                                    _filteredBranches[0]['lng'].toString()) ??
                                44.2251,
                          ),
                          13.0,
                        );
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarArea() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white10 : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterBranches,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            ),
            decoration: InputDecoration(
              hintText: 'search_branches'.tr(),
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white54 : Colors.black38,
              ),
              border: InputBorder.none,
              icon: Icon(
                Icons.search_rounded,
                color: AppColors.accentBlue,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _filterBranches('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: _findNearestBranch,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.near_me_rounded,
                      size: 18, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'أقرب فرع لك',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            _filteredBranches.isNotEmpty && _filteredBranches[0]['lat'] != null
                ? LatLng(
                    double.tryParse(_filteredBranches[0]['lat'].toString()) ??
                        15.3524,
                    double.tryParse(_filteredBranches[0]['lng'].toString()) ??
                        44.2251,
                  )
                : const LatLng(15.3524, 44.2251),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.alsaifi.wallet',
        ),
        MarkerLayer(
          markers: _filteredBranches
              .map((branch) {
                final latStr = (branch['lat'] ?? '').toString();
                final lngStr = (branch['lng'] ?? '').toString();
                final lat = double.tryParse(latStr);
                final lng = double.tryParse(lngStr);
                if (lat == null || lng == null) return null;

                return Marker(
                  point: LatLng(lat, lng),
                  width: 100,
                  height: 100,
                  child: GestureDetector(
                    onTap: () => _showBranchDetails(branch),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? AppColors.cardDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            branch['name'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.textBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_circle.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.location_on, size: 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .whereType<Marker>()
              .toList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_filteredBranches.isEmpty) {
      return Center(child: Text('no_results_found'.tr()));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 160),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: _filteredBranches.length,
          itemBuilder: (context, index) {
            final branch = _filteredBranches[index];
            return _buildBranchCard(branch, index);
          },
        ),
      ),
    );
  }

  Widget _buildBranchCard(dynamic branch, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.business_rounded, color: AppColors.accentBlue),
        ),
        title: Text(
          branch['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : AppColors.primaryBlue,
          ),
        ),
        subtitle: Text(
          branch['address'] ?? branch['street'] ?? '',
          style: TextStyle(
            fontSize: 12,
            color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.map_outlined,
                  label: 'location'.tr(),
                  color: Colors.green,
                  onTap: () => _openMap(
                    branch['map_url'],
                    branch['lat']?.toString(),
                    branch['lng']?.toString(),
                  ),
                ),
                _buildActionButton(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'call'.tr(),
                  color: Colors.blue,
                  onTap: () => _callPhone(branch['phone_number']),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
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

  Widget _buildBranchDetailSheet(dynamic branch) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business_rounded, color: AppColors.accentBlue),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch['name'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode
                            ? Colors.white
                            : AppColors.textBlack,
                      ),
                    ),
                    Text(
                      branch['agent_name'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.location_on_outlined,
            '${branch['governorate'] ?? ''} - ${branch['area'] ?? ''} - ${branch['street'] ?? ''}\n${branch['address'] ?? ''}',
          ),
          const SizedBox(height: 16),
          if (branch['phone_number'] != null || branch['fixed_phone'] != null)
            _buildInfoRow(
              Icons.phone_outlined,
              '${branch['phone_number'] ?? ''} ${branch['fixed_phone'] != null ? ' | ${branch['fixed_phone']}' : ''}',
            ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMap(
                    branch['map_url'],
                    branch['lat']?.toString(),
                    branch['lng']?.toString(),
                  ),
                  icon: const Icon(Icons.directions_rounded),
                  label: Text('directions'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (branch['phone_number'] != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    onPressed: () => _callPhone(branch['phone_number']),
                    icon: const Icon(Icons.call, color: Colors.green),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
