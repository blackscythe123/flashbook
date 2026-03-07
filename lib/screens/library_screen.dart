import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../state/state.dart';
import '../theme/app_colors.dart';
import 'book_source_screen.dart';
import 'book_detail_screen.dart';
import 'learning_feed_screen.dart';

/// Library screen — shows the user's uploaded books with progress.
/// From here the user can resume reading or upload a new book.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiConfig = context.read<ApiConfig>();
      final authProvider = context.read<AuthProvider>();
      final client = BackendApiClient(apiConfig);
      client.setTokenGetter(() => authProvider.idToken);
      final books = await client.getUserBooks();
      // Filter out incomplete/ghost books (0 pages or still uploading with no title)
      final validBooks = books.where((b) {
        final pages = (b['total_pages'] as num?)?.toInt() ?? 0;
        final status = b['status'] as String? ?? '';
        return pages > 0 || status == 'uploading';
      }).toList();
      if (mounted) {
        setState(() {
          _books = validBooks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _openBookSource() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BookSourceScreen()));
  }

  void _resumeBook(Map<String, dynamic> book) {
    // Set the book in BookProvider and navigate to learning feed
    final bookProvider = context.read<BookProvider>();
    final bookId = book['book_id'] as String? ?? '';
    final title = book['title'] as String? ?? 'Untitled';
    final s3Key = book['s3_key'] as String? ?? '';
    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
    final pagesExtracted = (book['pages_extracted'] as num?)?.toInt() ?? 0;
    final chapterIndex = (book['current_chapter_index'] as num?)?.toInt() ?? 0;
    final blockIndex = (book['current_block_index'] as num?)?.toInt() ?? 0;

    // Restore cached image URLs so the other device doesn't regenerate
    Map<String, String>? imageUrls;
    final rawImageUrls = book['image_urls'];
    if (rawImageUrls is Map) {
      imageUrls = rawImageUrls.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    bookProvider.resumeFromLibrary(
      bookId: bookId,
      title: title,
      s3Key: s3Key,
      totalPages: totalPages,
      pagesExtracted: pagesExtracted,
      currentChapterIndex: chapterIndex,
      currentBlockIndex: blockIndex,
      imageUrls: imageUrls,
    );

    // Use push (not pushReplacement) so back button returns here
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LearningFeedScreen()),
    );
  }

  void _openBookDetail(Map<String, dynamic> book) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(
          book: book,
          onResume: () => _resumeBook(book),
          onDelete: () => _deleteBook(book['book_id'] as String? ?? ''),
        ),
      ),
    );
    if (result == 'deleted') {
      _loadBooks();
    }
  }

  Future<void> _deleteBook(String bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Book', style: GoogleFonts.libreBaskerville(fontSize: 20, fontWeight: FontWeight.w700)),
            content: Text('This will permanently remove this book.', style: GoogleFonts.inter(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      final apiConfig = context.read<ApiConfig>();
      final authProvider = context.read<AuthProvider>();
      final client = BackendApiClient(apiConfig);
      client.setTokenGetter(() => authProvider.idToken);
      await client.deleteBook(bookId);
      await _loadBooks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Library',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_books.length} book${_books.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  // Upload button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openBookSource,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Upload',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
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
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildError()
                      : _books.isEmpty
                          ? _buildEmpty()
                          : _buildBookList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: AppColors.primary.withOpacity(0.05));
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load books',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadBooks,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 44,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF and I\'ll turn it into\nbite-sized learning cards',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _openBookSource,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text('Upload Your First Book'),
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find "continue reading" candidate: highest progress that isn't 100%
    Map<String, dynamic>? continueBook;
    for (final b in _books) {
      final p = (b['progress_pct'] as num?)?.toInt() ?? 0;
      if (p > 0 && p < 100) {
        if (continueBook == null ||
            p > ((continueBook['progress_pct'] as num?)?.toInt() ?? 0)) {
          continueBook = b;
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: _books.length + (continueBook != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Hero card at index 0
          if (continueBook != null && index == 0) {
            return _buildContinueReadingCard(continueBook, isDark);
          }
          final bookIndex = continueBook != null ? index - 1 : index;
          final book = _books[bookIndex];
          final title = book['title'] as String? ?? 'Untitled';
          final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
          final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
          final status = book['status'] as String? ?? 'unknown';
          final bookId = book['book_id'] as String? ?? '';
          final isReady = status == 'ready' || status == 'reading';
          final gradientColors = _bookGradients[bookIndex % _bookGradients.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isReady ? () => _openBookDetail(book) : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Book cover
                      Container(
                        width: 52,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status == 'uploading'
                                  ? 'Processing...'
                                  : '$totalPages pages · ~${totalPages * 2} min · $progress%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 4,
                                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                                valueColor: AlwaysStoppedAnimation(
                                  progress == 100
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Actions
                      Column(
                        children: [
                          if (isReady)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _deleteBook(bookId),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (bookIndex * 80).ms, duration: 400.ms)
              .slideX(begin: 0.03);
        },
      ),
    );
  }

  Widget _buildContinueReadingCard(Map<String, dynamic> book, bool isDark) {
    final title = book['title'] as String? ?? 'Untitled';
    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.surfaceBorder.withOpacity(0.5)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openBookDetail(book),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Continue Reading',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Continue where you left off',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 5,
                          backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progress%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  static const _bookGradients = [
    [Color(0xFF6366F1), Color(0xFF818CF8)],
    [Color(0xFFF97316), Color(0xFFFB923C)],
    [Color(0xFF10B981), Color(0xFF34D399)],
    [Color(0xFFEC4899), Color(0xFFF472B6)],
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  ];
}
