import 'package:intl/intl.dart';

class DateHelper {
  static const String defaultLocale = 'en_US';

  /// formats DateTime with custom pattern, forcing English locale
  static String format(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, defaultLocale).format(date);
  }

  /// formats DateTime to 'dd/MM/yyyy HH:mm', forcing English locale
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', defaultLocale).format(date);
  }

  /// formats DateTime to 'hh:mm a', forcing English locale
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', defaultLocale).format(date);
  }

  /// returns a DateFormat instance with English locale
  static DateFormat get englishDateFormat => DateFormat('dd/MM/yyyy', defaultLocale);
  
  /// returns a DateFormat instance with English locale and custom pattern
  static DateFormat customDateFormat(String pattern) => DateFormat(pattern, defaultLocale);
}
