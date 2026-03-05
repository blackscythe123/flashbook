import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../state/state.dart';
import '../theme/app_colors.dart';
import 'book_source_screen.dart';
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

    bookProvider.resumeFromLibrary(
      bookId: bookId,
      title: title,
      s3Key: s3Key,
      totalPages: totalPages,
      pagesExtracted: pagesExtracted,
      currentChapterIndex: chapterIndex,
      currentBlockIndex: blockIndex,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LearningFeedScreen()),
    );
  }

  Future<void> _deleteBook(String bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppColors.surfaceLight,
            title: Text('Delete Book', style: GoogleFonts.libreBaskerville(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.inkLight)),
            content: Text('This will permanently remove this book.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.paperLight, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Library',
                      style: GoogleFonts.libreBaskerville(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkLight,
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: AppColors.inkLight,
                          ),
                          onPressed: () async {
                            await context.read<AuthProvider>().signOut();
                          },
                          tooltip: 'Sign out',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _buildError()
                        : _books.isEmpty
                        ? _buildEmpty()
                        : _buildBookList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBookSource,
        backgroundColor: AppColors.inkLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'New Book',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadBooks, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 72,
            color: Colors.grey[400],
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'No books yet',
            style: GoogleFonts.libreBaskerville(
              fontSize: 22,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Upload a PDF to start learning',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildBookList() {
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          final title = book['title'] as String? ?? 'Untitled';
          final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
          final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
          final status = book['status'] as String? ?? 'unknown';
          final bookId = book['book_id'] as String? ?? '';

          return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (status == 'ready' || status == 'reading') ? () => _resumeBook(book) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Book icon
                        Container(
                          width: 52,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.inkLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: AppColors.inkLight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.libreBaskerville(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalPages pages',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress == 100
                                        ? Colors.green
                                        : AppColors.inkLight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status == 'uploading'
                                    ? 'Uploading...'
                                    : '$progress% complete',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () => _deleteBook(bookId),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: (index * 100).ms, duration: 400.ms)
              .slideX(begin: 0.05);
        },
      ),
    );
  }
}
