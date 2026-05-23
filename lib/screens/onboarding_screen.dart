import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'onb_title_1'.tr(),
      description: 'onb_desc_1'.tr(),
      image: 'logo_circle.png',
      backgroundImage: 'back 1 .png',
    ),
    OnboardingData(
      title: 'onb_title_2'.tr(),
      description: 'onb_desc_2'.tr(),
      image: 'pr_logo.png',
      backgroundImage: 'back2.png',
    ),
    OnboardingData(
      title: 'onb_title_3'.tr(),
      description: 'onb_desc_3'.tr(),
      image: 'logo_circle.png',
      backgroundImage: 'back 1 .png',
    ),
    OnboardingData(
      title: 'onb_title_4'.tr(),
      description: 'onb_desc_4'.tr(),
      image: 'pr_logo.png',
      backgroundImage: 'back2.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light mode as requested
      body: Stack(
        children: [
          // Background Image (Changes with page)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                _pages[_currentPage].backgroundImage,
                key: ValueKey(_pages[_currentPage].backgroundImage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                opacity: const AlwaysStoppedAnimation(0.3), // Faint background
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Static Logo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset('logo_circle.png', height: 60),
                  ),
                ),

                // Features PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Next or Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              await _finishOnboarding(const LoginScreen());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'login_button'.tr()
                                : 'next_button'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () async {
                            await _finishOnboarding(
                              const LoginScreen(showRegisterOnInit: true),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryBlue),
                            foregroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'create_account_button'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding(Widget screen) async {
    await ApiService.markOnboardingAsShown();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feature Image
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child:
                Image.asset(data.image, height: 150)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fade(),
          ),
          const SizedBox(height: 60),
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 20),
          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textBlack.withValues(alpha: 0.6),
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final String backgroundImage;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.backgroundImage,
  });
}
