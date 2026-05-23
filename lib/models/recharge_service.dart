class RechargeService {
  final int id;
  final String serviceCode;
  final String nameAr;
  final String nameEn;
  final String serviceType;
  final String? iconUrl;
  final bool isActive;
  final double? minAmountPrepaid;
  final double? minAmountPostpaid;
  final bool acceptsAnyAmountPrepaid;
  final bool acceptsAnyAmountPostpaid;

  RechargeService({
    required this.id,
    required this.serviceCode,
    required this.nameAr,
    required this.nameEn,
    required this.serviceType,
    this.iconUrl,
    required this.isActive,
    this.minAmountPrepaid,
    this.minAmountPostpaid,
    required this.acceptsAnyAmountPrepaid,
    required this.acceptsAnyAmountPostpaid,
  });

  factory RechargeService.fromJson(Map<String, dynamic> json) {
    return RechargeService(
      id: json['id'] as int,
      serviceCode: json['service_code'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      serviceType: json['service_type'] as String,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool,
      minAmountPrepaid:
          json['min_amount_prepaid'] != null
              ? double.parse(json['min_amount_prepaid'].toString())
              : null,
      minAmountPostpaid:
          json['min_amount_postpaid'] != null
              ? double.parse(json['min_amount_postpaid'].toString())
              : null,
      acceptsAnyAmountPrepaid:
          json['accepts_any_amount_prepaid'] as bool? ?? false,
      acceptsAnyAmountPostpaid:
          json['accepts_any_amount_postpaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_code': serviceCode,
      'name_ar': nameAr,
      'name_en': nameEn,
      'service_type': serviceType,
      'icon_url': iconUrl,
      'is_active': isActive,
      'min_amount_prepaid': minAmountPrepaid,
      'min_amount_postpaid': minAmountPostpaid,
      'accepts_any_amount_prepaid': acceptsAnyAmountPrepaid,
      'accepts_any_amount_postpaid': acceptsAnyAmountPostpaid,
    };
  }

  /// Validate amount based on subscriber type
  ValidationResult validateAmount(double amount, int subscriberType) {
    // PrePaid validation
    if (subscriberType == 1) {
      if (acceptsAnyAmountPrepaid) {
        return ValidationResult(isValid: true);
      }

      if (minAmountPrepaid != null && amount < minAmountPrepaid!) {
        return ValidationResult(
          isValid: false,
          errorMessage:
              'الحد الأدنى للمبلغ هو ${minAmountPrepaid!.toStringAsFixed(0)} ريال',
        );
      }
    }
    // PostPaid validation
    else if (subscriberType == 0 || subscriberType == 2) {
      if (acceptsAnyAmountPostpaid) {
        return ValidationResult(isValid: true);
      }

      if (minAmountPostpaid != null && amount < minAmountPostpaid!) {
        return ValidationResult(
          isValid: false,
          errorMessage:
              'الحد الأدنى للمبلغ هو ${minAmountPostpaid!.toStringAsFixed(0)} ريال',
        );
      }
    }

    return ValidationResult(isValid: true);
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorMessage});
}
