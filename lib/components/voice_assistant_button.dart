import 'package:flutter/material.dart';
import '../services/voice_command_service.dart';
import '../core/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceAssistantButton extends StatefulWidget {
  final bool isDarkMode;
  const VoiceAssistantButton({super.key, required this.isDarkMode});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: voiceCommandService.isListening,
      builder: (context, isListening, child) {
        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Floating Action Button
            GestureDetector(
              onTap: () {
                if (isListening) {
                  voiceCommandService.stopListening();
                } else {
                  voiceCommandService.startListening();
                }
              },
              child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isListening ? 70 : 60,
                    height: isListening ? 70 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          isListening
                              ? const LinearGradient(
                                colors: [Colors.redAccent, Colors.orangeAccent],
                              )
                              : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (isListening
                                  ? Colors.red
                                  : AppColors.accentBlue)
                              .withValues(alpha: 0.4),
                          blurRadius: isListening ? 20 : 10,
                          spreadRadius: isListening ? 5 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: isListening ? 35 : 28,
                    ),
                  )
                  .animate(target: isListening ? 1 : 0)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 500.ms,
                    curve: Curves.easeInOut,
                  )
                  .shimmer(delay: 500.ms, duration: 1500.ms)
                  .shake(hz: 2, curve: Curves.easeInOut),
            ),

            // Transcribed Text Bubble
            if (isListening)
              Positioned(
                bottom: 80,
                child: ValueListenableBuilder<String>(
                  valueListenable: voiceCommandService.transcribedText,
                  builder: (context, text, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            color: AppColors.accentBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              text.isEmpty ? 'تحدث الآن...' : text,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white
                                        : AppColors.textBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.5, end: 0);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
