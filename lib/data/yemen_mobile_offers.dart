// Yemen Mobile Offers Data
// Updated with categories and subscription types

class YemenMobileOffer {
  final String offerId;
  final String nameAr;
  final String payType; // 'دفع مسبق' or 'فوترة'
  final double price;
  final String category; // 'يومية', 'أسبوعية', 'شهرية', 'أخرى'

  YemenMobileOffer({
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

class YemenMobileOffersData {
  static List<YemenMobileOffer> getAllOffers() {
    return [
      // --- يومية (تشمل 24 و 48 ساعة) ---
      YemenMobileOffer(
        offerId: '4990004',
        nameAr: 'باقة مزايا فورجي فولتي اليوميه',
        payType: 'دفع مسبق',
        price: 400,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: '4990003',
        nameAr: 'باقة مزايا فورجي فولتي اليوميه',
        payType: 'فوترة',
        price: 400,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: 'A4826',
        nameAr: 'باقة مزايا فورجي 24 ساعة',
        payType: 'دفع مسبق',
        price: 300,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: 'A4825',
        nameAr: 'باقة مزايا فورجي 24 ساعة',
        payType: 'فوترة',
        price: 300,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: 'A88337',
        nameAr: 'باقة مزايا فورجي 48 ساعة',
        payType: 'دفع مسبق',
        price: 600,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: 'A88340',
        nameAr: 'باقة مزايا فورجي 48 ساعة',
        payType: 'فوترة',
        price: 600,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: 'A4990004',
        nameAr: 'باقة مزايا فولتي 48 ساعة',
        payType: 'دفع مسبق',
        price: 600,
        category: 'يومية',
      ),
      YemenMobileOffer(
        offerId: 'A4990003',
        nameAr: 'باقة مزايا فولتي 48 ساعة',
        payType: 'فوترة',
        price: 600,
        category: 'يومية',
      ),

      // --- أسبوعية ---
      YemenMobileOffer(
        offerId: '4990005',
        nameAr: 'باقة مزايا فورجي فولتي الاسبوعيه',
        payType: 'دفع مسبق',
        price: 1400,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: '4990002',
        nameAr: 'باقة مزايا فورجي فولتي الاسبوعيه',
        payType: 'فوترة',
        price: 1400,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A88336',
        nameAr: 'باقة مزايا forum الاسبوعية',
        payType: 'دفع مسبق',
        price: 1500,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A88339',
        nameAr: 'باقة مزايا forum الاسبوعية',
        payType: 'فوترة',
        price: 1500,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A4990005',
        nameAr: 'باقة مزايا فولتي الاسبوعية',
        payType: 'دفع مسبق',
        price: 1500,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A4990002',
        nameAr: 'باقة مزايا فولتي الاسبوعية',
        payType: 'فوترة',
        price: 1500,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A3435',
        nameAr: 'باقه نت توفير 3 جيجا فورجي الاسبوعيه',
        payType: 'دفع مسبق',
        price: 1125,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A44355',
        nameAr: 'باقه نت توفير 3 جيجا فورجي الاسبوعيه',
        payType: 'فوترة',
        price: 1125,
        category: 'أسبوعية',
      ),
      YemenMobileOffer(
        offerId: 'A64329',
        nameAr: 'مزايا اسبوعي',
        payType: 'دفع مسبق',
        price: 485,
        category: 'أسبوعية',
      ),

      // --- بصلاحية 10 أيام (تصنف تحت أسبوعية أو أخرى، سنضعها في أخرى للتميز) ---
      YemenMobileOffer(
        offerId: 'A74331',
        nameAr: 'باقة 1 جيجا (10 أيام) - شريحة',
        payType: 'دفع مسبق',
        price: 1400,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A74332',
        nameAr: 'باقة 1 جيجا (10 أيام) - برمجة',
        payType: 'دفع مسبق',
        price: 1400,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A74335',
        nameAr: 'باقة 1 جيجا (10 أيام) - شريحة',
        payType: 'فوترة',
        price: 1400,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A74336',
        nameAr: 'باقة 1 جيجا (10 أيام) - برمجة',
        payType: 'فوترة',
        price: 1400,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A74337',
        nameAr: 'باقة 1 جيجا (10 أيام) - داتا',
        payType: 'دفع مسبق',
        price: 1400,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A74338',
        nameAr: 'باقة 1 جيجا (10 أيام) - داتا',
        payType: 'فوترة',
        price: 1400,
        category: 'أخرى',
      ),

      // --- شهرية ---
      YemenMobileOffer(
        offerId: '4990006',
        nameAr: 'باقة مزايا فورجي فولتي الشهريه',
        payType: 'دفع مسبق',
        price: 2400,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: '4990001',
        nameAr: 'باقة مزايا فورجي فولتي الشهريه',
        payType: 'فوترة',
        price: 2400,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A88335',
        nameAr: 'باقة مزايا forum الشهرية',
        payType: 'دفع مسبق',
        price: 2500,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A88338',
        nameAr: 'باقة مزايا forum الشهرية',
        payType: 'فوترة',
        price: 2500,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4990006',
        nameAr: 'باقة مزايا فولتي الشهرية',
        payType: 'دفع مسبق',
        price: 2500,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4990001',
        nameAr: 'باقة مزايا فولتي الشهرية',
        payType: 'فوترة',
        price: 2500,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A88441',
        nameAr: 'باقة مزايا ماكس فورجي',
        payType: 'دفع مسبق',
        price: 4000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A88440',
        nameAr: 'باقة مزايا ماكس فورجي',
        payType: 'فوترة',
        price: 4000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A3823',
        nameAr: 'باقة مزايا توفير فورجي الشهرية',
        payType: 'دفع مسبق',
        price: 2400,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4823',
        nameAr: 'باقة مزايا توفير فورجي الشهرية',
        payType: 'فوترة',
        price: 2400,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A3822',
        nameAr: 'باقة نت توفير فورجي 7 جيجا الشهرية',
        payType: 'دفع مسبق',
        price: 3000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4818',
        nameAr: 'باقة نت توفير فورجي 7 جيجا الشهرية',
        payType: 'فوترة',
        price: 3000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A3825',
        nameAr: 'باقة نت توفير فورجي 5 جيجا الشهرية',
        payType: 'دفع مسبق',
        price: 2300,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4819',
        nameAr: 'باقة نت توفير فورجي 5 جيجا الشهرية',
        payType: 'فوترة',
        price: 2300,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4821',
        nameAr: 'باقة نت فورجي 4 جيجا الشهرية',
        payType: 'دفع مسبق',
        price: 2000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4820',
        nameAr: 'باقة نت فورجي 4 جيجا الشهرية',
        payType: 'فوترة',
        price: 2000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4828',
        nameAr: 'باقة نت فورجي 8 جيجا الشهرية',
        payType: 'دفع مسبق',
        price: 3900,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4822',
        nameAr: 'باقة نت فورجي 8 جيجا الشهرية',
        payType: 'فوترة',
        price: 3900,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4830',
        nameAr: 'باقة نت فورجي 20 جيجا الشهرية',
        payType: 'دفع مسبق',
        price: 9700,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A4829',
        nameAr: 'باقة نت فورجي 20 جيجا الشهرية',
        payType: 'فوترة',
        price: 9700,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A3436',
        nameAr: 'باقه نت توفير 6 جيجا فورجي الشهريه',
        payType: 'دفع مسبق',
        price: 2250,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A44356',
        nameAr: 'باقه نت توفير 6 جيجا فورجي الشهريه',
        payType: 'فوترة',
        price: 2250,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A34346',
        nameAr: 'باقه نت توفير 11 جيجا فورجي',
        payType: 'دفع مسبق',
        price: 4125,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A44345',
        nameAr: 'باقه نت توفير 11 جيجا فورجي',
        payType: 'فوترة',
        price: 4125,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A3347',
        nameAr: 'باقه نت توفير 25 جيجا فورجي',
        payType: 'دفع مسبق',
        price: 8830,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A44347',
        nameAr: 'باقه نت توفير 25 جيجا فورجي',
        payType: 'فوترة',
        price: 8830,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A39053',
        nameAr: 'باقة مزايا أعمال فورجي الشهريه 6 جيجا',
        payType: 'دفع مسبق',
        price: 5000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A49053',
        nameAr: 'باقة مزايا أعمال فورجي الشهريه 6 جيجا',
        payType: 'فوترة',
        price: 5000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A5533821',
        nameAr: 'باقة سوبر فورجي الشهرية',
        payType: 'فوترة',
        price: 2000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A5533822',
        nameAr: 'باقة سوبر فورجي الشهرية',
        payType: 'دفع مسبق',
        price: 2000,
        category: 'شهرية',
      ),

      // --- انترنت داتا (تصنف شهرية أو أخرى حسب الرغبة، سنضعها في أخرى لتميزها كداتا) ---
      YemenMobileOffer(
        offerId: 'A70333',
        nameAr: 'انترنت داتا 1500 ميجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 3300,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70329',
        nameAr: 'انترنت داتا 150 ميجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 500,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70337',
        nameAr: 'انترنت داتا 15 جيجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 15000,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70330',
        nameAr: 'انترنت داتا 300 ميجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 900,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70334',
        nameAr: 'انترنت داتا 3 جيجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 4500,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70331',
        nameAr: 'انترنت داتا 450 ميجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 1300,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70335',
        nameAr: 'انترنت داتا 5 جيجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 7000,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70332',
        nameAr: 'انترنت داتا 700 ميجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 1800,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A70336',
        nameAr: 'انترنت داتا 7 جيجا - دفع مسبق (3G)',
        payType: 'دفع مسبق',
        price: 9000,
        category: 'أخرى',
      ),

      // --- هدايا ومزايا أخرى ---
      YemenMobileOffer(
        offerId: 'A66328',
        nameAr: 'باقة هدايا توفير',
        payType: 'فوترة',
        price: 250,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A68329',
        nameAr: 'باقة هدايا الشهرية',
        payType: 'فوترة',
        price: 1500,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A38394',
        nameAr: 'مزايا دفع مسبق',
        payType: 'دفع مسبق',
        price: 1300,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A44330',
        nameAr: 'هدايا فوترة',
        payType: 'فوترة',
        price: 582,
        category: 'أخرى',
      ),
      YemenMobileOffer(
        offerId: 'A75328',
        nameAr: 'مزايا ماكس',
        payType: 'دفع مسبق',
        price: 2000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A76328',
        nameAr: 'هدايا ماكس',
        payType: 'فوترة',
        price: 3000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A41338',
        nameAr: '800 رساله الشهريه',
        payType: 'فوترة',
        price: 1000,
        category: 'شهرية',
      ),
      YemenMobileOffer(
        offerId: 'A31338',
        nameAr: '800 رساله الشهريه',
        payType: 'دفع مسبق',
        price: 1000,
        category: 'شهرية',
      ),
    ];
  }

  static List<YemenMobileOffer> getOffersByCategory(String category) {
    return getAllOffers().where((offer) => offer.category == category).toList();
  }
}
