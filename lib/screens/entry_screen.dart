import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'book_source_screen.dart';

/// Entry screen - the first screen users see.
/// Features a calm, full-screen layout with book imagery and a CTA.
/// Design inspired by the Figma entry/_hook_screen template.
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Paper-like gradient background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.paperLight, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Book icon illustration
                      _buildBookIllustration()
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: 0.1, end: 0, duration: 800.ms),

                      const SizedBox(height: 48),

                      // Headline
                      Text(
                        'Read by',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: 48,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkLight,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 800.ms),

                      Text(
                        'Scrolling',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: 48,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: AppColors.accentWarm,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 800.ms),

                      const SizedBox(height: 24),

                      // Tagline
                      Text(
                        'Books, reimagined for the way we consume content.\nExperience knowledge in a calm, vertical flow.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: AppColors.inkLight.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
                    ],
                  ),
                ),
              ),

              // Bottom CTA section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Main CTA button
                    _buildBeginButton(context)
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 800.ms,
                          duration: 600.ms,
                        ),

                    const SizedBox(height: 16),

                    // Restore purchases link
                    TextButton(
                      onPressed: () {
                        // Mock restore purchases
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No previous purchases found'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Restore Purchases',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the book illustration widget
  Widget _buildBookIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background book (rotated)
        Transform.rotate(
          angle: 0.05,
          child: Container(
            width: 96,
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border(
                left: BorderSide(
                  color: AppColors.accentWarm.withValues(alpha: 0.5),
                  width: 4,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
          ),
        ),

        // Foreground book
        Transform.rotate(
          angle: -0.1,
          child: Container(
            width: 96,
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border(
                left: BorderSide(color: AppColors.accentWarm, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(4, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Simulated text lines
                  for (int i = 0; i < 4; i++)
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.inkLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the main CTA button
  Widget _buildBeginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const BookSourceScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentWarm,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          shadowColor: AppColors.accentWarm.withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Begin Reading',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
