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

/// Library screen — Netflix/Spotify-style discovery layout.
/// Continue-reading hero card + category sections with horizontal carousels.
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
    final bookProvider = context.read<BookProvider>();
    final bookId = book['book_id'] as String? ?? '';
    final title = book['title'] as String? ?? 'Untitled';
    final s3Key = book['s3_key'] as String? ?? '';
    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
    final pagesExtracted = (book['pages_extracted'] as num?)?.toInt() ?? 0;
    final chapterIndex = (book['current_chapter_index'] as num?)?.toInt() ?? 0;
    final blockIndex = (book['current_block_index'] as num?)?.toInt() ?? 0;

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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Book',
            style: GoogleFonts.libreBaskerville(fontSize: 20, fontWeight: FontWeight.w700)),
        content: Text('This will permanently remove this book.', style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: \$e')));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────

  Map<String, dynamic>? get _continueBook {
    Map<String, dynamic>? best;
    for (final b in _books) {
      final p = (b['progress_pct'] as num?)?.toInt() ?? 0;
      if (p > 0 && p < 100) {
        if (best == null || p > ((best['progress_pct'] as num?)?.toInt() ?? 0)) {
          best = b;
        }
      }
    }
    return best;
  }

  List<Map<String, dynamic>> get _recentBooks {
    final sorted = List<Map<String, dynamic>>.from(_books);
    sorted.sort((a, b) {
      final aDate = a['updated_at'] ?? a['created_at'] ?? '';
      final bDate = b['updated_at'] ?? b['created_at'] ?? '';
      return bDate.toString().compareTo(aDate.toString());
    });
    return sorted;
  }

  List<Map<String, dynamic>> get _completedBooks =>
      _books.where((b) => ((b['progress_pct'] as num?)?.toInt() ?? 0) == 100).toList();

  List<Map<String, dynamic>> get _inProgressBooks => _books.where((b) {
        final p = (b['progress_pct'] as num?)?.toInt() ?? 0;
        return p > 0 && p < 100;
      }).toList();

  // ── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? _buildLoadingState()
            : _error != null
                ? _buildError()
                : _books.isEmpty
                    ? _buildEmpty()
                    : _buildDiscoveryLayout(),
      ),
    );
  }

  Widget _buildDiscoveryLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final continueBook = _continueBook;

    return RefreshIndicator(
      onRefresh: _loadBooks,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Library',
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_books.length} book${_books.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
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
                              Text('Upload',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Continue Reading Hero ──
          if (continueBook != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildContinueReadingHero(continueBook, isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],

          // ── In Progress Section ──
          if (_inProgressBooks.length > 1)
            ..._buildCarouselSection(
              title: 'In Progress',
              icon: Icons.play_circle_outline_rounded,
              iconColor: AppColors.primary,
              books: _inProgressBooks,
              isDark: isDark,
              animationDelay: 100,
            ),

          // ── Recently Added Section ──
          if (_recentBooks.isNotEmpty)
            ..._buildCarouselSection(
              title: 'Recently Added',
              icon: Icons.schedule_rounded,
              iconColor: AppColors.accentBlue,
              books: _recentBooks,
              isDark: isDark,
              animationDelay: 200,
            ),

          // ── Completed Section ──
          if (_completedBooks.isNotEmpty)
            ..._buildCarouselSection(
              title: 'Completed',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              books: _completedBooks,
              isDark: isDark,
              animationDelay: 300,
            ),

          // ── All Books Grid ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text('All Books',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = _books[index];
                  return _buildBookListTile(book, isDark, index);
                },
                childCount: _books.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Carousel Section Builder ──────────────────────────

  List<Widget> _buildCarouselSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> books,
    required bool isDark,
    int animationDelay = 0,
  }) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${books.length}',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
        ).animate().fadeIn(delay: animationDelay.ms, duration: 400.ms),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _buildCarouselCard(books[index], isDark, index);
            },
          ),
        ).animate().fadeIn(delay: (animationDelay + 50).ms, duration: 400.ms),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  // ── Continue Reading Hero ─────────────────────────────

  Widget _buildContinueReadingHero(Map<String, dynamic> book, bool isDark) {
    final title = book['title'] as String? ?? 'Untitled';
    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
    final gradientColors = _heroGradients[title.length % _heroGradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _resumeBook(book),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text('Continue Reading',
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Colors.white, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('$progress%',
                        style: GoogleFonts.inter(
                            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: GoogleFonts.libreBaskerville(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: Colors.white, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('$totalPages pages \u00B7 ~${totalPages * 2} min',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 16),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 18, color: gradientColors[0]),
                        const SizedBox(width: 4),
                        Text('Resume',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: gradientColors[0])),
                      ],
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

  // ── Horizontal Carousel Card ──────────────────────────

  Widget _buildCarouselCard(Map<String, dynamic> book, bool isDark, int index) {
    final title = book['title'] as String? ?? 'Untitled';
    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
    final gradientColors = _bookGradients[index % _bookGradients.length];
    final isReady = (book['status'] as String? ?? '') == 'ready' ||
        (book['status'] as String? ?? '') == 'reading';

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isReady ? () => _openBookDetail(book) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                    ),
                    // Progress badge
                    if (progress > 0)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$progress%',
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Title
              Text(title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('$totalPages pages',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideX(begin: 0.08);
  }

  // ── All Books List Tile ───────────────────────────────

  Widget _buildBookListTile(Map<String, dynamic> book, bool isDark, int index) {
    final title = book['title'] as String? ?? 'Untitled';
    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
    final status = book['status'] as String? ?? 'unknown';
    final bookId = book['book_id'] as String? ?? '';
    final isReady = status == 'ready' || status == 'reading';
    final gradientColors = _bookGradients[index % _bookGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
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
                    child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                          status == 'uploading'
                              ? 'Processing...'
                              : '$totalPages pages \u00B7 ~${totalPages * 2} min \u00B7 $progress%',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 4,
                          backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                          valueColor: AlwaysStoppedAnimation(
                              progress == 100 ? AppColors.success : AppColors.primary),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _deleteBook(bookId),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideX(begin: 0.03);
  }

  // ── Loading / Error / Empty states ────────────────────

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
        ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: AppColors.primary.withValues(alpha: 0.05));
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
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text('Failed to load books',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Check your connection and try again',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                textAlign: TextAlign.center),
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
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.auto_stories_rounded,
                  size: 44, color: AppColors.primary.withValues(alpha: 0.6)),
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text('Your library is empty',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Text('Upload a PDF and I\'ll turn it into\nbite-sized learning cards',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                    textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 250.ms, duration: 400.ms),
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

  // ── Color palettes ────────────────────────────────────

  static const _bookGradients = [
    [Color(0xFF6366F1), Color(0xFF818CF8)],
    [Color(0xFFF97316), Color(0xFFFB923C)],
    [Color(0xFF10B981), Color(0xFF34D399)],
    [Color(0xFFEC4899), Color(0xFFF472B6)],
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  ];

  static const _heroGradients = [
    [Color(0xFF4F46E5), Color(0xFF6366F1)],
    [Color(0xFF9333EA), Color(0xFFA855F7)],
    [Color(0xFF0891B2), Color(0xFF06B6D4)],
    [Color(0xFFDB2777), Color(0xFFEC4899)],
  ];
}
