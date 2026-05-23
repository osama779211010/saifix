import 'package:flutter/material.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

enum VoiceIntent {
  navigateTransfers,
  navigateTransferToSubscriber,
  inputPhone,
  inputAmount,
  confirmTransfer,
  unknown,
}

class VoiceCommandResult {
  final VoiceIntent intent;
  final String? value;
  final String? currency;
  final String? phone;
  final String? amount;
  final String originalText;
  final bool isConfirmed;

  VoiceCommandResult({
    required this.intent,
    this.value,
    this.currency,
    this.phone,
    this.amount,
    required this.originalText,
    this.isConfirmed = false,
  });
}

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> transcribedText = ValueNotifier<String>('');
  final ValueNotifier<VoiceCommandResult?> latestCommand =
      ValueNotifier<VoiceCommandResult?>(null);

  Future<bool> init() async {
    if (_isAvailable) return true;

    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'listening') isListening.value = true;
          if (status == 'notListening' || status == 'done') {
            isListening.value = false;
          }
        },
        onError: (errorNotification) {
          isListening.value = false;
          customPrint('Speech Error: ${errorNotification.errorMsg}');
        },
      );
    }
    return _isAvailable;
  }

  void startListening() async {
    if (!_isAvailable) {
      bool ok = await init();
      if (!ok) return;
    }

    transcribedText.value = 'جاري الاستماع...';
    _speech.listen(
      localeId: 'ar_SA', // Arabic Locale
      onResult: (result) {
        transcribedText.value = result.recognizedWords;
        if (result.finalResult) {
          _processText(result.recognizedWords);
        }
      },
    );
  }

  void stopListening() {
    _speech.stop();
    isListening.value = false;
  }

  void _processText(String text) {
    String normalized = _normalizeArabic(text);
    customPrint('Processing Voice: $normalized');

    VoiceIntent intent = VoiceIntent.unknown;
    String? value;
    String? currency;
    String? phone;
    String? amount;
    bool isConfirmed = false;

    // معالجة الأوامر المعقدة (سطر كامل يحتوي على تفاصيل التحويل)
    bool isComplexCommand =
        (normalized.contains('تحويل') || normalized.contains('ارسال')) &&
        (normalized.contains('رقم') ||
            normalized.contains('هاتف') ||
            normalized.contains('مشترك')) &&
        (normalized.contains('مبلغ') ||
            RegExp(r'[0-9]+\s*(ريال|دولار|سعودي|يمني)').hasMatch(normalized));

    if (isComplexCommand) {
      intent = VoiceIntent.navigateTransferToSubscriber;

      // Extract Phone (matches 7 to 9 digits usually)
      final phoneMatch =
          RegExp(
            r'(?:رقم|هاتف|جوال|تلفون|مشترك)\s*(?:الهاتف)?\s*([0-9]{7,})',
          ).firstMatch(normalized) ??
          RegExp(r'([0-9]{7,})').firstMatch(normalized);
      if (phoneMatch != null) phone = phoneMatch.group(1);

      // Extract Amount
      final amountMatch =
          RegExp(r'(?:مبلغ|المبلغ)\s*([0-9]+)').firstMatch(normalized) ??
          RegExp(
            r'([0-9]+)\s*(?:ريال|دولار|سعودي|يمني)',
          ).firstMatch(normalized);
      if (amountMatch != null) amount = amountMatch.group(1);

      // Extract Currency
      if (normalized.contains('يمني') || normalized.contains('ر.ي')) {
        currency = 'YER';
      } else if (normalized.contains('دولار') ||
          normalized.contains('امريكي')) {
        currency = 'USD';
      } else if (normalized.contains('سعودي') || normalized.contains('ر.س')) {
        currency = 'SAR';
      }

      // Check for confirmation word
      if (normalized.contains('تاكيد') ||
          normalized.contains('موافق') ||
          normalized.contains('ارسل')) {
        isConfirmed = true;
      }
    } else {
      // 1. التنقل إلى التحويلات البسيطة
      if (normalized.contains('تحويل الي مشترك') ||
          normalized.contains('تحويل مشترك')) {
        intent = VoiceIntent.navigateTransferToSubscriber;
      } else if (normalized.contains('تحويلات ماليه') ||
          normalized.contains('فتح التحويلات')) {
        intent = VoiceIntent.navigateTransfers;
      }
      // 2. إدخال مبلغ (بسيط)
      else if (normalized.contains('مبلغ') || normalized.contains('بمبلغ')) {
        intent = VoiceIntent.inputAmount;
        value = _extractNumbers(normalized);

        if (normalized.contains('يمني') || normalized.contains('ر.ي')) {
          currency = 'YER';
        } else if (normalized.contains('دولار') ||
            normalized.contains('امريكي')) {
          currency = 'USD';
        } else if (normalized.contains('سعودي')) {
          currency = 'SAR';
        }
      }
      // 3. إدخال رقم هاتف (بسيط)
      else if (normalized.contains('رقم') ||
          normalized.contains('هاتف') ||
          normalized.contains('جوال') ||
          normalized.contains('تلفون')) {
        intent = VoiceIntent.inputPhone;
        value = _extractNumbers(normalized);
      }
      // 4. تأكيد التحويل المباشر
      else if (normalized.contains('تاكيد') ||
          normalized.contains('تحويله') ||
          normalized.contains('موافق') ||
          (normalized.contains('تحويل') &&
              (normalized.contains('الان') || normalized.length < 10))) {
        intent = VoiceIntent.confirmTransfer;
      }
    }

    latestCommand.value = VoiceCommandResult(
      intent: intent,
      value: value,
      currency: currency,
      phone: phone,
      amount: amount,
      originalText: text,
      isConfirmed: isConfirmed,
    );
  }

  String _normalizeArabic(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[\u0640]'), '');
  }

  String _extractNumbers(String text) {
    // استخراج الأرقام من النص
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

final voiceCommandService = VoiceCommandService();
