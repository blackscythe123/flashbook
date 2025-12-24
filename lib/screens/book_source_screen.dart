import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';
import '../services/services.dart';
import 'processing_screen.dart';

/// Book source selection screen - bottom sheet modal.
/// Allows users to choose between public domain books or PDF upload.
/// Design inspired by the Figma book_source_selection template.
class BookSourceScreen extends StatelessWidget {
  const BookSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent backdrop
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              // Title
              Text(
                    'Start Learning',
                    style: GoogleFonts.libreBaskerville(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkLight,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Choose a source to begin your personalized learning journey.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Option: Public Library
              _buildSourceOption(
                    context,
                    icon: Icons.local_library_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                    title: 'Public Library',
                    subtitle:
                        'Explore thousands of timeless classics and public domain works.',
                    onTap: () => _selectPublicLibrary(context),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              // Option: Upload PDF
              _buildSourceOption(
                    context,
                    icon: Icons.cloud_upload_rounded,
                    iconColor: AppColors.accentGold,
                    iconBgColor: AppColors.accentGold.withValues(alpha: 0.1),
                    title: 'Upload PDF',
                    subtitle:
                        'Import your own documents and let AI generate insights.',
                    onTap: () => _selectUploadPdf(context),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),

              const SizedBox(height: 24),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 0.3,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  void _selectPublicLibrary(BuildContext context) {
    // Load available books and navigate to processing
    final bookProvider = context.read<BookProvider>();
    bookProvider.loadAvailableBooks();

    // For demo, auto-select the first book (Atomic Habits)
    final books = MockBookService.getPublicDomainBooks();
    if (books.isNotEmpty) {
      bookProvider.selectBook(books.first);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const ProcessingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _selectUploadPdf(BuildContext context) {
    // Mock PDF upload - show snackbar and proceed with demo book
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF upload simulated for demo'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    // Use demo book for hackathon
    final bookProvider = context.read<BookProvider>();
    final books = MockBookService.getPublicDomainBooks();
    if (books.isNotEmpty) {
      bookProvider.selectBook(books.first);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const ProcessingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
