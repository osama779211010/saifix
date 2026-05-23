import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isDarkMode;
  final String message;

  const LoadingOverlay({
    super.key,
    required this.isDarkMode,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkMode ? AppColors.scaffoldDark : Colors.white,
      child: Stack(
        children: [
          Positioned.fill(child: _buildBackgroundPattern(isDarkMode)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('pr_logo.png', height: 120, width: 120)
                    .animate()
                    .scale(
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                    )
                    .rotate(
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                      begin: -1.0,
                      end: 0.0,
                    )
                    .then(delay: 200.ms)
                    .shimmer(duration: 1500.ms),
                const SizedBox(height: 30),
                const SizedBox(height: 30),
                Text(
                      message,
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white : AppColors.primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 10, end: 0, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern(bool isDarkMode) {
    return Opacity(
      opacity: 0.03,
      child: Center(
        child: Wrap(
          spacing: 30,
          runSpacing: 30,
          children: List.generate(
            20,
            (index) => Icon(
              Icons.grid_view_rounded,
              size: 40,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
