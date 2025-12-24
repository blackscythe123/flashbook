import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../state/state.dart';
import 'visual_reveal_widget.dart';

/// Learning Card widget - the core content card in the feed.
/// Each card represents one learning block (swipeable card).
/// Design inspired by the Figma learning_feed template.
class LearningCard extends StatelessWidget {
  final LearningBlock block;
  final Chapter? chapter;
  final String bookTitle;
  final double progress;
  final bool isFirst;
  final bool isLast;

  const LearningCard({
    super.key,
    required this.block,
    required this.chapter,
    required this.bookTitle,
    required this.progress,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        margin: const EdgeInsets.only(top: 80, bottom: 80),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress bar at top
            _buildProgressBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tag
                    if (block.tag != null)
                      _buildTag(block.tag!).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 20),

                    // Headline
                    Text(
                      block.headline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkLight,
                        height: 1.3,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Main content
                    Text(
                      block.content,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.libreBaskerville(
                        fontSize: 18,
                        color: AppColors.inkLight.withValues(alpha: 0.9),
                        height: 1.8,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    // Quote (if available)
                    if (block.quote != null) ...[
                      const SizedBox(height: 32),
                      _buildQuote(
                        block.quote!,
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    ],

                    // Visual reveal (if image available)
                    if (block.imageUrl != null) ...[
                      const SizedBox(height: 32),
                      VisualRevealWidget(
                        imageUrl: block.imageUrl!,
                      ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                    ],

                    // Takeaway (if available)
                    if (block.takeaway != null) ...[
                      const SizedBox(height: 32),
                      _buildTakeaway(
                        block.takeaway!,
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    ],

                    const SizedBox(height: 24),

                    // Bottom divider
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.inkLight.withValues(alpha: 0.1),
                    ),

                    const SizedBox(height: 16),

                    // Actions row
                    _buildActionsRow(context),
                  ],
                ),
              ),
            ),

            // Swipe hint (only on first card)
            if (isFirst)
              _buildSwipeHint()
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn()
                  .then()
                  .fadeOut(delay: 2.seconds),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        tag.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildQuote(String quote) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 4,
          ),
        ),
      ),
      child: Text(
        quote,
        style: GoogleFonts.libreBaskerville(
          fontSize: 20,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: AppColors.inkLight,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTakeaway(String takeaway) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAKEAWAY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.inkLight.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  takeaway,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Read time
        Text(
          '${(block.estimatedReadTime / 60).ceil()} min read',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),

        // Action buttons
        Row(
          children: [
            // Bookmark button
            Consumer<BookmarkProvider>(
              builder: (context, provider, child) {
                final isBookmarked = provider.isBlockBookmarked(block.id);
                return IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color:
                        isBookmarked ? AppColors.primary : AppColors.textMuted,
                  ),
                  onPressed: () {
                    provider.toggleBookmark(
                      bookId: 'atomic_habits_001', // Would come from context
                      chapterId: chapter?.id ?? '',
                      blockId: block.id,
                    );
                  },
                );
              },
            ),

            // Share button
            IconButton(
              icon: Icon(Icons.share_rounded, color: AppColors.textMuted),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwipeHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            'Swipe up to continue',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
