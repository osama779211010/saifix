// Y (Way) Network Offers Data
// SC: 42104, AC: 7200, MT: 1 (Prepaid)

class YOffer {
  final String offerId;
  final String nameAr;
  final String payType; // 'دفع مسبق' only
  final double price;
  final String category; // 'أسبوعية', 'شهرية', 'أخرى'

  YOffer({
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

class YOffersData {
  static List<YOffer> getAllOffers() {
    return [
      // --- أسبوعية (Weekly) ---
      // Karam 250, Alo 250
      YOffer(
        offerId: '91',
        nameAr: 'باقة كرم 250',
        payType: 'دفع مسبق',
        price: 302.5,
        category: 'أسبوعية',
      ),
      YOffer(
        offerId: '72',
        nameAr: 'باقة ألو شحن 250',
        payType: 'دفع مسبق',
        price: 302.5,
        category: 'أسبوعية',
      ),

      // --- شهرية (Monthly) ---
      // Karam 500, Alo 1000
      YOffer(
        offerId: '92',
        nameAr: 'باقة كرم 500',
        payType: 'دفع مسبق',
        price: 605.0,
        category: 'شهرية',
      ),
      YOffer(
        offerId: '74',
        nameAr: 'باقة ألو شحن 1000',
        payType: 'دفع مسبق',
        price: 1210.0,
        category: 'شهرية',
      ),

      // --- أخرى (Other) ---
      // The rest
      YOffer(
        offerId: '93',
        nameAr: 'باقة كرم 900',
        payType: 'دفع مسبق',
        price: 1089.0,
        category: 'أخرى',
      ),
      YOffer(
        offerId: '94',
        nameAr: 'باقة كرم 2000',
        payType: 'دفع مسبق',
        price: 2420.0,
        category: 'أخرى',
      ),
      YOffer(
        offerId: '73',
        nameAr: 'باقة ألو شحن 500',
        payType: 'دفع مسبق',
        price: 605.0,
        category: 'أخرى',
      ),
      YOffer(
        offerId: '75',
        nameAr: 'باقة ألو شحن 2000',
        payType: 'دفع مسبق',
        price: 2420.0,
        category: 'أخرى',
      ),
    ];
  }

  static List<YOffer> getOffersByCategory(String category) {
    return getAllOffers().where((offer) => offer.category == category).toList();
  }

  static List<String> getCategories() {
    return ['أسبوعية', 'شهرية', 'أخرى'];
  }
}
