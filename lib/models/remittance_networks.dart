import 'package:saifix/services/api_service.dart';

class RemittanceNetwork {
  final int id;
  final String nameAr;
  final String nameEn;
  final String networkCode;
  final int sortOrder;
  final String apiKey;
  final String endpointUrl;
  final bool isActive;
  final String icon;
  final bool isLocal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name; // Localized name

  RemittanceNetwork({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.networkCode,
    required this.sortOrder,
    required this.apiKey,
    required this.endpointUrl,
    required this.isActive,
    required this.icon,
    this.isLocal = true,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
  });

  factory RemittanceNetwork.fromJson(Map<String, dynamic> json, String lang) {
    String imageUrl = json['icon'] ?? '';
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('/')) {
        imageUrl =
            '${ApiService.baseUrl.endsWith('/') ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1) : ApiService.baseUrl}$imageUrl';
      } else {
        imageUrl = imageUrl.replaceAll(
          "http://wallet.alsaifiex.com/media/",
          "${ApiService.baseUrl}media/",
        );
      }
    }
    return RemittanceNetwork(
      id: json['id'] ?? 0,
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      networkCode: json['network_code'] ?? '',
      sortOrder: json['sort_order'] ?? 999,
      apiKey: json['api_key'] ?? '',
      endpointUrl: json['endpoint_url'] ?? '',
      isActive: json['is_active'] ?? false,
      icon: imageUrl,
      isLocal: json['is_local'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      name: lang == 'ar' ? (json['name_ar'] ?? '') : (json['name_en'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'network_code': networkCode,
      'sort_order': sortOrder,
      'api_key': apiKey,
      'endpoint_url': endpointUrl,
      'is_active': isActive,
      'is_local': isLocal,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
