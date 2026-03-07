import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../state/state.dart';
import '../widgets/learning_card.dart';
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
  double _scrollOffset = 0.0; // for parallax

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
        // Build virtual feed items: blocks + chapter transition cards
        final feedItems = _buildFeedItems(book, allBlocks);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Main PageView feed with upgraded physics
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    setState(() {
                      _scrollOffset = _pageController.page ?? 0.0;
                    });
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: feedItems.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });

                    final item = feedItems[index];
                    if (item.isTransition) return; // skip progress for transition cards

                    // Update reading progress
                    final blockIndex = item.blockIndex!;
                    final progressProvider =
                        context.read<ReadingProgressProvider>();
                    final indices = progressProvider.getLocalIndices(book, blockIndex);
                    progressProvider.updateProgress(
                      book: book,
                      chapterIndex: indices.chapterIndex,
                      blockIndex: indices.blockIndex,
                    );

                    // Trigger lazy loading for upcoming chapters
                    bookProvider.onChapterViewed(indices.chapterIndex);

                    // 80% threshold: background-load next batch if needed
                    final pct = (blockIndex + 1) / allBlocks.length;
                    if (pct >= 0.8 && bookProvider.hasMorePages) {
                      bookProvider.loadMorePages();
                    }
                  },
                  itemBuilder: (context, index) {
                    final item = feedItems[index];

                    // Chapter transition card
                    if (item.isTransition) {
                      return _buildChapterTransition(
                        context,
                        completedChapter: item.completedChapter!,
                        nextChapter: item.nextChapter,
                        book: book,
                      );
                    }

                    final block = allBlocks[item.blockIndex!];
                    final chapter = bookProvider.getChapterForBlock(block.id);

                    // Check if this block's chapter is still loading
                    final chapterIndex = book.chapters.indexWhere(
                      (c) => c.id == chapter?.id,
                    );
                    final isLoading =
                        chapterIndex != -1 &&
                        bookProvider.isLoadingChapter &&
                        bookProvider.loadingChapterIndex == chapterIndex;

                    // Parallax offset for cinematic depth
                    final pageOffset = _scrollOffset - index;

                    return Transform.translate(
                      offset: Offset(0, pageOffset * 40),
                      child: LearningCard(
                        block: block,
                        chapter: chapter,
                        bookTitle: book.title,
                        progress: (item.blockIndex! + 1) / allBlocks.length,
                        isFirst: index == 0,
                        isLast: index == feedItems.length - 1,
                        isLoading: isLoading || block.tag == 'LOADING',
                        fontSize: _fontSize,
                        isBold: _isBold,
                      ),
                    );
                  },
                ),
              ),

              // Top navigation bar (floating)
              _buildTopNavigation(context, book),

              // Bottom progress indicator
              _buildBottomProgress(context, book, allBlocks.length, feedItems),
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
            final cs = Theme.of(context).colorScheme;
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
                        color: cs.outlineVariant,
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
                      color: cs.onSurfaceVariant,
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
                      color: cs.onSurfaceVariant,
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

              // Theme Toggle Button
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return _buildNavButton(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    onTap: () {
                      context.read<ThemeProvider>().toggleTheme(!isDark);
                    },
                  );
                }
              ),
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

  Widget _buildBottomProgress(
    BuildContext context,
    Book book,
    int totalBlocks,
    List<_FeedItem> feedItems,
  ) {
    // Map current page to actual block index for progress calc
    final currentItem = _currentPage < feedItems.length ? feedItems[_currentPage] : null;
    final currentBlockIndex = currentItem?.blockIndex ?? 0;
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
                      'Chapter ${_getCurrentChapterNumber(book, feedItems)}',
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
                      _getCurrentChapterTitle(book, feedItems),
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
                              '${((currentBlockIndex + 1) / totalBlocks * 100).toInt()}%',
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
                            widthFactor: (currentBlockIndex + 1) / totalBlocks,
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

  int _getCurrentChapterNumber(Book book, List<_FeedItem> feedItems) {
    final item = _currentPage < feedItems.length ? feedItems[_currentPage] : null;
    final blockIndex = item?.blockIndex ?? 0;

    int blocksCount = 0;
    for (int i = 0; i < book.chapters.length; i++) {
      blocksCount += book.chapters[i].blocks.length;
      if (blockIndex < blocksCount) {
        return i + 1;
      }
    }
    return book.chapters.length;
  }

  String _getCurrentChapterTitle(Book book, List<_FeedItem> feedItems) {
    final item = _currentPage < feedItems.length ? feedItems[_currentPage] : null;
    final blockIndex = item?.blockIndex ?? 0;

    int blocksCount = 0;
    for (int i = 0; i < book.chapters.length; i++) {
      blocksCount += book.chapters[i].blocks.length;
      if (blockIndex < blocksCount) {
        return book.chapters[i].title;
      }
    }
    return book.chapters.last.title;
  }

  /// Build virtual feed items: interleave blocks with chapter transition cards
  List<_FeedItem> _buildFeedItems(Book book, List<LearningBlock> allBlocks) {
    final items = <_FeedItem>[];
    int globalIndex = 0;

    for (int ci = 0; ci < book.chapters.length; ci++) {
      final chapter = book.chapters[ci];
      for (int bi = 0; bi < chapter.blocks.length; bi++) {
        items.add(_FeedItem(blockIndex: globalIndex));
        globalIndex++;
      }

      // Insert chapter transition after each chapter (except the last)
      if (ci < book.chapters.length - 1) {
        items.add(_FeedItem(
          isTransition: true,
          completedChapter: chapter,
          nextChapter: book.chapters[ci + 1],
        ));
      }
    }

    return items;
  }

  /// Build a chapter transition card between chapters
  Widget _buildChapterTransition(
    BuildContext context, {
    required Chapter completedChapter,
    Chapter? nextChapter,
    required Book book,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Completion icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),

                const SizedBox(height: 28),

                // "Chapter Complete" label
                Text(
                  'CHAPTER COMPLETE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: AppColors.primary,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Completed chapter title
                Text(
                  completedChapter.title,
                  style: GoogleFonts.libreBaskerville(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Divider
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ).animate().fadeIn(delay: 400.ms).scaleX(begin: 0, duration: 400.ms),

                const SizedBox(height: 32),

                // Next chapter preview
                if (nextChapter != null) ...[
                  Text(
                    'UP NEXT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textTertiary,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 10),

                  Text(
                    'Chapter ${nextChapter.number}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 550.ms, duration: 400.ms),

                  const SizedBox(height: 6),

                  Text(
                    nextChapter.title,
                    style: GoogleFonts.libreBaskerville(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: 40),

                  // "Swipe to continue" hint
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe up to continue',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ).animate(
                    onPlay: (c) => c.repeat(reverse: true),
                  ).fadeIn(delay: 800.ms).then().fadeOut(delay: 2.seconds),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents a virtual item in the feed — either a real block or a chapter transition
class _FeedItem {
  final bool isTransition;
  final int? blockIndex;
  final Chapter? completedChapter;
  final Chapter? nextChapter;

  const _FeedItem({
    this.isTransition = false,
    this.blockIndex,
    this.completedChapter,
    this.nextChapter,
  });
}
