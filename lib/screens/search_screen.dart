import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';
import '../services/services.dart';
import 'book_detail_screen.dart';

/// Search & Discovery screen — browse categories and find books.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _userBooks = [];
  bool _loadingBooks = true;

  final _categories = const [
    _Category('Self-Help', Icons.psychology_rounded, [Color(0xFF6366F1), Color(0xFF818CF8)]),
    _Category('Business', Icons.trending_up_rounded, [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
    _Category('Science', Icons.science_rounded, [Color(0xFF10B981), Color(0xFF34D399)]),
    _Category('History', Icons.history_edu_rounded, [Color(0xFFEC4899), Color(0xFFF472B6)]),
    _Category('Philosophy', Icons.auto_awesome_rounded, [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
    _Category('Technology', Icons.memory_rounded, [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
    _Category('Fiction', Icons.menu_book_rounded, [Color(0xFFF97316), Color(0xFFFB923C)]),
    _Category('Health', Icons.favorite_rounded, [Color(0xFFEF4444), Color(0xFFF87171)]),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserBooks();
  }

  Future<void> _loadUserBooks() async {
    try {
      final apiConfig = context.read<ApiConfig>();
      final authProvider = context.read<AuthProvider>();
      final client = BackendApiClient(apiConfig);
      client.setTokenGetter(() => authProvider.idToken);
      final books = await client.getUserBooks();
      if (mounted) {
        setState(() {
          _userBooks = books;
          _loadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBooks = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Find your next read',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.paperLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search books, topics...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 22),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Categories section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Browse Categories',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Category grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = _categories[index];
                    return _CategoryCard(category: cat, index: index);
                  },
                  childCount: _categories.length,
                ),
              ),
            ),

            // User books section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                child: Text(
                  _searchQuery.isNotEmpty ? 'Results' : 'Your Books',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ),

            // User books
            SliverToBoxAdapter(
              child: _loadingBooks
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildUserBooks(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBooks() {
    final filteredBooks = _searchQuery.isEmpty
        ? _userBooks
        : _userBooks.where((b) {
            final title = (b['title'] as String? ?? '').toLowerCase();
            return title.contains(_searchQuery.toLowerCase());
          }).toList();

    if (filteredBooks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No books match your search'
                : 'No books yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filteredBooks.length,
        itemBuilder: (context, index) {
          final book = filteredBooks[index];
          final title = book['title'] as String? ?? 'Untitled';
          final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
          final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
          final gradientColors = _categories[index % _categories.length].gradient;

          return _UserBookCard(
            title: title,
            totalPages: totalPages,
            progress: progress,
            index: index,
            gradient: gradientColors,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(
                    book: book,
                    onResume: () => Navigator.of(context).pop(),
                    onDelete: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  const _Category(this.name, this.icon, this.gradient);
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final int index;

  const _CategoryCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: category.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: category.gradient.first.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to category results
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(category.icon, color: Colors.white, size: 28),
                Text(
                  category.name,
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
    )
        .animate()
        .fadeIn(delay: (300 + index * 60).ms, duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }
}

class _UserBookCard extends StatelessWidget {
  final String title;
  final int totalPages;
  final int progress;
  final int index;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _UserBookCard({
    required this.title,
    required this.totalPages,
    required this.progress,
    required this.index,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover gradient
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalPages pages · $progress%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (600 + index * 80).ms, duration: 400.ms)
        .slideX(begin: 0.1);
  }
}
