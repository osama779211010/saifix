import 'package:flutter/services.dart';

class ArabicToEnglishNumbersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = convertArabicToEnglish(newValue.text);

    return newValue.copyWith(
      text: newText,
      selection: newValue.selection,
    );
  }

  static String convertArabicToEnglish(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result;
  }
}
