// Sabafon Network Offers Data
// AC 7200 Direct Activation

class SabafonOffer {
  final String offerId;
  final String nameAr;
  final String payType; // 'دفع مسبق' or 'فوترة'
  final double price;
  final String category; // 'يومية', 'أسبوعية', 'شهرية', 'أخرى'

  SabafonOffer({
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

class SabafonOffersData {
  static List<SabafonOffer> getAllOffers() {
    return [
      // --- يومية (Daily) ---
      SabafonOffer(
        offerId: 'PRE281',
        nameAr: 'يابلاش اليومية',
        payType: 'دفع مسبق',
        price: 574.75,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'PRE251',
        nameAr: 'باقة واحد اليومية',
        payType: 'دفع مسبق',
        price: 508.2,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'PRE284',
        nameAr: 'أنتر يومي (1 جيجا)',
        payType: 'دفع مسبق',
        price: 500.0,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'PRE211',
        nameAr: 'نت يومي (150 ميجا)',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'PRE291',
        nameAr: 'سفري 4 ساعات',
        payType: 'دفع مسبق',
        price: 193.6,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'PRE292',
        nameAr: 'سفري 8 ساعات',
        payType: 'دفع مسبق',
        price: 290.4,
        category: 'يومية',
      ),

      // --- أسبوعية (Weekly) ---
      SabafonOffer(
        offerId: 'PRE232',
        nameAr: 'يابلاش الأسبوعية',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'PRE253',
        nameAr: 'باقة واحد الأسبوعية',
        payType: 'دفع مسبق',
        price: 810.7,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'PRE285',
        nameAr: 'أنتر أسبوعي (2 جيجا)',
        payType: 'دفع مسبق',
        price: 990.0,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'PRE221',
        nameAr: 'واتساب أسبوعي',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'PRE223',
        nameAr: 'فيسبوك أسبوعي',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'PRE293',
        nameAr: 'هايبرد أسبوعي',
        payType: 'دفع مسبق',
        price: 1400.0,
        category: 'أسبوعية',
      ),

      // --- شهرية (Monthly) ---
      SabafonOffer(
        offerId: 'PRE233',
        nameAr: 'يابلاش الشهرية',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE235',
        nameAr: 'يابلاش سوبر بلس',
        payType: 'دفع مسبق',
        price: 3025.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE280',
        nameAr: 'يابلاش 10 أيام',
        payType: 'دفع مسبق',
        price: 847.0,
        category: 'أخرى',
      ),
      SabafonOffer(
        offerId: 'PRE252',
        nameAr: 'باقة واحد الشهرية',
        payType: 'دفع مسبق',
        price: 1512.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE286',
        nameAr: 'أنتر 4 جيجا',
        payType: 'دفع مسبق',
        price: 1940.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE287',
        nameAr: 'أنتر 6 جيجا',
        payType: 'دفع مسبق',
        price: 2260.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE288',
        nameAr: 'أنتر 7 جيجا',
        payType: 'دفع مسبق',
        price: 3420.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE289',
        nameAr: 'أنتر 17 جيجا',
        payType: 'دفع مسبق',
        price: 4520.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE290',
        nameAr: 'أنتر ليلي',
        payType: 'دفع مسبق',
        price: 944.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE212',
        nameAr: 'سوبر نت 1 (750 ميجا)',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE213',
        nameAr: 'سوبر نت 2',
        payType: 'دفع مسبق',
        price: 1815.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE214',
        nameAr: 'سوبر نت 3',
        payType: 'دفع مسبق',
        price: 3025.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE216',
        nameAr: 'سوبر نت 4',
        payType: 'دفع مسبق',
        price: 4840.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE282',
        nameAr: 'واتساب بلس شهري',
        payType: 'دفع مسبق',
        price: 1573.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE224',
        nameAr: 'فيسبوك شهري',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE226',
        nameAr: 'تواصل شهري',
        payType: 'دفع مسبق',
        price: 1996.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE71106',
        nameAr: 'تواصل اكسترا',
        payType: 'دفع مسبق',
        price: 1028.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE236',
        nameAr: 'يابلاش كلام (مكالمات)',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE241',
        nameAr: 'باقة 700 رسالة',
        payType: 'دفع مسبق',
        price: 484.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE242',
        nameAr: 'باقة 6000 رسالة',
        payType: 'دفع مسبق',
        price: 726.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'PRE294',
        nameAr: 'هايبرد بلس',
        payType: 'دفع مسبق',
        price: 3350.0,
        category: 'شهرية',
      ),

      // --- فوترة (Billing) ---
      // يومية
      SabafonOffer(
        offerId: 'POS111',
        nameAr: 'نت يومي (150 ميجا)',
        payType: 'فوترة',
        price: 484.0,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'POS186',
        nameAr: 'سفري 4 ساعات',
        payType: 'فوترة',
        price: 193.6,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'POS187',
        nameAr: 'سفري 8 ساعات',
        payType: 'فوترة',
        price: 290.4,
        category: 'يومية',
      ),
      SabafonOffer(
        offerId: 'POS179',
        nameAr: 'أنتر يومي (1 جيجا)',
        payType: 'فوترة',
        price: 500.0,
        category: 'يومية',
      ),

      // أسبوعية
      SabafonOffer(
        offerId: 'POS180',
        nameAr: 'أنتر أسبوعي (2 جيجا)',
        payType: 'فوترة',
        price: 990.0,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'POS121',
        nameAr: 'واتساب أسبوعي',
        payType: 'فوترة',
        price: 484.0,
        category: 'أسبوعية',
      ),
      SabafonOffer(
        offerId: 'POS123',
        nameAr: 'فيسبوك + تويتر أسبوعي',
        payType: 'فوترة',
        price: 484.0,
        category: 'أسبوعية',
      ),

      // شهرية
      SabafonOffer(
        offerId: 'POS125',
        nameAr: 'تواصل اكسترا (85 وحدة)',
        payType: 'فوترة',
        price: 1028.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS126',
        nameAr: 'تواصل شهري (165 وحدة)',
        payType: 'فوترة',
        price: 1996.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS112',
        nameAr: 'سوبر نت 1 (750 ميجا)',
        payType: 'فوترة',
        price: 1210.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS113',
        nameAr: 'سوبر نت 2 (1.5 جيجا)',
        payType: 'فوترة',
        price: 1815.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS114',
        nameAr: 'سوبر نت 3 (3 جيجا)',
        payType: 'فوترة',
        price: 3025.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS116',
        nameAr: 'سوبر نت 4 (4 جيجا)',
        payType: 'فوترة',
        price: 4840.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS181',
        nameAr: 'أنتر 4 جيجا',
        payType: 'فوترة',
        price: 1940.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS182',
        nameAr: 'أنتر 6 جيجا',
        payType: 'فوترة',
        price: 2260.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS183',
        nameAr: 'أنتر 7 جيجا',
        payType: 'فوترة',
        price: 3420.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS184',
        nameAr: 'أنتر 17 جيجا',
        payType: 'فوترة',
        price: 4520.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS185',
        nameAr: 'أنتر ليلي',
        payType: 'فوترة',
        price: 944.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS122',
        nameAr: 'واتساب بلس شهري',
        payType: 'فوترة',
        price: 1512.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS132',
        nameAr: 'يابلاش كلام (مكالمات)',
        payType: 'فوترة',
        price: 1210.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS149',
        nameAr: 'باقة واحد الشهرية',
        payType: 'فوترة',
        price: 1512.5,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS175',
        nameAr: 'جي إس إم شهري',
        payType: 'فوترة',
        price: 1936.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS188',
        nameAr: 'هايبرد بلس',
        payType: 'فوترة',
        price: 3350.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS141',
        nameAr: 'باقة 700 رسالة',
        payType: 'فوترة',
        price: 484.0,
        category: 'شهرية',
      ),
      SabafonOffer(
        offerId: 'POS142',
        nameAr: 'باقة 6000 رسالة',
        payType: 'فوترة',
        price: 726.0,
        category: 'شهرية',
      ),
    ];
  }

  static List<SabafonOffer> getOffersByCategory(String category) {
    return getAllOffers().where((offer) => offer.category == category).toList();
  }

  static List<String> getCategories() {
    return ['يومية', 'أسبوعية', 'شهرية', 'أخرى'];
  }
}
