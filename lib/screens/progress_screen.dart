import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';
import 'learning_feed_screen.dart';

/// Reading Progress screen.
/// Shows progress percentage, stats, and continue reading CTA.
/// Design inspired by the Figma reading_progress_screen template.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer2<BookProvider, ReadingProgressProvider>(
          builder: (context, bookProvider, progressProvider, child) {
            final book = bookProvider.currentBook;
            final progress = progressProvider.currentProgress;

            if (book == null) {
              return const Center(child: Text('No book selected'));
            }

            return Column(
              children: [
                // App bar
                _buildAppBar(context),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // PDF Preview Card (WhatsApp style)
                        _buildPdfPreviewCard(context, bookProvider)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                            ),

                        const SizedBox(height: 32),

                        // Progress percentage
                        _buildProgressHeader(
                          progress?.progressPercentage ?? 0,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 32),

                        // Progress card
                        _buildProgressCard(context, book, progress)
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 16),

                        // AI insight
                        _buildAiInsight()
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Stats grid
                        _buildStatsGrid(
                          progress,
                        ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                        const SizedBox(height: 100), // Space for bottom CTA
                      ],
                    ),
                  ),
                ),

                // Bottom CTA
                _buildBottomCta(context)
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  /// Build PDF preview card like WhatsApp document preview
  Widget _buildPdfPreviewCard(BuildContext context, BookProvider bookProvider) {
    final pdfPath = bookProvider.uploadedPdfPath;
    final book = bookProvider.currentBook;
    final isPdf = pdfPath?.toLowerCase().endsWith('.pdf') ?? false;
    final pdfBytes = bookProvider.uploadedPdfBytes;

    // Extract filename from path
    String fileName = book?.title ?? 'Uploaded Book';
    if (pdfPath != null) {
      fileName = pdfPath.split('/').last.split('\\').last;
    }

    // Get actual file size from bytes, fallback to content length
    String sizeStr;
    if (pdfBytes != null) {
      final sizeBytes = pdfBytes.length;
      if (sizeBytes >= 1024 * 1024) {
        sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        sizeStr = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
      }
    } else {
      final contentLength = bookProvider.uploadedPdfContent?.length ?? 0;
      sizeStr = '${(contentLength / 1024).toStringAsFixed(1)} KB (text)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // PDF Icon / Thumbnail
          Container(
            width: 72,
            height: 90,
            decoration: BoxDecoration(
              color:
                  isPdf
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.accentDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isPdf
                        ? AppColors.accent.withValues(alpha: 0.35)
                        : AppColors.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // File type icon
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.description_rounded,
                  size: 36,
                  color: AppColors.accent,
                ),
                // File extension badge
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPdf ? 'PDF' : 'TXT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$sizeStr • ${bookProvider.totalChunksCount} chapters',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ready to read',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
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

  Widget _buildProgressHeader(double percentage) {
    return Column(
      children: [
        Text(
          '${percentage.toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Completed',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You\'ve completed 5 out of 8 chapters. You\'re on a roll!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    dynamic book,
    dynamic progress,
  ) {
    final currentChapter = progress?.currentChapterIndex ?? 0;
    final chapterTitle =
        book.chapters.isNotEmpty
            ? book
                .chapters[currentChapter.clamp(0, book.chapters.length - 1)]
                .title
            : 'Chapter 1';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT CHAPTER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapterTitle,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Chapter ${currentChapter + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (progress?.progressPercentage ?? 0) / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${progress?.estimatedMinutesRemaining ?? 12} mins left',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                'Page ${progress?.totalBlocksRead ?? 0} / ${progress?.totalBlocks ?? 10}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Recap',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You learned about the "Focus Flow" technique in the last session. Ready to apply it?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.warning,
            value: '${progress?.readingStreak ?? 4} Days',
            label: 'Streak',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.bookmark_added_rounded,
            iconColor: AppColors.success,
            value: '12',
            label: 'Highlights',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LearningFeedScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Continue Reading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: Text(
              'View Table of Contents',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
