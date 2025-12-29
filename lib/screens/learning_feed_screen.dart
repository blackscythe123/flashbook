import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../state/state.dart';
import '../services/services.dart';
import '../widgets/learning_card.dart';
import '../widgets/backend_url_dialog.dart';
import 'progress_screen.dart';

/// Learning Feed Screen - the CORE experience.
/// Features Instagram-style vertical scrolling with one card per page.
/// Design inspired by the Figma learning_feed_(core_experience) template.
class LearningFeedScreen extends StatefulWidget {
  const LearningFeedScreen({super.key});

  @override
  State<LearningFeedScreen> createState() => _LearningFeedScreenState();
}

class _LearningFeedScreenState extends State<LearningFeedScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        final book = bookProvider.currentBook;

        if (book == null) {
          return const Scaffold(body: Center(child: Text('No book selected')));
        }

        final allBlocks = bookProvider.allBlocks;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Stack(
            children: [
              // Main PageView feed
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: allBlocks.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  // Update reading progress
                  final progressProvider =
                      context.read<ReadingProgressProvider>();
                  final indices = progressProvider.getLocalIndices(book, index);
                  progressProvider.updateProgress(
                    book: book,
                    chapterIndex: indices.chapterIndex,
                    blockIndex: indices.blockIndex,
                  );

                  // Trigger lazy loading for upcoming chapters
                  bookProvider.onChapterViewed(indices.chapterIndex);
                },
                itemBuilder: (context, index) {
                  final block = allBlocks[index];
                  final chapter = bookProvider.getChapterForBlock(block.id);

                  return LearningCard(
                    block: block,
                    chapter: chapter,
                    bookTitle: book.title,
                    progress: (index + 1) / allBlocks.length,
                    isFirst: index == 0,
                    isLast: index == allBlocks.length - 1,
                  );
                },
              ),

              // Top navigation bar (floating)
              _buildTopNavigation(context, book),

              // Bottom progress indicator
              _buildBottomProgress(context, book, allBlocks.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopNavigation(BuildContext context, Book book) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button
              _buildNavButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),

              // Book title
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      book.title,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // Text size button (placeholder)
              _buildNavButton(
                icon: Icons.format_size_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Text size adjustment coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),

              // Mode indicator & settings
              _buildModeIndicator(context),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.inkLight),
        ),
      ),
    );
  }

  Widget _buildModeIndicator(BuildContext context) {
    return Consumer<ApiConfig>(
      builder: (context, apiConfig, child) {
        final isLive = !apiConfig.isDemoMode && apiConfig.isConnected;

        return GestureDetector(
          onTap: () async {
            // Show backend URL dialog to reconfigure
            final result = await showBackendUrlDialog(context);
            if (result == true && context.mounted) {
              // If connected to live API, show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connected to AI backend!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isLive
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isLive
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLive ? Icons.cloud_done : Icons.cloud_off,
                  size: 14,
                  color: isLive ? Colors.green[700] : Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  isLive ? 'LIVE' : 'DEMO',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isLive ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomProgress(
    BuildContext context,
    Book book,
    int totalBlocks,
  ) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProgressScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inkLight.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chapter info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chapter ${_getCurrentChapterNumber(book)}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentChapterTitle(book),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.2),
                ),

                // Progress indicator
                Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Flow',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${((_currentPage + 1) / totalBlocks * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_currentPage + 1) / totalBlocks,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  int _getCurrentChapterNumber(Book book) {
    int blocksCount = 0;
    for (int i = 0; i < book.chapters.length; i++) {
      blocksCount += book.chapters[i].blocks.length;
      if (_currentPage < blocksCount) {
        return i + 1;
      }
    }
    return book.chapters.length;
  }

  String _getCurrentChapterTitle(Book book) {
    int blocksCount = 0;
    for (int i = 0; i < book.chapters.length; i++) {
      blocksCount += book.chapters[i].blocks.length;
      if (_currentPage < blocksCount) {
        return book.chapters[i].title;
      }
    }
    return book.chapters.last.title;
  }
}
