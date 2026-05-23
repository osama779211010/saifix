import 'package:intl/intl.dart' as intl;

class AmountConverter {
  static String convert(double amount) {
    if (amount == 0) return 'صفر';

    int integerPart = amount.floor();
    int decimalPart = ((amount - integerPart) * 100).round();

    String result = _numberToWords(integerPart);

    if (decimalPart > 0) {
      result += ' و ${_numberToWords(decimalPart)} فلس';
    }

    return result;
  }

  static String _numberToWords(int number) {
    if (number == 0) return '';
    if (number < 0) return 'سالب${_numberToWords(number.abs())}';

    final List<String> units = [
      '',
      'ألف',
      'مليون',
      'مليار',
      'ترليون',
      'كوادريليون',
    ];
    List<String> groups = [];
    int unitIndex = 0;
    int tempNumber = number;

    while (tempNumber > 0 && unitIndex < units.length) {
      int groupValue = tempNumber % 1000;
      if (groupValue > 0) {
        String groupWords = _processGroup(groupValue, units[unitIndex]);
        groups.insert(0, groupWords);
      }
      tempNumber ~/= 1000;
      unitIndex++;
    }

    if (groups.isEmpty) return 'صفر';
    return groups.where((g) => g.isNotEmpty).join(' و ');
  }

  static String _processGroup(int number, String unit) {
    if (number == 0) return '';

    String words = '';
    int h = number ~/ 100;
    int t = number % 100;

    // Hundreds
    if (h > 0) {
      if (h == 1) {
        words = 'مائة';
      } else if (h == 2) {
        words = 'مائتان';
      } else if (h == 8) {
        words = 'ثمانمائة';
      } else {
        words = '${_ones[h].replaceAll('ة', '')}مائة';
      }
    }

    // Tens and Ones
    if (t > 0) {
      if (words.isNotEmpty) words += ' و ';

      if (t < 10) {
        words += _ones[t];
      } else if (t < 20) {
        words += _teens[t - 10];
      } else {
        int tens = t ~/ 10;
        int ones = t % 10;
        if (ones > 0) words += '${_ones[ones]} و ';
        words += _tens[tens];
      }
    }

    if (unit.isEmpty) return words;

    // Handle Unit Pluralization
    if (number == 1) return unit;
    if (number == 2) {
      if (unit == 'ألف') return 'ألفان';
      if (unit == 'مليون') return 'مليونان';
      if (unit == 'مليار') return 'ملياران';
      if (unit == 'ترليون') return 'ترليونان';
    }
    if (number >= 3 && number <= 10) {
      if (unit == 'ألف') return '$words آلاف';
      if (unit == 'مليون') return '$words ملايين';
      if (unit == 'مليار') return '$words مليارات';
      if (unit == 'ترليون') return '$words ترليونات';
    }

    return '$words $unit';
  }

  static const List<String> _ones = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
  ];

  static const List<String> _teens = [
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  static const List<String> _tens = [
    '',
    '',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];
}

/// دالة مساعدة لتحويل المبلغ إلى كلمات بالعربية
String formatAmountToArabicWords(double amount) {
  return AmountConverter.convert(amount);
}
String formatAmountDisplay(double amount) {
  final formatter = intl.NumberFormat('#,##0.##');
  return formatter.format(amount);
}

int toIntAmount(double amount) {
  return amount.toInt();
}
