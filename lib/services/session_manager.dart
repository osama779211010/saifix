import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../main.dart'; // To access navigatorKey
import '../screens/auth/login_screen.dart';
import '../core/app_colors.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _sessionTimer;
  bool _isOperationInProgress = false;
  bool _isDialogShowing = false;

  // Set this to true when starting a sensitive operation (like payment)
  set isOperationInProgress(bool value) {
    _isOperationInProgress = value;
    // If an operation was pending and just finished, we might need to check if the session expired
    if (!_isOperationInProgress && _sessionTimer == null) {
      // Logic for delayed logout could go here if needed
    }
  }

  void startSession() async {
    _stopTimer();
    // Only start timer if user is authenticated
    if (!ApiService.isAuthenticated) return;

    final prefs = await SharedPreferences.getInstance();
    final int timeoutMinutes = prefs.getInt('session_timeout') ?? 5;

    _sessionTimer = Timer(Duration(minutes: timeoutMinutes), () {
      _handleSessionTimeout();
    });
  }

  Future<void> setSessionTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_timeout', minutes);
    if (ApiService.isAuthenticated) {
      startSession();
    }
  }

  Future<int> getSessionTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('session_timeout') ?? 5;
  }

  void stopSession() {
    _stopTimer();
  }

  void _stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _handleSessionTimeout() async {
    // If an operation is in progress, wait a bit or wait until it's done
    if (_isOperationInProgress) {
      // Re-check every 10 seconds if operation is done
      Timer.periodic(const Duration(seconds: 10), (timer) {
        if (!_isOperationInProgress) {
          timer.cancel();
          _performLogout();
        }
      });
      return;
    }

    _performLogout();
  }

  void _performLogout() async {
    if (_isDialogShowing) return;

    // Check if we are already logged out (token cleared)
    if (!ApiService.isAuthenticated) {
      _stopTimer();
      return;
    }

    await ApiService.logout();
    _stopTimer();

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      isDark ? 'pr_logo.png' : 'logo_circle.png',
                      width: 60,
                      errorBuilder:
                          (c, e, s) => const Icon(
                            Icons.account_balance_rounded,
                            size: 50,
                            color: AppColors.primaryBlue,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'session_expired_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'session_expired_message'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        _isDialogShowing = false;
                        Navigator.of(ctx).pop();
                        navigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ok'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Fallback if context is not available
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

final sessionManager = SessionManager();
