import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../state/state.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
  }

  List<Map<String, dynamic>> _filterValidBooks(
    List<Map<String, dynamic>> books,
  ) {
    return books.where((b) {
      final pages = (b['total_pages'] as num?)?.toInt() ?? 0;
      final status = b['status'] as String? ?? '';
      return pages > 0 || status == 'uploading';
    }).toList();
  }

  Map<String, dynamic>? _pickMostRecentBook() {
    if (_books.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(_books);
    sorted.sort((a, b) {
      final aTime = (a['updated_at'] ?? a['created_at'] ?? '').toString();
      final bTime = (b['updated_at'] ?? b['created_at'] ?? '').toString();
      return bTime.compareTo(aTime);
    });
    return sorted.first;
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final books = await context.read<BookProvider>().fetchBooks();
      final validBooks = _filterValidBooks(books);
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

  Future<void> _refreshBooks() async {
    final books = await context.read<BookProvider>().fetchBooks();
    if (!mounted) return;
    setState(() {
      _books = _filterValidBooks(books);
      _error = null;
    });
  }

  Future<void> _openBookSource() async {
    await pickAndUploadPDF(context);
    if (mounted) {
      await _loadBooks();
    }
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
      imageUrls = rawImageUrls.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LearningFeedScreen()));
  }

  void _openBookDetail(Map<String, dynamic> book) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (_) => BookDetailScreen(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Delete Book',
              style: GoogleFonts.libreBaskerville(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              'This will permanently remove this book.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final apiConfig = context.read<ApiConfig>();
      final authProvider = context.read<AuthProvider>();
      final client = BackendApiClient(apiConfig);
      client.setTokenGetter(() => authProvider.idToken);
      await client.deleteBook(bookId);
      await _loadBooks();
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            backgroundColor: cs.error,
            content: Text(
              'Failed to delete: $e',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
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
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  // Upload button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _openBookSource();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Upload',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimary,
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
              child:
                  _loading
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
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1500.ms,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            );
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
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load books',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF and I\'ll turn it into\nbite-sized learning cards',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                _openBookSource();
              },
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
    final cs = Theme.of(context).colorScheme;
    final continueBook = _pickMostRecentBook();

    return RefreshIndicator(
      onRefresh: _refreshBooks,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
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

          return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
                            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
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
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
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
                                    color: cs.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    minHeight: 4,
                                    backgroundColor:
                                        isDark
                                            ? Theme.of(context).colorScheme.onSurface.withValues(
                                              alpha: 0.06,
                                            )
                                            : Theme.of(context).colorScheme.surface.withValues(
                                              alpha: 0.06,
                                            ),
                                    valueColor: AlwaysStoppedAnimation(
                                      progress == 100
                                          ? const Color(0xFF22C55E)
                                          : Theme.of(context).colorScheme.primary,
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
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _deleteBook(bookId),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
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
    final cs = Theme.of(context).colorScheme;
    final title = book['title'] as String? ?? 'Untitled';
    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Continue Reading',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Continue where you left off',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
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
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progress%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${(book['total_pages'] as num?)?.toInt() ?? 0} pages · ~${((book['total_pages'] as num?)?.toInt() ?? 0) * 2} min · $progress%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
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
}

