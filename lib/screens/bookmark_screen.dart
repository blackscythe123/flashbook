import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';
import '../services/services.dart';

/// Bookmark & Highlights screen.
/// Shows saved highlights and bookmarks with resume option.
/// Design inspired by the Figma bookmark_&_highlights template.
class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Load bookmarks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader().animate().fadeIn(duration: 400.ms),

            // Filter chips
            _buildFilterChips().animate().fadeIn(
              delay: 200.ms,
              duration: 400.ms,
            ),

            // Content
            Expanded(
              child: Consumer<BookmarkProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookmarks = _getFilteredBookmarks(provider);

                  if (bookmarks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      return _buildBookmarkCard(bookmarks[index], index)
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                            duration: 400.ms,
                          )
                          .slideX(begin: -0.1, end: 0);
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Your Collection',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.inkLight,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Filter options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Bookmarks', 'Highlights'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  List<dynamic> _getFilteredBookmarks(BookmarkProvider provider) {
    switch (_selectedFilter) {
      case 'Bookmarks':
        return provider.positions;
      case 'Highlights':
        return provider.highlights;
      default:
        return provider.sortedByDate;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved items yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookmarks and highlights will appear here',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBookmarkCard(dynamic bookmark, int index) {
    // Get mock book data for display
    final books = MockBookService.getPublicDomainBooks();
    final book = books.firstWhere(
      (b) => b.id == bookmark.bookId,
      orElse: () => books.first,
    );

    final isHighlight = bookmark.type.toString().contains('highlight');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover thumbnail
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Book info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.author,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Type indicator
                Icon(
                  isHighlight
                      ? Icons.format_quote_rounded
                      : Icons.bookmark_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),

          // Highlight text (if applicable)
          if (isHighlight && bookmark.highlightText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bookmark.highlightText,
                  style: GoogleFonts.libreBaskerville(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.inkLight,
                    height: 1.6,
                  ),
                ),
              ),
            ),

          // Action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Actions
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.share_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  label: Text(
                    'Share',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.read<BookmarkProvider>().removeBookmark(
                      bookmark.id,
                    );
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  label: Text(
                    'Remove',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

                const Spacer(),

                // Resume/Page button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isHighlight ? 'Page 24' : 'Resume',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
