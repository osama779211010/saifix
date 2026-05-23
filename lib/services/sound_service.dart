import 'package:audioplayers/audioplayers.dart';
import 'package:saifix/helper/custom_print_helper.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  /// تهيئة الخدمة (اختياري، يمكن أن تتم آلياً عند أول تشغيل)
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // إعدادات أولية إذا لزم الأمر
      _initialized = true;
    } catch (e) {
      customPrint('Error initializing SoundService: $e');
    }
  }

  /// تشغيل صوت النجاح (Apple Pay style)
  static Future<void> playSuccessSound() async {
    try {
      await _player.play(AssetSource('sounds/success.wav'));
    } catch (e) {
      customPrint(
        'Error playing success sound: $e. Make sure assets/sounds/success.wav exists.',
      );
      // يمكن إضافة صوت نظام كبديل إذا فشل تشغيل الملف المخصص
    }
  }
}

// إنشاء نسخة عالمية للوصول السهل
final soundService = SoundService();
