import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import '../services/api_service.dart';
import '../core/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Wait for splash animation (Reduced for faster startup)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // التحقق من حالة الدخول
    // contactService.preLoadContacts(); // Moved to when needed

    final bool hasAccounts = await ApiService.hasSavedAccounts();
    final bool showOnboarding = await ApiService.shouldShowOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            // ننتقل لشاشات التعريف فقط إذا كان الإصدار جديداً ولم يسجل المستخدم دخوله من قبل
            if (showOnboarding && !hasAccounts) {
              return const OnboardingScreen();
            }
            // في كافة الحالات الأخرى، ننتقل لشاشة تسجيل الدخول مباشرة
            return const LoginScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.accentBlue,
                  const Color(0xFF001F3F), // Deep space blue
                ],
              ),
            ),
          ),

          // Subtle Glow in the center
          Center(
            child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 1.seconds,
                  curve: Curves.easeInOut,
                ),
          ),

          // Main Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                      'pr_logo.png',
                      width: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('pr_logo.png', width: 200);
                      },
                    )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 1200.ms,
                    )
                    .shimmer(delay: 1000.ms, duration: 2.seconds),

                const SizedBox(height: 20),

                // Optional: Loading indicator or Tagline
                Text(
                  'أمان.. سرعة.. خصوصية \n Security, speed, privacy',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w300,
                  ),
                ).animate().fade(delay: 1000.ms, duration: 800.ms),
              ],
            ),
          ),

          // Bottom Version or Copy
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                'SAIFI PAY © 2026',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ).animate().fade(delay: 1500.ms),
        ],
      ),
    );
  }
}
