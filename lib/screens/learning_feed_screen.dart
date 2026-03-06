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
import '../theme/theme_provider.dart';

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
  double _fontSize = 18.0;
  bool _isBold = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Jump to resume position after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = context.read<BookProvider>();
      final resumeIndex = bookProvider.resumeBlockIndex;
      if (resumeIndex > 0) {
        setState(() => _currentPage = resumeIndex);
        _pageController.jumpToPage(resumeIndex);
        bookProvider.clearResumePosition();
      }
    });
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

        if (book == null && bookProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (book == null) {
          return const Scaffold(body: Center(child: Text('No book selected')));
        }

        final allBlocks = bookProvider.allBlocks;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                  // 80% threshold: background-load next batch if needed
                  final pct = (index + 1) / allBlocks.length;
                  if (pct >= 0.8 && bookProvider.hasMorePages) {
                    bookProvider.loadMorePages();
                  }
                },
                itemBuilder: (context, index) {
                  final block = allBlocks[index];
                  final chapter = bookProvider.getChapterForBlock(block.id);

                  // Check if this block's chapter is still loading
                  final chapterIndex = book.chapters.indexWhere(
                    (c) => c.id == chapter?.id,
                  );
                  final isLoading =
                      chapterIndex != -1 &&
                      bookProvider.isLoadingChapter &&
                      bookProvider.loadingChapterIndex == chapterIndex;

                  return LearningCard(
                    block: block,
                    chapter: chapter,
                    bookTitle: book.title,
                    progress: (index + 1) / allBlocks.length,
                    isFirst: index == 0,
                    isLast: index == allBlocks.length - 1,
                    isLoading: isLoading || block.tag == 'LOADING',
                    fontSize: _fontSize,
                    isBold: _isBold,
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

  void _showReadingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double tempFontSize = _fontSize;
        bool tempIsBold = _isBold;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title + Reset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reading Settings',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempFontSize = 18.0;
                            tempIsBold = false;
                          });
                          setState(() {
                            _fontSize = 18.0;
                            _isBold = false;
                          });
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Font Size
                  Text(
                    'Font Size',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: tempFontSize,
                          min: 14,
                          max: 24,
                          divisions: 10,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setSheetState(() => tempFontSize = value);
                            setState(() => _fontSize = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tempFontSize.round()}px',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Font Weight
                  Text(
                    'Font Weight',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(
                          'Regular',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            color: !tempIsBold ? Colors.white : null,
                          ),
                        ),
                        selected: !tempIsBold,
                        selectedColor: AppColors.primary,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => tempIsBold = false);
                            setState(() => _isBold = false);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text(
                          'Bold',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: tempIsBold ? Colors.white : null,
                          ),
                        ),
                        selected: tempIsBold,
                        selectedColor: AppColors.primary,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => tempIsBold = true);
                            setState(() => _isBold = true);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
                      color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // Text size button
              _buildNavButton(
                icon: Icons.format_size_rounded,
                onTap: () => _showReadingSettings(context),
              ),

              const SizedBox(width: 8),

              // Settings button
              // Theme Toggle Button
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return _buildNavButton(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    onTap: () {
                      // Toggle the theme instantly
                      context.read<ThemeProvider>().toggleTheme(!isDark);
                    },
                  );
                }
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
    return Builder(
      builder: (context) {
        return Material(
          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        );
      },
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
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.inkLight.withValues(alpha: 0.95)
                  : Theme.of(context).cardColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.3),
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
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white.withValues(alpha: 0.6)
                            : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentChapterTitle(book),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),

                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white.withValues(alpha: 0.2)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),

                // Progress indicator
                Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white.withValues(alpha: 0.8)
                          : Theme.of(context).iconTheme.color?.withValues(alpha: 0.8),
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
                                color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${((_currentPage + 1) / totalBlocks * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.white.withValues(alpha: 0.2)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
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
