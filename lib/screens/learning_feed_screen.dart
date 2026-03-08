import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/state.dart';
import '../widgets/learning_card.dart';
import 'progress_screen.dart';

/// Learning Feed Screen - the CORE experience.
/// Features Instagram-style vertical scrolling with one card per page.
/// Design inspired by the Figma learning_feed_(core_experience) template.
class LearningFeedScreen extends StatefulWidget {
  final String? bookId;
  final int? initialCardIndex;

  const LearningFeedScreen({super.key, this.bookId, this.initialCardIndex});

  @override
  State<LearningFeedScreen> createState() => _LearningFeedScreenState();
}

class _LearningFeedScreenState extends State<LearningFeedScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  double _fontSize = 18.0;
  bool _isBold = false;
  bool _isInitialBookLoading = false;
  bool _bookLoadFailed = false;
  static const int _maxBookLoadAttempts = 3;

  Future<void> _loadRequestedBookWithRetry(BookProvider bookProvider) async {
    if (widget.bookId == null) return;

    setState(() {
      _isInitialBookLoading = true;
      _bookLoadFailed = false;
    });

    for (int attempt = 1; attempt <= _maxBookLoadAttempts; attempt++) {
      await bookProvider.processBook(widget.bookId!);
      if (!mounted) return;

      final hasRequestedBook = bookProvider.currentBook?.id == widget.bookId;
      final hasCards = bookProvider.allBlocks.isNotEmpty;
      if (hasRequestedBook && hasCards) {
        setState(() {
          _isInitialBookLoading = false;
          _bookLoadFailed = false;
        });
        return;
      }

      if (attempt < _maxBookLoadAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!mounted) return;
    setState(() {
      _isInitialBookLoading = false;
      _bookLoadFailed = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialCardIndex ?? 0);

    // Ensure requested book is loaded when opening from bookmarks.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bookProvider = context.read<BookProvider>();
      if (widget.bookId != null) {
        final needsLoad =
            bookProvider.currentBook == null ||
            bookProvider.currentBook!.id != widget.bookId ||
            bookProvider.allBlocks.isEmpty;
        if (needsLoad) {
          await _loadRequestedBookWithRetry(bookProvider);
        }
      }

      if (!mounted || widget.initialCardIndex != null) {
        return;
      }

      // Jump to resume position after content is rendered for regular flow.
      final resumeIndex = bookProvider.resumeBlockIndex;
      if (resumeIndex > 0) {
        setState(() => _currentPage = resumeIndex);
        _pageController.jumpToPage(resumeIndex);
        bookProvider.clearResumePosition();
      }
    });

    // Keep initial index in local state for progress label/logic.
    if ((widget.initialCardIndex ?? 0) > 0) {
      _currentPage = widget.initialCardIndex!;
    }
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

        if (widget.bookId != null && _isInitialBookLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your book...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (widget.bookId != null && _bookLoadFailed) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load your book after $_maxBookLoadAttempts attempts.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _loadRequestedBookWithRetry(bookProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (book == null && bookProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (book != null && bookProvider.allBlocks.isEmpty && widget.bookId != null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your book...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
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
                    bookId: book.id,
                    bookTitle: book.title,
                    cardIndex: index,
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
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      builder: (context) {
        double tempFontSize = _fontSize;
        bool tempIsBold = _isBold;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
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
                        color: cs.outline.withValues(alpha: 0.5),
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
                            color: cs.primary,
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
                      color: cs.secondary,
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
                          activeColor: cs.primary,
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
                      color: cs.secondary,
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
                            color: !tempIsBold ? cs.onPrimary : null,
                          ),
                        ),
                        selected: !tempIsBold,
                        selectedColor: cs.primary,
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
                            color: tempIsBold ? cs.onPrimary : null,
                          ),
                        ),
                        selected: tempIsBold,
                        selectedColor: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
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
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline, width: 1),
                    ),
                    child: Text(
                      book.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
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
              _buildNavButton(icon: Icons.dark_mode_rounded, onTap: () {}),
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
        final cs = Theme.of(context).colorScheme;
        return Material(
          color: cs.surfaceContainerHighest,
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
                color: cs.onSurface,
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
  ) {
    final cs = Theme.of(context).colorScheme;
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
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outline, width: 1),
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
                        color: cs.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentChapterTitle(book),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),

                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: cs.outline,
                ),

                // Progress indicator
                Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 16,
                      color: cs.secondary,
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
                                color: cs.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${((_currentPage + 1) / totalBlocks * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outline.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_currentPage + 1) / totalBlocks,
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.primary,
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
