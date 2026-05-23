class RechargeOffer {
  final int id;
  final String serviceCode;
  final String offerId;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final double amount;
  final int subscriberType; // 0: PostPaid, 1: PrePaid, 2: PrePaid سبق دفع
  final int? itemCode;
  final bool isActive;

  RechargeOffer({
    required this.id,
    required this.serviceCode,
    required this.offerId,
    required this.nameAr,
    this.nameEn,
    this.description,
    required this.amount,
    required this.subscriberType,
    this.itemCode,
    required this.isActive,
  });

  factory RechargeOffer.fromJson(Map<String, dynamic> json) {
    return RechargeOffer(
      id: json['id'] as int,
      serviceCode: json['service_code'] as String,
      offerId: json['offer_id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String?,
      description: json['description'] as String?,
      amount: double.parse(json['amount'].toString()),
      subscriberType: json['subscriber_type'] as int,
      itemCode: json['item_code'] as int?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_code': serviceCode,
      'offer_id': offerId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description': description,
      'amount': amount,
      'subscriber_type': subscriberType,
      'item_code': itemCode,
      'is_active': isActive,
    };
  }

  String get subscriberTypeLabel {
    switch (subscriberType) {
      case 0:
        return 'فاتورة';
      case 1:
        return 'سبق دفع';
      case 2:
        return 'سبق دفع (خاص)';
      default:
        return 'غير محدد';
    }
  }
}
