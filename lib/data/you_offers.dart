// YOU Network Offers Data
// Optimized for GSM direct activation (AC 7200)

class YouOffer {
  final String offerId;
  final String nameAr;
  final String payType; // 'دفع مسبق' or 'فوترة'
  final double price;
  final String
  category; // 'مكس', 'نت', 'سوشال', 'مكالمات', 'توفير', 'رسائل', '4G'

  YouOffer({
    required this.offerId,
    required this.nameAr,
    required this.payType,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'offer_id': offerId,
      'name_ar': nameAr,
      'pay_type': payType,
      'amt': price,
      'category': category,
    };
  }
}

class YouOffersData {
  static List<YouOffer> getAllOffers() {
    return [
      // --- يومية (Daily) ---
      YouOffer(
        offerId: 'PRETawfeer',
        nameAr: 'باقة توفير يومية',
        payType: 'دفع مسبق',
        price: 496.1,
        category: 'يومية',
      ),
      YouOffer(
        offerId: 'POSTawfeer',
        nameAr: 'باقة توفير يومية (فوترة)',
        payType: 'فوترة',
        price: 496.1,
        category: 'يومية',
      ),

      // --- أسبوعية (Weekly) ---
      YouOffer(
        offerId: 'PREWeeklyMix',
        nameAr: 'باقة ماكس الأسبوعية',
        payType: 'دفع مسبق',
        price: 496.1,
        category: 'أسبوعية',
      ),
      YouOffer(
        offerId: 'WeeklyPRE600Min',
        nameAr: 'مكالمات أسبوعي 600 دقيقة',
        payType: 'دفع مسبق',
        price: 1004.3,
        category: 'أسبوعية',
      ),
      YouOffer(
        offerId: 'WeeklyPRE2GB',
        nameAr: 'سمارت أسبوعي 2 جيجا',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'أسبوعية',
      ),
      YouOffer(
        offerId: 'WeeklyPOS600Min',
        nameAr: 'مكالمات أسبوعي 600 دقيقة (فوترة)',
        payType: 'فوترة',
        price: 1004.3,
        category: 'أسبوعية',
      ),
      YouOffer(
        offerId: 'WeeklyPOS2GB',
        nameAr: 'سمارت أسبوعي 2 جيجا (فوترة)',
        payType: 'فوترة',
        price: 1210.0,
        category: 'أسبوعية',
      ),

      // --- شهرية (Monthly) ---
      // Mix
      YouOffer(
        offerId: 'PREMIX300',
        nameAr: 'باقة مكس 300',
        payType: 'دفع مسبق',
        price: 1249.93,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'PREMIX600',
        nameAr: 'باقة مكس 600',
        payType: 'دفع مسبق',
        price: 2420.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'PREMIXPLUS',
        nameAr: 'باقة مكس بلس',
        payType: 'دفع مسبق',
        price: 1512.5,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'POSMIXPLUS',
        nameAr: 'باقة مكس بلس (فوترة)',
        payType: 'فوترة',
        price: 1512.5,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Sawa_250_PRE',
        nameAr: 'سوا 250',
        payType: 'دفع مسبق',
        price: 1815.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Sawa_250_POS',
        nameAr: 'سوا 250 (فوترة)',
        payType: 'فوترة',
        price: 1815.0,
        category: 'شهرية',
      ),

      // Net
      YouOffer(
        offerId: 'PRESN188MB',
        nameAr: 'سمارت نت (500 ميجا)',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'POSSN250MB',
        nameAr: 'سمارت نت (250 ميجا)',
        payType: 'فوترة',
        price: 1210.0,
        category: 'شهرية',
      ),

      // Social
      YouOffer(
        offerId: 'PREWhatsApp',
        nameAr: 'واتساب بلا حدود',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'POSWhatsApp',
        nameAr: 'واتساب بلا حدود (فوترة)',
        payType: 'فوترة',
        price: 484.0,
        category: 'شهرية',
      ),

      // Calls
      YouOffer(
        offerId: 'PRE400Min',
        nameAr: 'باقة مكالمات 400 دقيقة',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'POS400Min',
        nameAr: 'باقة مكالمات 400 دقيقة (فوترة)',
        payType: 'فوترة',
        price: 1210.0,
        category: 'شهرية',
      ),

      // SMS
      YouOffer(
        offerId: 'PRE_750_SMS',
        nameAr: 'باقة رسائل',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'POS_750_SMS',
        nameAr: 'باقة رسائل (750 رسالة)',
        payType: 'فوترة',
        price: 1210.0,
        category: 'شهرية',
      ),

      // 4G
      YouOffer(
        offerId: 'Smart_0.5GB_4G_PRE',
        nameAr: 'سمارت 4G (0.5 جيجا)',
        payType: 'دفع مسبق',
        price: 266.2,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Smart_1GB_4G_PRE',
        nameAr: 'سمارت 4G (1 جيجا)',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Smart_5GB_4G_PRE',
        nameAr: 'سمارت 4G (5 جيجا)',
        payType: 'دفع مسبق',
        price: 2420.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Smart_8GB_4G_PRE',
        nameAr: 'سمارت 4G (8 جيجا)',
        payType: 'دفع مسبق',
        price: 3484.8,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Mix_1.5GB_4G_PRE',
        nameAr: 'مكس 4G (1.5 جيجا)',
        payType: 'دفع مسبق',
        price: 961.95,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Mix_6GB_4G_PRE',
        nameAr: 'مكس 4G (6 جيجا)',
        payType: 'دفع مسبق',
        price: 3412.2,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Smart3Giga4G_PRE',
        nameAr: 'سمارت 4G (3 جيجا)',
        payType: 'دفع مسبق',
        price: 1452.0,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Mix30Giga4G_PRE',
        nameAr: 'مكس 4G (30 جيجا)',
        payType: 'دفع مسبق',
        price: 14713.6,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Waffer_9G_4G_PRE',
        nameAr: 'وفر 4G (9 جيجا)',
        payType: 'دفع مسبق',
        price: 3484.8,
        category: 'شهرية',
      ),
      YouOffer(
        offerId: 'Smart20Giga_4G_PRE',
        nameAr: 'سمارت 4G (20 جيجا)',
        payType: 'دفع مسبق',
        price: 9680.0,
        category: 'شهرية',
      ),
    ];
  }

  static List<String> getCategories() {
    return ['يومية', 'أسبوعية', 'شهرية', 'أخرى'];
  }

  static List<YouOffer> getOffersByCategory(String category) {
    return getAllOffers().where((offer) => offer.category == category).toList();
  }
}
