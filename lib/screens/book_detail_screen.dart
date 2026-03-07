import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Book detail / preview screen before entering the reel reader.
class BookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = book['title'] as String? ?? 'Untitled';
    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
    final status = book['status'] as String? ?? '';
    final estimatedMinutes = totalPages * 2;
    final isReading = progress > 0 && progress < 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero gradient header
            _buildHeader(title)
                .animate()
                .fadeIn(duration: 500.ms),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 6),
                  Text(
                    status == 'reading' ? 'Currently reading' : 'Ready to read',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Stats row
                  _buildStatsRow(totalPages, progress, estimatedMinutes)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.05),

                  const SizedBox(height: 28),

                  // Card preview section
                  _buildCardPreview(totalPages)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 36),

                  // CTA button
                  _buildCtaButton(isReading)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Delete option
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        onDelete();
                        Navigator.pop(context, 'deleted');
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      label: Text(
                        'Delete Book',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: AppColors.primaryLight,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(int totalPages, int progress, int estimatedMinutes) {
    return Row(
      children: [
        _buildStatItem(Icons.auto_stories_rounded, '$totalPages', 'Pages'),
        const SizedBox(width: 24),
        _buildStatItem(Icons.trending_up_rounded, '$progress%', 'Progress'),
        const SizedBox(width: 24),
        _buildStatItem(Icons.schedule_rounded, '${estimatedMinutes}m', 'Est. Time'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview(int totalPages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Preview',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.layers_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Text(
                '$totalPages chapters ready',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCtaButton(bool isReading) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onResume,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isReading ? 'Continue Reading' : 'Start Reading',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
