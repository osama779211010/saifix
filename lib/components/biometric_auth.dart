import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../helper/custom_print_helper.dart';
class BiometricAuth {
  static final _auth = LocalAuthentication();
  static bool? _isSupported;

  static Future<bool> canAuthenticate() async {
    if (_isSupported != null) return _isSupported!;
    try {
      _isSupported =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      _isSupported = false;
    }
    return _isSupported!;
  }

  static Future<bool> authenticate({required String reason}) async {
    try {
      // Fast check (cached)
      if (!await canAuthenticate()) return true;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          sensitiveTransaction: false, // Allow Face ID (Weak Biometric)
        ),
      );
    } on PlatformException catch (e) {
      customPrint('Biometric Error: $e');
      return false;
    }
  }
}
