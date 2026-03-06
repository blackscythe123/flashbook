import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';

/// Bookmarks & Highlights screen — shows saved cards grouped by type.
class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  int _selectedFilter = 0;
  final _filters = ['All', 'Bookmarks', 'Highlights'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Saved',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<BookmarkProvider>(
                builder: (context, provider, _) => Text(
                  '${provider.totalCount} item${provider.totalCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final isSelected = _selectedFilter == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceDark : AppColors.paperLight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                          ),
                        ),
                        child: Text(
                          _filters[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: Consumer<BookmarkProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookmarks = _getFiltered(provider);
                  if (bookmarks.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      return _BookmarkCard(
                        bookmark: bookmarks[index],
                        onRemove: () {
                          provider.removeBookmark(bookmarks[index].id);
                        },
                      )
                          .animate()
                          .fadeIn(delay: (index * 60).ms, duration: 400.ms)
                          .slideY(begin: 0.03);
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

  List<dynamic> _getFiltered(BookmarkProvider provider) {
    switch (_selectedFilter) {
      case 1:
        return provider.positions;
      case 2:
        return provider.highlights;
      default:
        return provider.sortedByDate;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              size: 36,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 20),
          Text(
            'Nothing saved yet',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            'Tap the bookmark icon on any card\nto save it here',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final dynamic bookmark;
  final VoidCallback onRemove;

  const _BookmarkCard({required this.bookmark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighlight = bookmark.type.toString().contains('highlight');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isHighlight ? AppColors.accentGold : AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isHighlight ? Icons.format_quote_rounded : Icons.bookmark_rounded,
                    size: 16,
                    color: isHighlight ? AppColors.accentGold : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHighlight ? 'Highlight' : 'Bookmark',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Card ${bookmark.blockId?.substring(0, 8) ?? ''}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            // Highlight text
            if (isHighlight && bookmark.highlightText != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : AppColors.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  bookmark.highlightText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Note
            if (bookmark.note != null && bookmark.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bookmark.note,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
