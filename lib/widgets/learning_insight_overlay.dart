import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Learning Insight Overlay - AI-powered insight modal.
/// Shows when user interacts with certain elements.
/// Design inspired by the Figma learning_insight_overlay template.
class LearningInsightOverlay extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onContinue;
  final VoidCallback? onDismiss;

  const LearningInsightOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.onContinue,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: AppColors.paperLight.withValues(alpha: 0.9),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.1),
            BlendMode.overlay,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                            ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkLight,
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 32),

                        // Continue button
                        SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: onContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Text(
                                  'Continue Learning',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the learning insight overlay
Future<void> showLearningInsight({
  required BuildContext context,
  required String title,
  required String description,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder:
        (context) => LearningInsightOverlay(
          title: title,
          description: description,
          onContinue: () => Navigator.of(context).pop(),
          onDismiss: () => Navigator.of(context).pop(),
        ),
  );
}
