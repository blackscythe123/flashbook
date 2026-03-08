import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';
import 'learning_feed_screen.dart';

/// Bookmarks screen with content-first cards and jump-to-card navigation.
class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Text(
                'Saved',
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<BookmarkProvider>(
                builder: (context, provider, _) {
                  final count = provider.bookmarks.length;
                  return Text(
                    '$count bookmark${count == 1 ? '' : 's'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 70.ms, duration: 300.ms),
            const SizedBox(height: 14),

            Expanded(
              child: Consumer<BookmarkProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookmarks = provider.sortedByDate;
                  if (bookmarks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return GestureDetector(
                            onTap: () => _openBookmark(context, bookmark),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentDim,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      bookmark.cardType.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bookmark.cardHeadline.isNotEmpty
                                              ? bookmark.cardHeadline
                                              : bookmark.cardTitle,
                                          style: GoogleFonts.syne(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bookmark.bookTitle.isNotEmpty
                                              ? bookmark.bookTitle
                                              : bookmark.bookId,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                          .slideY(begin: 0.03, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark cards while reading to save them here',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openBookmark(BuildContext context, Bookmark bookmark) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) => LearningFeedScreen(
              bookId: bookmark.bookId,
              initialCardIndex: bookmark.cardIndex,
            ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}
