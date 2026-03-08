# Branch Change Report: testing/comprehensive-test-suite vs aws

Generated on: 2026-03-08 01:51:19 +05:30

## Comparison Baseline
- Base branch: aws (4cae7baee0b4d01b14f3ee960b99924cece83d08)
- Target branch: origin/testing/comprehensive-test-suite (851894d16e387dad873109acb40b516a8503ba19)
- Merge base: 4cae7baee0b4d01b14f3ee960b99924cece83d08
- Commits ahead: 7
- Files changed (net): 22
- Net diffstat: 22 files changed, 1846 insertions(+), 872 deletions(-)

## Commits In Target Branch (Not In aws)
```text
a1ac571f9a91f87601fce4cd136a1857dd447dad | 2026-03-07 21:14:38 +0530 | Sundaeswaran | refactor(theme): replace withOpacity with semantic Material 3 color roles
dea14d1744fd07082fb3c7dfe8c805f55d269b81 | 2026-03-07 22:37:02 +0530 | Sundaeswaran | Merge branch 'aws' of https://github.com/blackscythe123/flashbook into aws
f702e1578a5c1c59fe15d53862f9ce648ac48ef8 | 2026-03-08 00:57:46 +0530 | Sundaeswaran | feat(theme): warm peach light theme with Material 3 semantic colors
9c707400df7ac5446a3ce6e45ce24aaa619c5891 | 2026-03-08 00:57:54 +0530 | Sundaeswaran | fix(screens): replace hardcoded dark colors with semantic ColorScheme tokens
6a98f62602007e11798e3b3965b0a4bf0abf65d0 | 2026-03-08 00:58:03 +0530 | Sundaeswaran | fix(learning_card): fix overlaps and apply semantic colors
fa8798a084f1a5a6df19ad07390ccb8297f0f157 | 2026-03-08 00:58:10 +0530 | Sundaeswaran | chore: update .gitignore and dependencies
851894d16e387dad873109acb40b516a8503ba19 | 2026-03-08 01:23:28 +0530 | Sundaeswaran | feat: feed physics upgrade, card rendering system, library discovery redesign
```

## File-Level Change Summary (Net)

```text
M	.gitignore
M	lib/main.dart
M	lib/models/book.dart
M	lib/screens/book_detail_screen.dart
M	lib/screens/book_source_screen.dart
M	lib/screens/bookmark_screen.dart
M	lib/screens/learning_feed_screen.dart
M	lib/screens/library_screen.dart
M	lib/screens/notes_screen.dart
M	lib/screens/processing_screen.dart
M	lib/screens/profile_screen.dart
M	lib/screens/progress_screen.dart
M	lib/screens/search_screen.dart
M	lib/screens/settings_screen.dart
M	lib/screens/upgrade_screen.dart
M	lib/state/book_provider.dart
M	lib/theme/app_theme.dart
M	lib/theme/theme_provider.dart
A	lib/widgets/block_renderer.dart
M	lib/widgets/learning_card.dart
M	pubspec.lock
M	pubspec.yaml
```

## Diffstat By File (Net)

```text
 .gitignore                            |   8 +
 lib/main.dart                         |   7 +-
 lib/models/book.dart                  |   4 +
 lib/screens/book_detail_screen.dart   |  54 +-
 lib/screens/book_source_screen.dart   |  31 +-
 lib/screens/bookmark_screen.dart      |   8 +-
 lib/screens/learning_feed_screen.dart | 364 +++++++++++---
 lib/screens/library_screen.dart       | 903 ++++++++++++++++++++--------------
 lib/screens/notes_screen.dart         | 231 +++++----
 lib/screens/processing_screen.dart    |  12 +-
 lib/screens/profile_screen.dart       |  48 +-
 lib/screens/progress_screen.dart      |  70 +--
 lib/screens/search_screen.dart        |  26 +-
 lib/screens/settings_screen.dart      |   4 +-
 lib/screens/upgrade_screen.dart       |  33 +-
 lib/state/book_provider.dart          |  32 ++
 lib/theme/app_theme.dart              |  16 +-
 lib/theme/theme_provider.dart         |  43 +-
 lib/widgets/block_renderer.dart       | 576 ++++++++++++++++++++++
 lib/widgets/learning_card.dart        | 207 +-------
 pubspec.lock                          |  39 ++
 pubspec.yaml                          |   2 +
 22 files changed, 1846 insertions(+), 872 deletions(-)
```

## Full Unified Diff (Net Changes vs aws)

```diff
diff --git a/.gitignore b/.gitignore
index 96d0d66..2fc8f74 100644
--- a/.gitignore
+++ b/.gitignore
@@ -44,3 +44,11 @@ app.*.map.json
 /android/app/debug
 /android/app/profile
 /android/app/release
+
+# Debug screenshots and UI dumps
+*.png
+!assets/**/*.png
+ui_dump*.xml
+maestro_hierarchy.json
+maestro_out.txt
+screenshots/
diff --git a/lib/main.dart b/lib/main.dart
index 1e4175e..23c5e3d 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -28,13 +28,14 @@ void main() async {
     DeviceOrientation.portraitDown,
   ]);
 
-  // Set system UI style for immersive reading
+  // Set system UI style for immersive reading.
+  // Use transparent bars so the navigation bar adapts to the active theme.
   SystemChrome.setSystemUIOverlayStyle(
     const SystemUiOverlayStyle(
       statusBarColor: Colors.transparent,
       statusBarIconBrightness: Brightness.dark,
-      systemNavigationBarColor: Colors.white,
-      systemNavigationBarIconBrightness: Brightness.dark,
+      systemNavigationBarColor: Colors.transparent,
+      systemNavigationBarContrastEnforced: false,
     ),
   );
 
diff --git a/lib/models/book.dart b/lib/models/book.dart
index c68816c..6ea7184 100644
--- a/lib/models/book.dart
+++ b/lib/models/book.dart
@@ -122,6 +122,7 @@ class Chapter {
 class LearningBlock {
   final String id;
   final String? tag;
+  final String type; // quote, insight, scene, takeaway
   final String headline;
   final String content;
   final String? quote;
@@ -133,6 +134,7 @@ class LearningBlock {
   const LearningBlock({
     required this.id,
     this.tag,
+    this.type = 'insight',
     required this.headline,
     required this.content,
     this.quote,
@@ -146,6 +148,7 @@ class LearningBlock {
     return {
       'id': id,
       'tag': tag,
+      'type': type,
       'headline': headline,
       'content': content,
       'quote': quote,
@@ -160,6 +163,7 @@ class LearningBlock {
     return LearningBlock(
       id: json['id'] as String,
       tag: json['tag'] as String?,
+      type: json['type'] as String? ?? 'insight',
       headline: json['headline'] as String,
       content: json['content'] as String,
       quote: json['quote'] as String?,
diff --git a/lib/screens/book_detail_screen.dart b/lib/screens/book_detail_screen.dart
index 04a6850..7780a82 100644
--- a/lib/screens/book_detail_screen.dart
+++ b/lib/screens/book_detail_screen.dart
@@ -25,8 +25,9 @@ class BookDetailScreen extends StatelessWidget {
     final estimatedMinutes = totalPages * 2;
     final isReading = progress > 0 && progress < 100;
 
+    final cs = Theme.of(context).colorScheme;
+
     return Scaffold(
-      backgroundColor: AppColors.background,
       appBar: AppBar(
         backgroundColor: Colors.transparent,
         elevation: 0,
@@ -41,7 +42,7 @@ class BookDetailScreen extends StatelessWidget {
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // Hero gradient header
-            _buildHeader(title)
+            _buildHeader(context, title)
                 .animate()
                 .fadeIn(duration: 500.ms),
 
@@ -58,7 +59,7 @@ class BookDetailScreen extends StatelessWidget {
                     style: GoogleFonts.inter(
                       fontSize: 26,
                       fontWeight: FontWeight.w700,
-                      color: AppColors.textPrimary,
+                      color: cs.onSurface,
                     ),
                   ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),
 
@@ -67,14 +68,14 @@ class BookDetailScreen extends StatelessWidget {
                     status == 'reading' ? 'Currently reading' : 'Ready to read',
                     style: GoogleFonts.inter(
                       fontSize: 14,
-                      color: AppColors.textMuted,
+                      color: cs.onSurfaceVariant,
                     ),
                   ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
 
                   const SizedBox(height: 24),
 
                   // Stats row
-                  _buildStatsRow(totalPages, progress, estimatedMinutes)
+                  _buildStatsRow(context, totalPages, progress, estimatedMinutes)
                       .animate()
                       .fadeIn(delay: 200.ms, duration: 400.ms)
                       .slideY(begin: 0.05),
@@ -82,7 +83,7 @@ class BookDetailScreen extends StatelessWidget {
                   const SizedBox(height: 28),
 
                   // Card preview section
-                  _buildCardPreview(totalPages)
+                  _buildCardPreview(context, totalPages)
                       .animate()
                       .fadeIn(delay: 300.ms, duration: 400.ms),
 
@@ -125,12 +126,13 @@ class BookDetailScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildHeader(String title) {
+  Widget _buildHeader(BuildContext context, String title) {
+    final cs = Theme.of(context).colorScheme;
     return Container(
       height: 200,
-      decoration: const BoxDecoration(
-        color: AppColors.surface,
-        borderRadius: BorderRadius.only(
+      decoration: BoxDecoration(
+        color: cs.surface,
+        borderRadius: const BorderRadius.only(
           bottomLeft: Radius.circular(32),
           bottomRight: Radius.circular(32),
         ),
@@ -140,9 +142,9 @@ class BookDetailScreen extends StatelessWidget {
           width: 72,
           height: 90,
           decoration: BoxDecoration(
-            color: AppColors.surfaceLight,
+            color: cs.surfaceContainerHighest,
             borderRadius: BorderRadius.circular(14),
-            border: Border.all(color: AppColors.surfaceBorder),
+            border: Border.all(color: cs.outlineVariant),
           ),
           child: const Icon(
             Icons.menu_book_rounded,
@@ -154,24 +156,25 @@ class BookDetailScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildStatsRow(int totalPages, int progress, int estimatedMinutes) {
+  Widget _buildStatsRow(BuildContext context, int totalPages, int progress, int estimatedMinutes) {
     return Row(
       children: [
-        _buildStatItem(Icons.auto_stories_rounded, '$totalPages', 'Pages'),
+        _buildStatItem(context, Icons.auto_stories_rounded, '$totalPages', 'Pages'),
         const SizedBox(width: 24),
-        _buildStatItem(Icons.trending_up_rounded, '$progress%', 'Progress'),
+        _buildStatItem(context, Icons.trending_up_rounded, '$progress%', 'Progress'),
         const SizedBox(width: 24),
-        _buildStatItem(Icons.schedule_rounded, '${estimatedMinutes}m', 'Est. Time'),
+        _buildStatItem(context, Icons.schedule_rounded, '${estimatedMinutes}m', 'Est. Time'),
       ],
     );
   }
 
-  Widget _buildStatItem(IconData icon, String value, String label) {
+  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
+    final cs = Theme.of(context).colorScheme;
     return Expanded(
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 14),
         decoration: BoxDecoration(
-          color: AppColors.surface,
+          color: cs.surface,
           borderRadius: BorderRadius.circular(14),
         ),
         child: Column(
@@ -183,7 +186,7 @@ class BookDetailScreen extends StatelessWidget {
               style: GoogleFonts.inter(
                 fontSize: 18,
                 fontWeight: FontWeight.w700,
-                color: AppColors.textPrimary,
+                color: cs.onSurface,
               ),
             ),
             const SizedBox(height: 2),
@@ -191,7 +194,7 @@ class BookDetailScreen extends StatelessWidget {
               label,
               style: GoogleFonts.inter(
                 fontSize: 11,
-                color: AppColors.textMuted,
+                color: cs.onSurfaceVariant,
               ),
             ),
           ],
@@ -200,7 +203,8 @@ class BookDetailScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildCardPreview(int totalPages) {
+  Widget _buildCardPreview(BuildContext context, int totalPages) {
+    final cs = Theme.of(context).colorScheme;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
@@ -209,7 +213,7 @@ class BookDetailScreen extends StatelessWidget {
           style: GoogleFonts.inter(
             fontSize: 16,
             fontWeight: FontWeight.w600,
-            color: AppColors.textPrimary,
+            color: cs.onSurface,
           ),
         ),
         const SizedBox(height: 12),
@@ -217,10 +221,10 @@ class BookDetailScreen extends StatelessWidget {
           width: double.infinity,
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
-            color: AppColors.surface,
+            color: cs.surface,
             borderRadius: BorderRadius.circular(14),
             border: Border.all(
-              color: AppColors.surfaceBorder,
+              color: cs.outlineVariant,
             ),
           ),
           child: Row(
@@ -239,7 +243,7 @@ class BookDetailScreen extends StatelessWidget {
                 style: GoogleFonts.inter(
                   fontSize: 14,
                   fontWeight: FontWeight.w500,
-                  color: AppColors.textPrimary,
+                  color: cs.onSurface,
                 ),
               ),
             ],
diff --git a/lib/screens/book_source_screen.dart b/lib/screens/book_source_screen.dart
index 72d6609..57b2eb0 100644
--- a/lib/screens/book_source_screen.dart
+++ b/lib/screens/book_source_screen.dart
@@ -39,10 +39,11 @@ class BookSourceScreen extends StatelessWidget {
   }
 
   Widget _buildBottomSheet(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
     return Container(
-      decoration: const BoxDecoration(
-        color: Colors.white,
-        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
+      decoration: BoxDecoration(
+        color: cs.surface,
+        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
       ),
       child: SafeArea(
         top: false,
@@ -56,7 +57,7 @@ class BookSourceScreen extends StatelessWidget {
                 width: 48,
                 height: 5,
                 decoration: BoxDecoration(
-                  color: Colors.grey[300],
+                  color: cs.outlineVariant,
                   borderRadius: BorderRadius.circular(3),
                 ),
               ).animate().fadeIn(duration: 300.ms),
@@ -69,7 +70,7 @@ class BookSourceScreen extends StatelessWidget {
                     style: GoogleFonts.libreBaskerville(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
-                      color: AppColors.inkLight,
+                      color: cs.onSurface,
                     ),
                   )
                   .animate()
@@ -84,7 +85,7 @@ class BookSourceScreen extends StatelessWidget {
                 textAlign: TextAlign.center,
                 style: GoogleFonts.inter(
                   fontSize: 14,
-                  color: AppColors.textMuted,
+                  color: cs.onSurfaceVariant,
                   height: 1.5,
                 ),
               ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
@@ -133,7 +134,7 @@ class BookSourceScreen extends StatelessWidget {
                   style: GoogleFonts.inter(
                     fontSize: 14,
                     fontWeight: FontWeight.w500,
-                    color: AppColors.textMuted,
+                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                   ),
                 ),
               ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
@@ -158,8 +159,10 @@ class BookSourceScreen extends StatelessWidget {
     required String subtitle,
     required VoidCallback onTap,
   }) {
+    final cs = Theme.of(context).colorScheme;
+    final isDark = Theme.of(context).brightness == Brightness.dark;
     return Material(
-      color: AppColors.backgroundLight,
+      color: isDark ? AppColors.paperDark : AppColors.backgroundLight,
       borderRadius: BorderRadius.circular(16),
       child: InkWell(
         onTap: onTap,
@@ -191,7 +194,7 @@ class BookSourceScreen extends StatelessWidget {
                       style: GoogleFonts.inter(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
-                        color: AppColors.inkLight,
+                        color: cs.onSurface,
                       ),
                     ),
                     const SizedBox(height: 4),
@@ -199,7 +202,7 @@ class BookSourceScreen extends StatelessWidget {
                       subtitle,
                       style: GoogleFonts.inter(
                         fontSize: 12,
-                        color: AppColors.textMuted,
+                        color: cs.onSurfaceVariant,
                         height: 1.4,
                       ),
                     ),
@@ -208,7 +211,7 @@ class BookSourceScreen extends StatelessWidget {
               ),
 
               // Chevron
-              Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
+              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
             ],
           ),
         ),
@@ -295,8 +298,8 @@ class BookSourceScreen extends StatelessWidget {
               context: context,
               barrierDismissible: false,
               builder: (BuildContext context) {
+                final cs = Theme.of(context).colorScheme;
                 return Dialog(
-                  backgroundColor: AppColors.backgroundLight,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(16),
                   ),
@@ -312,7 +315,7 @@ class BookSourceScreen extends StatelessWidget {
                           style: GoogleFonts.inter(
                             fontSize: 16,
                             fontWeight: FontWeight.w600,
-                            color: AppColors.inkLight,
+                            color: cs.onSurface,
                           ),
                         ),
                         const SizedBox(height: 8),
@@ -321,7 +324,7 @@ class BookSourceScreen extends StatelessWidget {
                           textAlign: TextAlign.center,
                           style: GoogleFonts.inter(
                             fontSize: 12,
-                            color: AppColors.textMuted,
+                            color: cs.onSurfaceVariant,
                           ),
                         ),
                       ],
diff --git a/lib/screens/bookmark_screen.dart b/lib/screens/bookmark_screen.dart
index 55f5180..c22a0d2 100644
--- a/lib/screens/bookmark_screen.dart
+++ b/lib/screens/bookmark_screen.dart
@@ -71,12 +71,12 @@ class _BookmarkScreenState extends State<BookmarkScreen> {
                         decoration: BoxDecoration(
                           color: isSelected
                               ? AppColors.primary
-                              : (isDark ? AppColors.surfaceDark : AppColors.paperLight),
+                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(
                             color: isSelected
                                 ? AppColors.primary
-                                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
+                                : Theme.of(context).colorScheme.outlineVariant,
                           ),
                         ),
                         child: Text(
@@ -189,10 +189,10 @@ class _BookmarkCard extends StatelessWidget {
     return Container(
       margin: const EdgeInsets.only(bottom: 10),
       decoration: BoxDecoration(
-        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+        color: Theme.of(context).colorScheme.surface,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(
-          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
+          color: Theme.of(context).colorScheme.outlineVariant,
         ),
       ),
       child: Padding(
diff --git a/lib/screens/learning_feed_screen.dart b/lib/screens/learning_feed_screen.dart
index afc3ec0..cd8add4 100644
--- a/lib/screens/learning_feed_screen.dart
+++ b/lib/screens/learning_feed_screen.dart
@@ -24,6 +24,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
   int _currentPage = 0;
   double _fontSize = 18.0;
   bool _isBold = false;
+  double _scrollOffset = 0.0; // for parallax
 
   @override
   void initState() {
@@ -64,72 +65,107 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
         }
 
         final allBlocks = bookProvider.allBlocks;
+        // Build virtual feed items: blocks + chapter transition cards
+        final feedItems = _buildFeedItems(book, allBlocks);
 
         return Scaffold(
           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
           body: Stack(
             children: [
-              // Main PageView feed
-              PageView.builder(
-                controller: _pageController,
-                scrollDirection: Axis.vertical,
-                itemCount: allBlocks.length,
-                onPageChanged: (index) {
-                  setState(() {
-                    _currentPage = index;
-                  });
-
-                  // Update reading progress
-                  final progressProvider =
-                      context.read<ReadingProgressProvider>();
-                  final indices = progressProvider.getLocalIndices(book, index);
-                  progressProvider.updateProgress(
-                    book: book,
-                    chapterIndex: indices.chapterIndex,
-                    blockIndex: indices.blockIndex,
-                  );
-
-                  // Trigger lazy loading for upcoming chapters
-                  bookProvider.onChapterViewed(indices.chapterIndex);
-
-                  // 80% threshold: background-load next batch if needed
-                  final pct = (index + 1) / allBlocks.length;
-                  if (pct >= 0.8 && bookProvider.hasMorePages) {
-                    bookProvider.loadMorePages();
+              // Main PageView feed with upgraded physics
+              NotificationListener<ScrollNotification>(
+                onNotification: (notification) {
+                  if (notification is ScrollUpdateNotification) {
+                    setState(() {
+                      _scrollOffset = _pageController.page ?? 0.0;
+                    });
                   }
+                  return false;
                 },
-                itemBuilder: (context, index) {
-                  final block = allBlocks[index];
-                  final chapter = bookProvider.getChapterForBlock(block.id);
-
-                  // Check if this block's chapter is still loading
-                  final chapterIndex = book.chapters.indexWhere(
-                    (c) => c.id == chapter?.id,
-                  );
-                  final isLoading =
-                      chapterIndex != -1 &&
-                      bookProvider.isLoadingChapter &&
-                      bookProvider.loadingChapterIndex == chapterIndex;
-
-                  return LearningCard(
-                    block: block,
-                    chapter: chapter,
-                    bookTitle: book.title,
-                    progress: (index + 1) / allBlocks.length,
-                    isFirst: index == 0,
-                    isLast: index == allBlocks.length - 1,
-                    isLoading: isLoading || block.tag == 'LOADING',
-                    fontSize: _fontSize,
-                    isBold: _isBold,
-                  );
-                },
+                child: PageView.builder(
+                  controller: _pageController,
+                  scrollDirection: Axis.vertical,
+                  physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
+                  itemCount: feedItems.length,
+                  onPageChanged: (index) {
+                    setState(() {
+                      _currentPage = index;
+                    });
+
+                    final item = feedItems[index];
+                    if (item.isTransition) return; // skip progress for transition cards
+
+                    // Update reading progress
+                    final blockIndex = item.blockIndex!;
+                    final progressProvider =
+                        context.read<ReadingProgressProvider>();
+                    final indices = progressProvider.getLocalIndices(book, blockIndex);
+                    progressProvider.updateProgress(
+                      book: book,
+                      chapterIndex: indices.chapterIndex,
+                      blockIndex: indices.blockIndex,
+                    );
+
+                    // Trigger lazy loading for upcoming chapters
+                    bookProvider.onChapterViewed(indices.chapterIndex);
+
+                    // 80% threshold: background-load next batch if needed
+                    final pct = (blockIndex + 1) / allBlocks.length;
+                    if (pct >= 0.8 && bookProvider.hasMorePages) {
+                      bookProvider.loadMorePages();
+                    }
+                  },
+                  itemBuilder: (context, index) {
+                    final item = feedItems[index];
+
+                    // Chapter transition card
+                    if (item.isTransition) {
+                      return _buildChapterTransition(
+                        context,
+                        completedChapter: item.completedChapter!,
+                        nextChapter: item.nextChapter,
+                        book: book,
+                      );
+                    }
+
+                    final block = allBlocks[item.blockIndex!];
+                    final chapter = bookProvider.getChapterForBlock(block.id);
+
+                    // Check if this block's chapter is still loading
+                    final chapterIndex = book.chapters.indexWhere(
+                      (c) => c.id == chapter?.id,
+                    );
+                    final isLoading =
+                        chapterIndex != -1 &&
+                        bookProvider.isLoadingChapter &&
+                        bookProvider.loadingChapterIndex == chapterIndex;
+
+                    // Parallax offset for cinematic depth
+                    final pageOffset = _scrollOffset - index;
+
+                    return Transform.translate(
+                      offset: Offset(0, pageOffset * 40),
+                      child: LearningCard(
+                        block: block,
+                        chapter: chapter,
+                        bookTitle: book.title,
+                        progress: (item.blockIndex! + 1) / allBlocks.length,
+                        isFirst: index == 0,
+                        isLast: index == feedItems.length - 1,
+                        isLoading: isLoading || block.tag == 'LOADING',
+                        fontSize: _fontSize,
+                        isBold: _isBold,
+                      ),
+                    );
+                  },
+                ),
               ),
 
               // Top navigation bar (floating)
               _buildTopNavigation(context, book),
 
               // Bottom progress indicator
-              _buildBottomProgress(context, book, allBlocks.length),
+              _buildBottomProgress(context, book, allBlocks.length, feedItems),
             ],
           ),
         );
@@ -147,6 +183,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
 
         return StatefulBuilder(
           builder: (context, setSheetState) {
+            final cs = Theme.of(context).colorScheme;
             return Container(
               decoration: BoxDecoration(
                 color: Theme.of(context).scaffoldBackgroundColor,
@@ -165,7 +202,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                       width: 40,
                       height: 4,
                       decoration: BoxDecoration(
-                        color: AppColors.textMuted.withValues(alpha: 0.3),
+                        color: cs.outlineVariant,
                         borderRadius: BorderRadius.circular(2),
                       ),
                     ),
@@ -213,7 +250,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                     style: GoogleFonts.inter(
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
-                      color: AppColors.textMuted,
+                      color: cs.onSurfaceVariant,
                     ),
                   ),
                   const SizedBox(height: 8),
@@ -250,7 +287,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                     style: GoogleFonts.inter(
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
-                      color: AppColors.textMuted,
+                      color: cs.onSurfaceVariant,
                     ),
                   ),
                   const SizedBox(height: 12),
@@ -410,7 +447,11 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
     BuildContext context,
     Book book,
     int totalBlocks,
+    List<_FeedItem> feedItems,
   ) {
+    // Map current page to actual block index for progress calc
+    final currentItem = _currentPage < feedItems.length ? feedItems[_currentPage] : null;
+    final currentBlockIndex = currentItem?.blockIndex ?? 0;
     return Positioned(
       bottom: 24,
       left: 0,
@@ -446,7 +487,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
-                      'Chapter ${_getCurrentChapterNumber(book)}',
+                      'Chapter ${_getCurrentChapterNumber(book, feedItems)}',
                       style: GoogleFonts.inter(
                         fontSize: 9,
                         fontWeight: FontWeight.bold,
@@ -458,7 +499,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                     ),
                     const SizedBox(height: 2),
                     Text(
-                      _getCurrentChapterTitle(book),
+                      _getCurrentChapterTitle(book, feedItems),
                       style: GoogleFonts.inter(
                         fontSize: 11,
                         fontWeight: FontWeight.bold,
@@ -509,7 +550,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                             ),
                             const SizedBox(width: 16),
                             Text(
-                              '${((_currentPage + 1) / totalBlocks * 100).toInt()}%',
+                              '${((currentBlockIndex + 1) / totalBlocks * 100).toInt()}%',
                               style: GoogleFonts.inter(
                                 fontSize: 8,
                                 fontWeight: FontWeight.bold,
@@ -532,7 +573,7 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
                           ),
                           child: FractionallySizedBox(
                             alignment: Alignment.centerLeft,
-                            widthFactor: (_currentPage + 1) / totalBlocks,
+                            widthFactor: (currentBlockIndex + 1) / totalBlocks,
                             child: Container(
                               decoration: BoxDecoration(
                                 color: AppColors.primary,
@@ -553,25 +594,220 @@ class _LearningFeedScreenState extends State<LearningFeedScreen> {
     ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
   }
 
-  int _getCurrentChapterNumber(Book book) {
+  int _getCurrentChapterNumber(Book book, List<_FeedItem> feedItems) {
+    final item = _currentPage < feedItems.length ? feedItems[_currentPage] : null;
+    final blockIndex = item?.blockIndex ?? 0;
+
     int blocksCount = 0;
     for (int i = 0; i < book.chapters.length; i++) {
       blocksCount += book.chapters[i].blocks.length;
-      if (_currentPage < blocksCount) {
+      if (blockIndex < blocksCount) {
         return i + 1;
       }
     }
     return book.chapters.length;
   }
 
-  String _getCurrentChapterTitle(Book book) {
+  String _getCurrentChapterTitle(Book book, List<_FeedItem> feedItems) {
+    final item = _currentPage < feedItems.length ? feedItems[_currentPage] : null;
+    final blockIndex = item?.blockIndex ?? 0;
+
     int blocksCount = 0;
     for (int i = 0; i < book.chapters.length; i++) {
       blocksCount += book.chapters[i].blocks.length;
-      if (_currentPage < blocksCount) {
+      if (blockIndex < blocksCount) {
         return book.chapters[i].title;
       }
     }
     return book.chapters.last.title;
   }
+
+  /// Build virtual feed items: interleave blocks with chapter transition cards
+  List<_FeedItem> _buildFeedItems(Book book, List<LearningBlock> allBlocks) {
+    final items = <_FeedItem>[];
+    int globalIndex = 0;
+
+    for (int ci = 0; ci < book.chapters.length; ci++) {
+      final chapter = book.chapters[ci];
+      for (int bi = 0; bi < chapter.blocks.length; bi++) {
+        items.add(_FeedItem(blockIndex: globalIndex));
+        globalIndex++;
+      }
+
+      // Insert chapter transition after each chapter (except the last)
+      if (ci < book.chapters.length - 1) {
+        items.add(_FeedItem(
+          isTransition: true,
+          completedChapter: chapter,
+          nextChapter: book.chapters[ci + 1],
+        ));
+      }
+    }
+
+    return items;
+  }
+
+  /// Build a chapter transition card between chapters
+  Widget _buildChapterTransition(
+    BuildContext context, {
+    required Chapter completedChapter,
+    Chapter? nextChapter,
+    required Book book,
+  }) {
+    final cs = Theme.of(context).colorScheme;
+    final isDark = Theme.of(context).brightness == Brightness.dark;
+
+    return Container(
+      color: Theme.of(context).scaffoldBackgroundColor,
+      child: SafeArea(
+        child: Center(
+          child: Padding(
+            padding: const EdgeInsets.symmetric(horizontal: 32),
+            child: Column(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                // Completion icon
+                Container(
+                  width: 80,
+                  height: 80,
+                  decoration: BoxDecoration(
+                    color: AppColors.primary.withValues(alpha: 0.12),
+                    shape: BoxShape.circle,
+                  ),
+                  child: const Icon(
+                    Icons.check_circle_rounded,
+                    size: 44,
+                    color: AppColors.primary,
+                  ),
+                ).animate().scale(
+                  begin: const Offset(0.5, 0.5),
+                  end: const Offset(1, 1),
+                  duration: 600.ms,
+                  curve: Curves.elasticOut,
+                ),
+
+                const SizedBox(height: 28),
+
+                // "Chapter Complete" label
+                Text(
+                  'CHAPTER COMPLETE',
+                  style: GoogleFonts.inter(
+                    fontSize: 11,
+                    fontWeight: FontWeight.w800,
+                    letterSpacing: 2.5,
+                    color: AppColors.primary,
+                  ),
+                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
+
+                const SizedBox(height: 12),
+
+                // Completed chapter title
+                Text(
+                  completedChapter.title,
+                  style: GoogleFonts.libreBaskerville(
+                    fontSize: 22,
+                    fontWeight: FontWeight.w700,
+                    color: cs.onSurface,
+                    height: 1.3,
+                  ),
+                  textAlign: TextAlign.center,
+                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
+
+                const SizedBox(height: 32),
+
+                // Divider
+                Container(
+                  width: 40,
+                  height: 2,
+                  decoration: BoxDecoration(
+                    color: cs.outlineVariant,
+                    borderRadius: BorderRadius.circular(1),
+                  ),
+                ).animate().fadeIn(delay: 400.ms).scaleX(begin: 0, duration: 400.ms),
+
+                const SizedBox(height: 32),
+
+                // Next chapter preview
+                if (nextChapter != null) ...[
+                  Text(
+                    'UP NEXT',
+                    style: GoogleFonts.inter(
+                      fontSize: 10,
+                      fontWeight: FontWeight.w700,
+                      letterSpacing: 2,
+                      color: isDark
+                          ? AppColors.textMuted
+                          : AppColors.textTertiary,
+                    ),
+                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
+
+                  const SizedBox(height: 10),
+
+                  Text(
+                    'Chapter ${nextChapter.number}',
+                    style: GoogleFonts.inter(
+                      fontSize: 14,
+                      fontWeight: FontWeight.w600,
+                      color: cs.onSurface.withValues(alpha: 0.7),
+                    ),
+                  ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
+
+                  const SizedBox(height: 6),
+
+                  Text(
+                    nextChapter.title,
+                    style: GoogleFonts.libreBaskerville(
+                      fontSize: 18,
+                      fontWeight: FontWeight.w600,
+                      color: cs.onSurface,
+                    ),
+                    textAlign: TextAlign.center,
+                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
+
+                  const SizedBox(height: 40),
+
+                  // "Swipe to continue" hint
+                  Row(
+                    mainAxisSize: MainAxisSize.min,
+                    children: [
+                      Icon(
+                        Icons.keyboard_arrow_up_rounded,
+                        size: 20,
+                        color: AppColors.textMuted,
+                      ),
+                      const SizedBox(width: 6),
+                      Text(
+                        'Swipe up to continue',
+                        style: GoogleFonts.inter(
+                          fontSize: 13,
+                          color: AppColors.textMuted,
+                        ),
+                      ),
+                    ],
+                  ).animate(
+                    onPlay: (c) => c.repeat(reverse: true),
+                  ).fadeIn(delay: 800.ms).then().fadeOut(delay: 2.seconds),
+                ],
+              ],
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+/// Represents a virtual item in the feed ??? either a real block or a chapter transition
+class _FeedItem {
+  final bool isTransition;
+  final int? blockIndex;
+  final Chapter? completedChapter;
+  final Chapter? nextChapter;
+
+  const _FeedItem({
+    this.isTransition = false,
+    this.blockIndex,
+    this.completedChapter,
+    this.nextChapter,
+  });
 }
diff --git a/lib/screens/library_screen.dart b/lib/screens/library_screen.dart
index 26cfde2..2ddecab 100644
--- a/lib/screens/library_screen.dart
+++ b/lib/screens/library_screen.dart
@@ -9,8 +9,8 @@ import 'book_source_screen.dart';
 import 'book_detail_screen.dart';
 import 'learning_feed_screen.dart';
 
-/// Library screen ??? shows the user's uploaded books with progress.
-/// From here the user can resume reading or upload a new book.
+/// Library screen ??? Netflix/Spotify-style discovery layout.
+/// Continue-reading hero card + category sections with horizontal carousels.
 class LibraryScreen extends StatefulWidget {
   const LibraryScreen({super.key});
 
@@ -41,7 +41,6 @@ class _LibraryScreenState extends State<LibraryScreen> {
       final client = BackendApiClient(apiConfig);
       client.setTokenGetter(() => authProvider.idToken);
       final books = await client.getUserBooks();
-      // Filter out incomplete/ghost books (0 pages or still uploading with no title)
       final validBooks = books.where((b) {
         final pages = (b['total_pages'] as num?)?.toInt() ?? 0;
         final status = b['status'] as String? ?? '';
@@ -70,7 +69,6 @@ class _LibraryScreenState extends State<LibraryScreen> {
   }
 
   void _resumeBook(Map<String, dynamic> book) {
-    // Set the book in BookProvider and navigate to learning feed
     final bookProvider = context.read<BookProvider>();
     final bookId = book['book_id'] as String? ?? '';
     final title = book['title'] as String? ?? 'Untitled';
@@ -80,7 +78,6 @@ class _LibraryScreenState extends State<LibraryScreen> {
     final chapterIndex = (book['current_chapter_index'] as num?)?.toInt() ?? 0;
     final blockIndex = (book['current_block_index'] as num?)?.toInt() ?? 0;
 
-    // Restore cached image URLs so the other device doesn't regenerate
     Map<String, String>? imageUrls;
     final rawImageUrls = book['image_urls'];
     if (rawImageUrls is Map) {
@@ -98,7 +95,6 @@ class _LibraryScreenState extends State<LibraryScreen> {
       imageUrls: imageUrls,
     );
 
-    // Use push (not pushReplacement) so back button returns here
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => const LearningFeedScreen()),
     );
@@ -122,26 +118,23 @@ class _LibraryScreenState extends State<LibraryScreen> {
   Future<void> _deleteBook(String bookId) async {
     final confirmed = await showDialog<bool>(
       context: context,
-      builder:
-          (ctx) => AlertDialog(
-            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
-            backgroundColor: AppColors.surfaceLight,
-            title: Text('Delete Book', style: GoogleFonts.libreBaskerville(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.inkLight)),
-            content: Text('This will permanently remove this book.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
-            actions: [
-              TextButton(
-                onPressed: () => Navigator.pop(ctx, false),
-                child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
-              ),
-              TextButton(
-                onPressed: () => Navigator.pop(ctx, true),
-                child: Text(
-                  'Delete',
-                  style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600),
-                ),
-              ),
-            ],
+      builder: (ctx) => AlertDialog(
+        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
+        title: Text('Delete Book',
+            style: GoogleFonts.libreBaskerville(fontSize: 20, fontWeight: FontWeight.w700)),
+        content: Text('This will permanently remove this book.', style: GoogleFonts.inter(fontSize: 14)),
+        actions: [
+          TextButton(
+            onPressed: () => Navigator.pop(ctx, false),
+            child: Text('Cancel', style: GoogleFonts.inter()),
+          ),
+          TextButton(
+            onPressed: () => Navigator.pop(ctx, true),
+            child: Text('Delete',
+                style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
           ),
+        ],
+      ),
     );
     if (confirmed != true) return;
 
@@ -154,22 +147,75 @@ class _LibraryScreenState extends State<LibraryScreen> {
       await _loadBooks();
     } catch (e) {
       if (mounted) {
-        ScaffoldMessenger.of(
-          context,
-        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
+        ScaffoldMessenger.of(context)
+            .showSnackBar(SnackBar(content: Text('Failed to delete: \$e')));
       }
     }
   }
 
+  // ?????? Helpers ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+
+  Map<String, dynamic>? get _continueBook {
+    Map<String, dynamic>? best;
+    for (final b in _books) {
+      final p = (b['progress_pct'] as num?)?.toInt() ?? 0;
+      if (p > 0 && p < 100) {
+        if (best == null || p > ((best['progress_pct'] as num?)?.toInt() ?? 0)) {
+          best = b;
+        }
+      }
+    }
+    return best;
+  }
+
+  List<Map<String, dynamic>> get _recentBooks {
+    final sorted = List<Map<String, dynamic>>.from(_books);
+    sorted.sort((a, b) {
+      final aDate = a['updated_at'] ?? a['created_at'] ?? '';
+      final bDate = b['updated_at'] ?? b['created_at'] ?? '';
+      return bDate.toString().compareTo(aDate.toString());
+    });
+    return sorted;
+  }
+
+  List<Map<String, dynamic>> get _completedBooks =>
+      _books.where((b) => ((b['progress_pct'] as num?)?.toInt() ?? 0) == 100).toList();
+
+  List<Map<String, dynamic>> get _inProgressBooks => _books.where((b) {
+        final p = (b['progress_pct'] as num?)?.toInt() ?? 0;
+        return p > 0 && p < 100;
+      }).toList();
+
+  // ?????? Build ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: SafeArea(
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            // Header
-            Padding(
+        child: _loading
+            ? _buildLoadingState()
+            : _error != null
+                ? _buildError()
+                : _books.isEmpty
+                    ? _buildEmpty()
+                    : _buildDiscoveryLayout(),
+      ),
+    );
+  }
+
+  Widget _buildDiscoveryLayout() {
+    final isDark = Theme.of(context).brightness == Brightness.dark;
+    final continueBook = _continueBook;
+
+    return RefreshIndicator(
+      onRefresh: _loadBooks,
+      color: AppColors.primary,
+      child: CustomScrollView(
+        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
+        slivers: [
+          // ?????? Header ??????
+          SliverToBoxAdapter(
+            child: Padding(
               padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
@@ -179,22 +225,15 @@ class _LibraryScreenState extends State<LibraryScreen> {
                     children: [
                       Text(
                         'My Library',
-                        style: GoogleFonts.inter(
-                          fontSize: 28,
-                          fontWeight: FontWeight.w700,
-                        ),
+                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700),
                       ),
                       const SizedBox(height: 2),
                       Text(
                         '${_books.length} book${_books.length == 1 ? '' : 's'}',
-                        style: GoogleFonts.inter(
-                          fontSize: 14,
-                          color: AppColors.textMuted,
-                        ),
+                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                       ),
                     ],
                   ),
-                  // Upload button
                   Container(
                     decoration: BoxDecoration(
                       color: AppColors.primary,
@@ -212,14 +251,9 @@ class _LibraryScreenState extends State<LibraryScreen> {
                             children: [
                               const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                               const SizedBox(width: 6),
-                              Text(
-                                'Upload',
-                                style: GoogleFonts.inter(
-                                  fontSize: 14,
-                                  fontWeight: FontWeight.w600,
-                                  color: Colors.white,
-                                ),
-                              ),
+                              Text('Upload',
+                                  style: GoogleFonts.inter(
+                                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                             ],
                           ),
                         ),
@@ -229,25 +263,430 @@ class _LibraryScreenState extends State<LibraryScreen> {
                 ],
               ),
             ).animate().fadeIn(duration: 400.ms),
+          ),
 
-            const SizedBox(height: 20),
+          const SliverToBoxAdapter(child: SizedBox(height: 24)),
 
-            // Content
-            Expanded(
-              child: _loading
-                  ? _buildLoadingState()
-                  : _error != null
-                      ? _buildError()
-                      : _books.isEmpty
-                          ? _buildEmpty()
-                          : _buildBookList(),
+          // ?????? Continue Reading Hero ??????
+          if (continueBook != null) ...[
+            SliverToBoxAdapter(
+              child: Padding(
+                padding: const EdgeInsets.symmetric(horizontal: 20),
+                child: _buildContinueReadingHero(continueBook, isDark),
+              ),
             ),
+            const SliverToBoxAdapter(child: SizedBox(height: 28)),
           ],
-        ),
+
+          // ?????? In Progress Section ??????
+          if (_inProgressBooks.length > 1)
+            ..._buildCarouselSection(
+              title: 'In Progress',
+              icon: Icons.play_circle_outline_rounded,
+              iconColor: AppColors.primary,
+              books: _inProgressBooks,
+              isDark: isDark,
+              animationDelay: 100,
+            ),
+
+          // ?????? Recently Added Section ??????
+          if (_recentBooks.isNotEmpty)
+            ..._buildCarouselSection(
+              title: 'Recently Added',
+              icon: Icons.schedule_rounded,
+              iconColor: AppColors.accentBlue,
+              books: _recentBooks,
+              isDark: isDark,
+              animationDelay: 200,
+            ),
+
+          // ?????? Completed Section ??????
+          if (_completedBooks.isNotEmpty)
+            ..._buildCarouselSection(
+              title: 'Completed',
+              icon: Icons.check_circle_outline_rounded,
+              iconColor: AppColors.success,
+              books: _completedBooks,
+              isDark: isDark,
+              animationDelay: 300,
+            ),
+
+          // ?????? All Books Grid ??????
+          SliverToBoxAdapter(
+            child: Padding(
+              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
+              child: Row(
+                children: [
+                  Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textMuted),
+                  const SizedBox(width: 8),
+                  Text('All Books',
+                      style: GoogleFonts.inter(
+                          fontSize: 18, fontWeight: FontWeight.w700)),
+                ],
+              ),
+            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
+          ),
+
+          SliverPadding(
+            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
+            sliver: SliverList(
+              delegate: SliverChildBuilderDelegate(
+                (context, index) {
+                  final book = _books[index];
+                  return _buildBookListTile(book, isDark, index);
+                },
+                childCount: _books.length,
+              ),
+            ),
+          ),
+        ],
       ),
     );
   }
 
+  // ?????? Carousel Section Builder ??????????????????????????????????????????????????????????????????????????????
+
+  List<Widget> _buildCarouselSection({
+    required String title,
+    required IconData icon,
+    required Color iconColor,
+    required List<Map<String, dynamic>> books,
+    required bool isDark,
+    int animationDelay = 0,
+  }) {
+    return [
+      SliverToBoxAdapter(
+        child: Padding(
+          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
+          child: Row(
+            children: [
+              Icon(icon, size: 18, color: iconColor),
+              const SizedBox(width: 8),
+              Text(title,
+                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
+              const Spacer(),
+              Text('${books.length}',
+                  style: GoogleFonts.inter(
+                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
+            ],
+          ),
+        ).animate().fadeIn(delay: animationDelay.ms, duration: 400.ms),
+      ),
+      SliverToBoxAdapter(
+        child: SizedBox(
+          height: 190,
+          child: ListView.builder(
+            scrollDirection: Axis.horizontal,
+            physics: const BouncingScrollPhysics(),
+            padding: const EdgeInsets.symmetric(horizontal: 20),
+            itemCount: books.length,
+            itemBuilder: (context, index) {
+              return _buildCarouselCard(books[index], isDark, index);
+            },
+          ),
+        ).animate().fadeIn(delay: (animationDelay + 50).ms, duration: 400.ms),
+      ),
+      const SliverToBoxAdapter(child: SizedBox(height: 24)),
+    ];
+  }
+
+  // ?????? Continue Reading Hero ???????????????????????????????????????????????????????????????????????????????????????
+
+  Widget _buildContinueReadingHero(Map<String, dynamic> book, bool isDark) {
+    final title = book['title'] as String? ?? 'Untitled';
+    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
+    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
+    final gradientColors = _heroGradients[title.length % _heroGradients.length];
+
+    return Container(
+      decoration: BoxDecoration(
+        gradient: LinearGradient(
+          colors: gradientColors,
+          begin: Alignment.topLeft,
+          end: Alignment.bottomRight,
+        ),
+        borderRadius: BorderRadius.circular(24),
+        boxShadow: [
+          BoxShadow(
+            color: gradientColors[0].withValues(alpha: 0.3),
+            blurRadius: 20,
+            offset: const Offset(0, 8),
+          ),
+        ],
+      ),
+      child: Material(
+        color: Colors.transparent,
+        child: InkWell(
+          borderRadius: BorderRadius.circular(24),
+          onTap: () => _resumeBook(book),
+          child: Padding(
+            padding: const EdgeInsets.all(24),
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Row(
+                  children: [
+                    Container(
+                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
+                      decoration: BoxDecoration(
+                        color: Colors.white.withValues(alpha: 0.2),
+                        borderRadius: BorderRadius.circular(8),
+                      ),
+                      child: Row(
+                        mainAxisSize: MainAxisSize.min,
+                        children: [
+                          const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 14),
+                          const SizedBox(width: 6),
+                          Text('Continue Reading',
+                              style: GoogleFonts.inter(
+                                  fontSize: 11, fontWeight: FontWeight.w700,
+                                  color: Colors.white, letterSpacing: 0.5)),
+                        ],
+                      ),
+                    ),
+                    const Spacer(),
+                    Text('$progress%',
+                        style: GoogleFonts.inter(
+                            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
+                  ],
+                ),
+                const SizedBox(height: 16),
+                Text(title,
+                    style: GoogleFonts.libreBaskerville(
+                        fontSize: 22, fontWeight: FontWeight.w700,
+                        color: Colors.white, height: 1.3),
+                    maxLines: 2, overflow: TextOverflow.ellipsis),
+                const SizedBox(height: 8),
+                Text('$totalPages pages \u00B7 ~${totalPages * 2} min',
+                    style: GoogleFonts.inter(
+                        fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
+                const SizedBox(height: 16),
+                // Progress bar
+                ClipRRect(
+                  borderRadius: BorderRadius.circular(4),
+                  child: LinearProgressIndicator(
+                    value: progress / 100,
+                    minHeight: 6,
+                    backgroundColor: Colors.white.withValues(alpha: 0.2),
+                    valueColor: const AlwaysStoppedAnimation(Colors.white),
+                  ),
+                ),
+                const SizedBox(height: 16),
+                Align(
+                  alignment: Alignment.centerRight,
+                  child: Container(
+                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
+                    decoration: BoxDecoration(
+                      color: Colors.white,
+                      borderRadius: BorderRadius.circular(12),
+                    ),
+                    child: Row(
+                      mainAxisSize: MainAxisSize.min,
+                      children: [
+                        Icon(Icons.play_arrow_rounded, size: 18, color: gradientColors[0]),
+                        const SizedBox(width: 4),
+                        Text('Resume',
+                            style: GoogleFonts.inter(
+                                fontSize: 14, fontWeight: FontWeight.w700,
+                                color: gradientColors[0])),
+                      ],
+                    ),
+                  ),
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
+  }
+
+  // ?????? Horizontal Carousel Card ??????????????????????????????????????????????????????????????????????????????
+
+  Widget _buildCarouselCard(Map<String, dynamic> book, bool isDark, int index) {
+    final title = book['title'] as String? ?? 'Untitled';
+    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
+    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
+    final gradientColors = _bookGradients[index % _bookGradients.length];
+    final isReady = (book['status'] as String? ?? '') == 'ready' ||
+        (book['status'] as String? ?? '') == 'reading';
+
+    return Container(
+      width: 150,
+      margin: const EdgeInsets.only(right: 14),
+      child: Material(
+        color: Colors.transparent,
+        child: InkWell(
+          borderRadius: BorderRadius.circular(18),
+          onTap: isReady ? () => _openBookDetail(book) : null,
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              // Cover
+              Container(
+                height: 110,
+                decoration: BoxDecoration(
+                  gradient: LinearGradient(
+                    colors: gradientColors,
+                    begin: Alignment.topLeft,
+                    end: Alignment.bottomRight,
+                  ),
+                  borderRadius: BorderRadius.circular(16),
+                  boxShadow: [
+                    BoxShadow(
+                      color: gradientColors[0].withValues(alpha: 0.25),
+                      blurRadius: 12,
+                      offset: const Offset(0, 4),
+                    ),
+                  ],
+                ),
+                child: Stack(
+                  children: [
+                    const Center(
+                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
+                    ),
+                    // Progress badge
+                    if (progress > 0)
+                      Positioned(
+                        bottom: 8,
+                        right: 8,
+                        child: Container(
+                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
+                          decoration: BoxDecoration(
+                            color: Colors.black.withValues(alpha: 0.5),
+                            borderRadius: BorderRadius.circular(8),
+                          ),
+                          child: Text('$progress%',
+                              style: GoogleFonts.inter(
+                                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
+                        ),
+                      ),
+                  ],
+                ),
+              ),
+              const SizedBox(height: 10),
+              // Title
+              Text(title,
+                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
+                  maxLines: 2, overflow: TextOverflow.ellipsis),
+              const SizedBox(height: 4),
+              Text('$totalPages pages',
+                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
+            ],
+          ),
+        ),
+      ),
+    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideX(begin: 0.08);
+  }
+
+  // ?????? All Books List Tile ?????????????????????????????????????????????????????????????????????????????????????????????
+
+  Widget _buildBookListTile(Map<String, dynamic> book, bool isDark, int index) {
+    final title = book['title'] as String? ?? 'Untitled';
+    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
+    final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
+    final status = book['status'] as String? ?? 'unknown';
+    final bookId = book['book_id'] as String? ?? '';
+    final isReady = status == 'ready' || status == 'reading';
+    final gradientColors = _bookGradients[index % _bookGradients.length];
+
+    return Container(
+      margin: const EdgeInsets.only(bottom: 12),
+      decoration: BoxDecoration(
+        color: isDark ? AppColors.surfaceDark : Theme.of(context).colorScheme.surface,
+        borderRadius: BorderRadius.circular(16),
+        border: Border.all(
+          color: isDark
+              ? Colors.white.withValues(alpha: 0.06)
+              : Theme.of(context).colorScheme.outlineVariant,
+        ),
+      ),
+      child: Material(
+        color: Colors.transparent,
+        child: InkWell(
+          borderRadius: BorderRadius.circular(16),
+          onTap: isReady ? () => _openBookDetail(book) : null,
+          child: Padding(
+            padding: const EdgeInsets.all(14),
+            child: Row(
+              children: [
+                // Book cover
+                Container(
+                  width: 52,
+                  height: 68,
+                  decoration: BoxDecoration(
+                    gradient: LinearGradient(
+                      colors: gradientColors,
+                      begin: Alignment.topLeft,
+                      end: Alignment.bottomRight,
+                    ),
+                    borderRadius: BorderRadius.circular(10),
+                  ),
+                  child: const Center(
+                    child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
+                  ),
+                ),
+                const SizedBox(width: 14),
+                // Info
+                Expanded(
+                  child: Column(
+                    crossAxisAlignment: CrossAxisAlignment.start,
+                    children: [
+                      Text(title,
+                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
+                          maxLines: 2, overflow: TextOverflow.ellipsis),
+                      const SizedBox(height: 4),
+                      Text(
+                          status == 'uploading'
+                              ? 'Processing...'
+                              : '$totalPages pages \u00B7 ~${totalPages * 2} min \u00B7 $progress%',
+                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
+                      const SizedBox(height: 8),
+                      ClipRRect(
+                        borderRadius: BorderRadius.circular(4),
+                        child: LinearProgressIndicator(
+                          value: progress / 100,
+                          minHeight: 4,
+                          backgroundColor: Theme.of(context).colorScheme.outlineVariant,
+                          valueColor: AlwaysStoppedAnimation(
+                              progress == 100 ? AppColors.success : AppColors.primary),
+                        ),
+                      ),
+                    ],
+                  ),
+                ),
+                const SizedBox(width: 8),
+                // Actions
+                Column(
+                  children: [
+                    if (isReady)
+                      Container(
+                        padding: const EdgeInsets.all(8),
+                        decoration: BoxDecoration(
+                          color: AppColors.primary.withValues(alpha: 0.1),
+                          borderRadius: BorderRadius.circular(10),
+                        ),
+                        child: const Icon(Icons.play_arrow_rounded,
+                            color: AppColors.primary, size: 20),
+                      ),
+                    const SizedBox(height: 4),
+                    GestureDetector(
+                      onTap: () => _deleteBook(bookId),
+                      child: Icon(Icons.delete_outline_rounded,
+                          size: 18, color: AppColors.textMuted.withValues(alpha: 0.5)),
+                    ),
+                  ],
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideX(begin: 0.03);
+  }
+
+  // ?????? Loading / Error / Empty states ????????????????????????????????????????????????????????????
+
   Widget _buildLoadingState() {
     return ListView.builder(
       padding: const EdgeInsets.symmetric(horizontal: 24),
@@ -259,12 +698,11 @@ class _LibraryScreenState extends State<LibraryScreen> {
           decoration: BoxDecoration(
             color: Theme.of(context).brightness == Brightness.dark
                 ? AppColors.surfaceDark
-                : AppColors.paperLight,
+                : Theme.of(context).colorScheme.surfaceContainerHighest,
             borderRadius: BorderRadius.circular(16),
           ),
-        )
-            .animate(onPlay: (c) => c.repeat())
-            .shimmer(duration: 1500.ms, color: AppColors.primary.withOpacity(0.05));
+        ).animate(onPlay: (c) => c.repeat())
+            .shimmer(duration: 1500.ms, color: AppColors.primary.withValues(alpha: 0.05));
       },
     );
   }
@@ -279,22 +717,18 @@ class _LibraryScreenState extends State<LibraryScreen> {
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
-                color: AppColors.error.withOpacity(0.1),
+                color: AppColors.error.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
             ),
             const SizedBox(height: 16),
-            Text(
-              'Failed to load books',
-              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
-            ),
+            Text('Failed to load books',
+                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600)),
             const SizedBox(height: 6),
-            Text(
-              'Check your connection and try again',
-              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
-              textAlign: TextAlign.center,
-            ),
+            Text('Check your connection and try again',
+                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
+                textAlign: TextAlign.center),
             const SizedBox(height: 20),
             OutlinedButton.icon(
               onPressed: _loadBooks,
@@ -319,29 +753,29 @@ class _LibraryScreenState extends State<LibraryScreen> {
               height: 100,
               decoration: BoxDecoration(
                 gradient: LinearGradient(
-                  colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
+                  colors: [
+                    AppColors.primary.withValues(alpha: 0.1),
+                    AppColors.secondary.withValues(alpha: 0.05),
+                  ],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
                 borderRadius: BorderRadius.circular(28),
               ),
-              child: Icon(
-                Icons.auto_stories_rounded,
-                size: 44,
-                color: AppColors.primary.withOpacity(0.6),
-              ),
+              child: Icon(Icons.auto_stories_rounded,
+                  size: 44, color: AppColors.primary.withValues(alpha: 0.6)),
             ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
             const SizedBox(height: 24),
-            Text(
-              'Your library is empty',
-              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
-            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
+            Text('Your library is empty',
+                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600))
+                .animate()
+                .fadeIn(delay: 150.ms, duration: 400.ms),
             const SizedBox(height: 8),
-            Text(
-              'Upload a PDF and I\'ll turn it into\nbite-sized learning cards',
-              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.5),
-              textAlign: TextAlign.center,
-            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
+            Text('Upload a PDF and I\'ll turn it into\nbite-sized learning cards',
+                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.5),
+                    textAlign: TextAlign.center)
+                .animate()
+                .fadeIn(delay: 250.ms, duration: 400.ms),
             const SizedBox(height: 28),
             ElevatedButton.icon(
               onPressed: _openBookSource,
@@ -354,287 +788,7 @@ class _LibraryScreenState extends State<LibraryScreen> {
     );
   }
 
-  Widget _buildBookList() {
-    final isDark = Theme.of(context).brightness == Brightness.dark;
-
-    // Find "continue reading" candidate: highest progress that isn't 100%
-    Map<String, dynamic>? continueBook;
-    for (final b in _books) {
-      final p = (b['progress_pct'] as num?)?.toInt() ?? 0;
-      if (p > 0 && p < 100) {
-        if (continueBook == null ||
-            p > ((continueBook['progress_pct'] as num?)?.toInt() ?? 0)) {
-          continueBook = b;
-        }
-      }
-    }
-
-    return RefreshIndicator(
-      onRefresh: _loadBooks,
-      color: AppColors.primary,
-      child: ListView.builder(
-        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
-        itemCount: _books.length + (continueBook != null ? 1 : 0),
-        itemBuilder: (context, index) {
-          // Hero card at index 0
-          if (continueBook != null && index == 0) {
-            return _buildContinueReadingCard(continueBook, isDark);
-          }
-          final bookIndex = continueBook != null ? index - 1 : index;
-          final book = _books[bookIndex];
-          final title = book['title'] as String? ?? 'Untitled';
-          final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
-          final totalPages = (book['total_pages'] as num?)?.toInt() ?? 0;
-          final status = book['status'] as String? ?? 'unknown';
-          final bookId = book['book_id'] as String? ?? '';
-          final isReady = status == 'ready' || status == 'reading';
-          final gradientColors = _bookGradients[bookIndex % _bookGradients.length];
-
-          return Container(
-            margin: const EdgeInsets.only(bottom: 12),
-            decoration: BoxDecoration(
-              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
-              borderRadius: BorderRadius.circular(16),
-              border: Border.all(
-                color: isDark
-                    ? Colors.white.withOpacity(0.06)
-                    : Colors.black.withOpacity(0.06),
-              ),
-            ),
-            child: Material(
-              color: Colors.transparent,
-              child: InkWell(
-                borderRadius: BorderRadius.circular(16),
-                onTap: isReady ? () => _openBookDetail(book) : null,
-                child: Padding(
-                  padding: const EdgeInsets.all(14),
-                  child: Row(
-                    children: [
-                      // Book cover
-                      Container(
-                        width: 52,
-                        height: 68,
-                        decoration: BoxDecoration(
-                          gradient: LinearGradient(
-                            colors: gradientColors,
-                            begin: Alignment.topLeft,
-                            end: Alignment.bottomRight,
-                          ),
-                          borderRadius: BorderRadius.circular(10),
-                        ),
-                        child: const Center(
-                          child: Icon(
-                            Icons.menu_book_rounded,
-                            color: Colors.white,
-                            size: 24,
-                          ),
-                        ),
-                      ),
-                      const SizedBox(width: 14),
-
-                      // Info
-                      Expanded(
-                        child: Column(
-                          crossAxisAlignment: CrossAxisAlignment.start,
-                          children: [
-                            Text(
-                              title,
-                              style: GoogleFonts.inter(
-                                fontSize: 15,
-                                fontWeight: FontWeight.w600,
-                              ),
-                              maxLines: 2,
-                              overflow: TextOverflow.ellipsis,
-                            ),
-                            const SizedBox(height: 4),
-                            Text(
-                              status == 'uploading'
-                                  ? 'Processing...'
-                                  : '$totalPages pages ?? ~${totalPages * 2} min ?? $progress%',
-                              style: GoogleFonts.inter(
-                                fontSize: 12,
-                                color: AppColors.textMuted,
-                              ),
-                            ),
-                            const SizedBox(height: 8),
-                            // Progress bar
-                            ClipRRect(
-                              borderRadius: BorderRadius.circular(4),
-                              child: LinearProgressIndicator(
-                                value: progress / 100,
-                                minHeight: 4,
-                                backgroundColor: isDark
-                                    ? Colors.white.withOpacity(0.06)
-                                    : Colors.black.withOpacity(0.06),
-                                valueColor: AlwaysStoppedAnimation(
-                                  progress == 100
-                                      ? AppColors.success
-                                      : AppColors.primary,
-                                ),
-                              ),
-                            ),
-                          ],
-                        ),
-                      ),
-                      const SizedBox(width: 8),
-
-                      // Actions
-                      Column(
-                        children: [
-                          if (isReady)
-                            Container(
-                              padding: const EdgeInsets.all(8),
-                              decoration: BoxDecoration(
-                                color: AppColors.primary.withOpacity(0.1),
-                                borderRadius: BorderRadius.circular(10),
-                              ),
-                              child: const Icon(
-                                Icons.play_arrow_rounded,
-                                color: AppColors.primary,
-                                size: 20,
-                              ),
-                            ),
-                          const SizedBox(height: 4),
-                          GestureDetector(
-                            onTap: () => _deleteBook(bookId),
-                            child: Icon(
-                              Icons.delete_outline_rounded,
-                              size: 18,
-                              color: AppColors.textMuted.withOpacity(0.5),
-                            ),
-                          ),
-                        ],
-                      ),
-                    ],
-                  ),
-                ),
-              ),
-            ),
-          )
-              .animate()
-              .fadeIn(delay: (bookIndex * 80).ms, duration: 400.ms)
-              .slideX(begin: 0.03);
-        },
-      ),
-    );
-  }
-
-  Widget _buildContinueReadingCard(Map<String, dynamic> book, bool isDark) {
-    final title = book['title'] as String? ?? 'Untitled';
-    final progress = (book['progress_pct'] as num?)?.toInt() ?? 0;
-
-    return Container(
-      margin: const EdgeInsets.only(bottom: 16),
-      decoration: BoxDecoration(
-        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
-        borderRadius: BorderRadius.circular(20),
-        border: Border.all(
-          color: isDark
-              ? AppColors.surfaceBorder.withOpacity(0.5)
-              : Colors.black.withOpacity(0.06),
-        ),
-      ),
-      child: Material(
-        color: Colors.transparent,
-        child: InkWell(
-          borderRadius: BorderRadius.circular(20),
-          onTap: () => _openBookDetail(book),
-          child: Padding(
-            padding: const EdgeInsets.all(20),
-            child: Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Row(
-                  children: [
-                    Container(
-                      padding: const EdgeInsets.all(8),
-                      decoration: BoxDecoration(
-                        color: AppColors.primary.withOpacity(0.12),
-                        borderRadius: BorderRadius.circular(10),
-                      ),
-                      child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 20),
-                    ),
-                    const SizedBox(width: 10),
-                    Text(
-                      'Continue Reading',
-                      style: GoogleFonts.inter(
-                        fontSize: 13,
-                        fontWeight: FontWeight.w600,
-                        color: AppColors.textMuted,
-                      ),
-                    ),
-                  ],
-                ),
-                const SizedBox(height: 14),
-                Text(
-                  title,
-                  style: GoogleFonts.inter(
-                    fontSize: 18,
-                    fontWeight: FontWeight.w700,
-                  ),
-                  maxLines: 2,
-                  overflow: TextOverflow.ellipsis,
-                ),
-                const SizedBox(height: 4),
-                Text(
-                  'Continue where you left off',
-                  style: GoogleFonts.inter(
-                    fontSize: 13,
-                    color: AppColors.textMuted,
-                  ),
-                ),
-                const SizedBox(height: 14),
-                Row(
-                  children: [
-                    Expanded(
-                      child: ClipRRect(
-                        borderRadius: BorderRadius.circular(4),
-                        child: LinearProgressIndicator(
-                          value: progress / 100,
-                          minHeight: 5,
-                          backgroundColor: isDark
-                              ? Colors.white.withOpacity(0.06)
-                              : Colors.black.withOpacity(0.06),
-                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
-                        ),
-                      ),
-                    ),
-                    const SizedBox(width: 12),
-                    Text(
-                      '$progress%',
-                      style: GoogleFonts.inter(
-                        fontSize: 13,
-                        fontWeight: FontWeight.w600,
-                      ),
-                    ),
-                  ],
-                ),
-                const SizedBox(height: 14),
-                Align(
-                  alignment: Alignment.centerRight,
-                  child: Container(
-                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
-                    decoration: BoxDecoration(
-                      color: AppColors.primary,
-                      borderRadius: BorderRadius.circular(10),
-                    ),
-                    child: Text(
-                      'Continue',
-                      style: GoogleFonts.inter(
-                        fontSize: 13,
-                        fontWeight: FontWeight.w600,
-                        color: Colors.white,
-                      ),
-                    ),
-                  ),
-                ),
-              ],
-            ),
-          ),
-        ),
-      ),
-    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
-  }
+  // ?????? Color palettes ????????????????????????????????????????????????????????????????????????????????????????????????????????????
 
   static const _bookGradients = [
     [Color(0xFF6366F1), Color(0xFF818CF8)],
@@ -644,4 +798,11 @@ class _LibraryScreenState extends State<LibraryScreen> {
     [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
     [Color(0xFF3B82F6), Color(0xFF60A5FA)],
   ];
+
+  static const _heroGradients = [
+    [Color(0xFF4F46E5), Color(0xFF6366F1)],
+    [Color(0xFF9333EA), Color(0xFFA855F7)],
+    [Color(0xFF0891B2), Color(0xFF06B6D4)],
+    [Color(0xFFDB2777), Color(0xFFEC4899)],
+  ];
 }
diff --git a/lib/screens/notes_screen.dart b/lib/screens/notes_screen.dart
index fcecb7d..3e279b8 100644
--- a/lib/screens/notes_screen.dart
+++ b/lib/screens/notes_screen.dart
@@ -1,4 +1,6 @@
 import 'package:flutter/material.dart';
+import 'package:flutter_animate/flutter_animate.dart';
+import 'package:google_fonts/google_fonts.dart';
 import 'package:provider/provider.dart';
 import '../models/note.dart';
 import '../state/state.dart';
@@ -6,30 +8,35 @@ import '../theme/app_colors.dart';
 import '../widgets/note_input_dialog.dart';
 
 class NotesScreen extends StatefulWidget {
-  const NotesScreen({Key? key}) : super(key: key);
+  const NotesScreen({super.key});
 
   @override
   State<NotesScreen> createState() => _NotesScreenState();
 }
 
 class _NotesScreenState extends State<NotesScreen> {
-  // We removed the 'initState' block because it causes crashes.
-  // The code below handles everything automatically.
-
   @override
   Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+
     return Scaffold(
       appBar: AppBar(
-        title: const Text('My Notes'),
-        backgroundColor: Colors.white,
-        elevation: 1,
-        foregroundColor: AppColors.inkLight,
+        title: Text(
+          'My Notes',
+          style: GoogleFonts.libreBaskerville(
+            fontSize: 20,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        backgroundColor: Colors.transparent,
+        elevation: 0,
+        scrolledUnderElevation: 0,
+        surfaceTintColor: Colors.transparent,
       ),
-      backgroundColor: AppColors.backgroundLight,
       body: Consumer2<NoteProvider, BookProvider>(
         builder: (context, noteProvider, bookProvider, child) {
           final currentBook = bookProvider.currentBook;
-          
+
           if (currentBook == null) {
             return Center(
               child: Padding(
@@ -37,8 +44,11 @@ class _NotesScreenState extends State<NotesScreen> {
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
-                    // FIXED: Changed .withValues to .withOpacity
-                    Icon(Icons.note_outlined, size: 64, color: AppColors.inkLight.withOpacity(0.3)),
+                    Icon(
+                      Icons.note_outlined,
+                      size: 64,
+                      color: cs.onSurfaceVariant,
+                    ),
                     const SizedBox(height: 16),
                     Text(
                       'No book selected',
@@ -59,19 +69,34 @@ class _NotesScreenState extends State<NotesScreen> {
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
-                    // FIXED: Changed .withValues to .withOpacity
-                    Icon(Icons.note_add_outlined, size: 64, color: AppColors.accentBlue.withOpacity(0.5)),
-                    const SizedBox(height: 16),
+                    Container(
+                      padding: const EdgeInsets.all(20),
+                      decoration: BoxDecoration(
+                        color: AppColors.accentBlue.withOpacity(0.08),
+                        shape: BoxShape.circle,
+                      ),
+                      child: Icon(
+                        Icons.note_add_outlined,
+                        size: 48,
+                        color: AppColors.accentBlue.withOpacity(0.7),
+                      ),
+                    ),
+                    const SizedBox(height: 20),
                     Text(
                       'No notes yet',
-                      style: Theme.of(context).textTheme.titleMedium,
+                      style: GoogleFonts.libreBaskerville(
+                        fontSize: 20,
+                        fontWeight: FontWeight.w600,
+                        color: cs.onSurface,
+                      ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       'Add notes while reading to see them here',
-                      // FIXED: Changed .withValues to .withOpacity
-                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
-                        color: AppColors.inkLight.withOpacity(0.6),
+                      style: GoogleFonts.inter(
+                        fontSize: 14,
+                        color: cs.onSurfaceVariant,
+                        height: 1.5,
                       ),
                       textAlign: TextAlign.center,
                     ),
@@ -82,11 +107,13 @@ class _NotesScreenState extends State<NotesScreen> {
           }
 
           return ListView.builder(
-            padding: const EdgeInsets.all(12),
+            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
             itemCount: notes.length,
             itemBuilder: (context, index) {
-              final note = notes[index];
-              return _buildNoteCard(context, noteProvider, note);
+              return _buildNoteCard(context, noteProvider, notes[index])
+                  .animate()
+                  .fadeIn(delay: Duration(milliseconds: index * 60), duration: 300.ms)
+                  .slideY(begin: 0.05, end: 0);
             },
           );
         },
@@ -95,55 +122,82 @@ class _NotesScreenState extends State<NotesScreen> {
   }
 
   Widget _buildNoteCard(BuildContext context, NoteProvider noteProvider, Note note) {
-    return Card(
-      margin: const EdgeInsets.symmetric(vertical: 8),
-      elevation: 1,
-      child: Padding(
-        padding: const EdgeInsets.all(16),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            // Card title
-            Text(
-              note.cardTitle,
-              style: Theme.of(context).textTheme.titleSmall?.copyWith(
-                color: AppColors.accentBlue,
-                fontWeight: FontWeight.w600,
-              ),
-              maxLines: 2,
-              overflow: TextOverflow.ellipsis,
-            ),
-            const SizedBox(height: 12),
-
-            // Note text
-            Text(
-              note.noteText,
-              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
-                color: AppColors.inkLight,
-                height: 1.5,
+    final cs = Theme.of(context).colorScheme;
+
+    return Container(
+      margin: const EdgeInsets.only(bottom: 12),
+      padding: const EdgeInsets.all(16),
+      decoration: BoxDecoration(
+        color: cs.surface,
+        borderRadius: BorderRadius.circular(16),
+        border: Border.all(color: cs.outlineVariant),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          // Card title chip
+          Row(
+            children: [
+              Container(
+                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
+                decoration: BoxDecoration(
+                  color: AppColors.accentBlue.withOpacity(0.1),
+                  borderRadius: BorderRadius.circular(6),
+                ),
+                child: Text(
+                  note.cardTitle,
+                  style: GoogleFonts.inter(
+                    fontSize: 11,
+                    fontWeight: FontWeight.w600,
+                    color: AppColors.accentBlue,
+                  ),
+                  maxLines: 1,
+                  overflow: TextOverflow.ellipsis,
+                ),
               ),
+            ],
+          ),
+          const SizedBox(height: 10),
+
+          // Note text
+          Text(
+            note.noteText,
+            style: GoogleFonts.inter(
+              fontSize: 14,
+              color: cs.onSurface,
+              height: 1.6,
             ),
-            const SizedBox(height: 12),
-
-            // Metadata and actions
-            Row(
-              mainAxisAlignment: MainAxisAlignment.spaceBetween,
-              children: [
-                Expanded(
-                  child: Text(
-                    'Saved ${_formatDate(note.updatedAt)}',
-                    // FIXED: Changed .withValues to .withOpacity
-                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
-                      color: AppColors.inkLight.withOpacity(0.5),
+          ),
+          const SizedBox(height: 12),
+
+          // Metadata and actions
+          Row(
+            mainAxisAlignment: MainAxisAlignment.spaceBetween,
+            children: [
+              Expanded(
+                child: Row(
+                  children: [
+                    Icon(Icons.access_time_rounded, size: 12, color: cs.onSurfaceVariant),
+                    const SizedBox(width: 4),
+                    Text(
+                      _formatDate(note.updatedAt),
+                      style: GoogleFonts.inter(
+                        fontSize: 11,
+                        color: cs.onSurfaceVariant,
+                      ),
                     ),
-                  ),
+                  ],
                 ),
-                Row(
-                  children: [
-                    // Edit button
-                    IconButton(
-                      icon: const Icon(Icons.edit, size: 18),
-                      color: AppColors.accentBlue,
+              ),
+              Row(
+                children: [
+                  // Edit button
+                  SizedBox(
+                    width: 32,
+                    height: 32,
+                    child: IconButton(
+                      padding: EdgeInsets.zero,
+                      icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.accentBlue),
                       onPressed: () {
                         showDialog(
                           context: context,
@@ -162,27 +216,36 @@ class _NotesScreenState extends State<NotesScreen> {
                         );
                       },
                     ),
+                  ),
+
+                  const SizedBox(width: 4),
 
-                    // Delete button
-                    IconButton(
-                      icon: const Icon(Icons.delete, size: 18),
-                      color: Colors.red,
+                  // Delete button
+                  SizedBox(
+                    width: 32,
+                    height: 32,
+                    child: IconButton(
+                      padding: EdgeInsets.zero,
+                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: cs.error),
                       onPressed: () {
                         showDialog(
                           context: context,
                           builder: (context) => AlertDialog(
-                            title: const Text('Delete Note?'),
-                            content: const Text('This action cannot be undone.'),
+                            title: Text(
+                              'Delete Note?',
+                              style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.w600),
+                            ),
+                            content: Text(
+                              'This action cannot be undone.',
+                              style: GoogleFonts.inter(fontSize: 14),
+                            ),
                             actions: [
                               TextButton(
                                 onPressed: () => Navigator.pop(context),
                                 child: const Text('Cancel'),
                               ),
-                              ElevatedButton(
-                                style: ElevatedButton.styleFrom(
-                                  backgroundColor: Colors.red,
-                                  foregroundColor: Colors.white,
-                                ),
+                              TextButton(
+                                style: TextButton.styleFrom(foregroundColor: cs.error),
                                 onPressed: () {
                                   noteProvider.deleteNote(note.id);
                                   Navigator.pop(context);
@@ -197,12 +260,12 @@ class _NotesScreenState extends State<NotesScreen> {
                         );
                       },
                     ),
-                  ],
-                ),
-              ],
-            ),
-          ],
-        ),
+                  ),
+                ],
+              ),
+            ],
+          ),
+        ],
       ),
     );
   }
diff --git a/lib/screens/processing_screen.dart b/lib/screens/processing_screen.dart
index c0cbc25..46ecf4c 100644
--- a/lib/screens/processing_screen.dart
+++ b/lib/screens/processing_screen.dart
@@ -125,8 +125,10 @@ class _ProcessingScreenState extends State<ProcessingScreen>
 
   @override
   Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+    final isDark = Theme.of(context).brightness == Brightness.dark;
     return Scaffold(
-      backgroundColor: AppColors.paperLight,
+      backgroundColor: isDark ? AppColors.paperDark : AppColors.paperLight,
       body: SafeArea(
         child: Padding(
           padding: const EdgeInsets.all(32),
@@ -151,7 +153,7 @@ class _ProcessingScreenState extends State<ProcessingScreen>
                 style: GoogleFonts.libreBaskerville(
                   fontSize: 28,
                   fontWeight: FontWeight.bold,
-                  color: AppColors.inkLight,
+                  color: cs.onSurface,
                 ),
               ).animate().fadeIn(duration: 600.ms),
 
@@ -178,7 +180,7 @@ class _ProcessingScreenState extends State<ProcessingScreen>
                   textAlign: TextAlign.center,
                   style: GoogleFonts.inter(
                     fontSize: 16,
-                    color: AppColors.textMuted,
+                    color: cs.onSurfaceVariant,
                     height: 1.5,
                   ),
                 ),
@@ -196,7 +198,7 @@ class _ProcessingScreenState extends State<ProcessingScreen>
                 '${_currentStep + 1} of ${_processingSteps.length}',
                 style: GoogleFonts.inter(
                   fontSize: 12,
-                  color: AppColors.textMuted,
+                  color: cs.onSurfaceVariant,
                 ),
               ),
 
@@ -222,7 +224,7 @@ class _ProcessingScreenState extends State<ProcessingScreen>
                         'AI is structuring this book for optimal learning',
                         style: GoogleFonts.inter(
                           fontSize: 13,
-                          color: AppColors.inkLight.withValues(alpha: 0.8),
+                          color: cs.onSurfaceVariant,
                         ),
                       ),
                     ),
diff --git a/lib/screens/profile_screen.dart b/lib/screens/profile_screen.dart
index 3be0bc4..6374982 100644
--- a/lib/screens/profile_screen.dart
+++ b/lib/screens/profile_screen.dart
@@ -13,7 +13,7 @@ class ProfileScreen extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final isDark = Theme.of(context).brightness == Brightness.dark;
+    final cs = Theme.of(context).colorScheme;
     final auth = context.watch<AuthProvider>();
 
     return Scaffold(
@@ -105,13 +105,9 @@ class ProfileScreen extends StatelessWidget {
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
-                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+                  color: cs.surface,
                   borderRadius: BorderRadius.circular(16),
-                  border: Border.all(
-                    color: isDark
-                        ? Colors.white.withOpacity(0.06)
-                        : Colors.black.withOpacity(0.06),
-                  ),
+                  border: Border.all(color: cs.outlineVariant),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
@@ -120,17 +116,13 @@ class ProfileScreen extends StatelessWidget {
                     Container(
                       width: 1,
                       height: 36,
-                      color: isDark
-                          ? Colors.white.withOpacity(0.08)
-                          : Colors.black.withOpacity(0.06),
+                      color: cs.outlineVariant,
                     ),
                     _StatItem(value: '0', label: 'Cards Read'),
                     Container(
                       width: 1,
                       height: 36,
-                      color: isDark
-                          ? Colors.white.withOpacity(0.08)
-                          : Colors.black.withOpacity(0.06),
+                      color: cs.outlineVariant,
                     ),
                     _StatItem(value: '0h', label: 'Time'),
                   ],
@@ -153,13 +145,9 @@ class ProfileScreen extends StatelessWidget {
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
-                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+                  color: cs.surface,
                   borderRadius: BorderRadius.circular(16),
-                  border: Border.all(
-                    color: isDark
-                        ? Colors.white.withOpacity(0.06)
-                        : Colors.black.withOpacity(0.06),
-                  ),
+                  border: Border.all(color: cs.outlineVariant),
                 ),
                 child: Row(
                   children: [
@@ -208,13 +196,9 @@ class ProfileScreen extends StatelessWidget {
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
-                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+                  color: cs.surface,
                   borderRadius: BorderRadius.circular(16),
-                  border: Border.all(
-                    color: isDark
-                        ? Colors.white.withOpacity(0.06)
-                        : Colors.black.withOpacity(0.06),
-                  ),
+                  border: Border.all(color: cs.outlineVariant),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
@@ -244,9 +228,7 @@ class ProfileScreen extends StatelessWidget {
                       child: LinearProgressIndicator(
                         value: 0,
                         minHeight: 8,
-                        backgroundColor: isDark
-                            ? Colors.white.withOpacity(0.06)
-                            : Colors.black.withOpacity(0.06),
+                        backgroundColor: cs.outlineVariant,
                         valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                       ),
                     ),
@@ -340,17 +322,13 @@ class _ActionTile extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final isDark = Theme.of(context).brightness == Brightness.dark;
+    final cs = Theme.of(context).colorScheme;
 
     return Container(
       decoration: BoxDecoration(
-        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+        color: cs.surface,
         borderRadius: BorderRadius.circular(14),
-        border: Border.all(
-          color: isDark
-              ? Colors.white.withOpacity(0.06)
-              : Colors.black.withOpacity(0.06),
-        ),
+        border: Border.all(color: cs.outlineVariant),
       ),
       child: ListTile(
         onTap: onTap,
diff --git a/lib/screens/progress_screen.dart b/lib/screens/progress_screen.dart
index 60cb3f5..8eb6304 100644
--- a/lib/screens/progress_screen.dart
+++ b/lib/screens/progress_screen.dart
@@ -15,7 +15,6 @@ class ProgressScreen extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     return Scaffold(
-      backgroundColor: AppColors.backgroundLight,
       body: SafeArea(
         child: Consumer2<BookProvider, ReadingProgressProvider>(
           builder: (context, bookProvider, progressProvider, child) {
@@ -50,6 +49,7 @@ class ProgressScreen extends StatelessWidget {
 
                         // Progress percentage
                         _buildProgressHeader(
+                          context,
                           progress?.progressPercentage ?? 0,
                         ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
 
@@ -64,7 +64,7 @@ class ProgressScreen extends StatelessWidget {
                         const SizedBox(height: 16),
 
                         // AI insight
-                        _buildAiInsight()
+                        _buildAiInsight(context)
                             .animate()
                             .fadeIn(delay: 400.ms, duration: 600.ms)
                             .slideY(begin: 0.1, end: 0),
@@ -73,6 +73,7 @@ class ProgressScreen extends StatelessWidget {
 
                         // Stats grid
                         _buildStatsGrid(
+                          context,
                           progress,
                         ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
 
@@ -117,6 +118,7 @@ class ProgressScreen extends StatelessWidget {
 
   /// Build PDF preview card like WhatsApp document preview
   Widget _buildPdfPreviewCard(BuildContext context, BookProvider bookProvider) {
+    final cs = Theme.of(context).colorScheme;
     final pdfPath = bookProvider.uploadedPdfPath;
     final book = bookProvider.currentBook;
     final isPdf = pdfPath?.toLowerCase().endsWith('.pdf') ?? false;
@@ -145,7 +147,7 @@ class ProgressScreen extends StatelessWidget {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
-        color: Colors.white,
+        color: cs.surface,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(
@@ -220,7 +222,7 @@ class ProgressScreen extends StatelessWidget {
                   style: GoogleFonts.inter(
                     fontSize: 15,
                     fontWeight: FontWeight.w600,
-                    color: AppColors.inkLight,
+                    color: cs.onSurface,
                   ),
                 ),
                 const SizedBox(height: 6),
@@ -229,14 +231,14 @@ class ProgressScreen extends StatelessWidget {
                     Icon(
                       Icons.insert_drive_file_outlined,
                       size: 14,
-                      color: AppColors.textMuted,
+                      color: cs.onSurfaceVariant,
                     ),
                     const SizedBox(width: 4),
                     Text(
                       '$sizeStr ??? ${bookProvider.totalChunksCount} chapters',
                       style: GoogleFonts.inter(
                         fontSize: 12,
-                        color: AppColors.textMuted,
+                        color: cs.onSurfaceVariant,
                       ),
                     ),
                   ],
@@ -280,7 +282,8 @@ class ProgressScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildProgressHeader(double percentage) {
+  Widget _buildProgressHeader(BuildContext context, double percentage) {
+    final cs = Theme.of(context).colorScheme;
     return Column(
       children: [
         Text(
@@ -288,7 +291,7 @@ class ProgressScreen extends StatelessWidget {
           style: GoogleFonts.inter(
             fontSize: 48,
             fontWeight: FontWeight.bold,
-            color: AppColors.inkLight,
+            color: cs.onSurface,
           ),
         ),
         const SizedBox(height: 4),
@@ -297,14 +300,14 @@ class ProgressScreen extends StatelessWidget {
           style: GoogleFonts.inter(
             fontSize: 18,
             fontWeight: FontWeight.w500,
-            color: AppColors.inkLight,
+            color: cs.onSurface,
           ),
         ),
         const SizedBox(height: 8),
         Text(
           'You\'ve completed 5 out of 8 chapters. You\'re on a roll!',
           textAlign: TextAlign.center,
-          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
+          style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
         ),
       ],
     );
@@ -315,6 +318,8 @@ class ProgressScreen extends StatelessWidget {
     dynamic book,
     dynamic progress,
   ) {
+    final cs = Theme.of(context).colorScheme;
+    final isDark = Theme.of(context).brightness == Brightness.dark;
     final currentChapter = progress?.currentChapterIndex ?? 0;
     final chapterTitle =
         book.chapters.isNotEmpty
@@ -326,7 +331,7 @@ class ProgressScreen extends StatelessWidget {
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
-        color: Colors.white,
+        color: cs.surface,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(
@@ -359,7 +364,7 @@ class ProgressScreen extends StatelessWidget {
                     style: GoogleFonts.inter(
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
-                      color: AppColors.inkLight,
+                      color: cs.onSurface,
                     ),
                   ),
                 ],
@@ -367,14 +372,14 @@ class ProgressScreen extends StatelessWidget {
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
-                  color: AppColors.backgroundLight,
+                  color: isDark ? AppColors.paperDark : AppColors.backgroundLight,
                   borderRadius: BorderRadius.circular(6),
                 ),
                 child: Text(
                   'Chapter ${currentChapter + 1}',
                   style: GoogleFonts.inter(
                     fontSize: 11,
-                    color: AppColors.textMuted,
+                    color: cs.onSurfaceVariant,
                   ),
                 ),
               ),
@@ -416,14 +421,14 @@ class ProgressScreen extends StatelessWidget {
                   Icon(
                     Icons.schedule_rounded,
                     size: 14,
-                    color: AppColors.textMuted,
+                    color: cs.onSurfaceVariant,
                   ),
                   const SizedBox(width: 4),
                   Text(
                     '${progress?.estimatedMinutesRemaining ?? 12} mins left',
                     style: GoogleFonts.inter(
                       fontSize: 12,
-                      color: AppColors.textMuted,
+                      color: cs.onSurfaceVariant,
                     ),
                   ),
                 ],
@@ -432,7 +437,7 @@ class ProgressScreen extends StatelessWidget {
                 'Page ${progress?.totalBlocksRead ?? 0} / ${progress?.totalBlocks ?? 10}',
                 style: GoogleFonts.inter(
                   fontSize: 12,
-                  color: AppColors.textMuted,
+                  color: cs.onSurfaceVariant,
                 ),
               ),
             ],
@@ -442,7 +447,8 @@ class ProgressScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildAiInsight() {
+  Widget _buildAiInsight(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
@@ -461,7 +467,7 @@ class ProgressScreen extends StatelessWidget {
             width: 40,
             height: 40,
             decoration: BoxDecoration(
-              color: Colors.white,
+              color: cs.surface,
               borderRadius: BorderRadius.circular(10),
             ),
             child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
@@ -484,7 +490,7 @@ class ProgressScreen extends StatelessWidget {
                   'You learned about the "Focus Flow" technique in the last session. Ready to apply it?',
                   style: GoogleFonts.inter(
                     fontSize: 12,
-                    color: AppColors.inkLight.withValues(alpha: 0.7),
+                    color: cs.onSurfaceVariant,
                   ),
                 ),
               ],
@@ -495,11 +501,12 @@ class ProgressScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildStatsGrid(dynamic progress) {
+  Widget _buildStatsGrid(BuildContext context, dynamic progress) {
     return Row(
       children: [
         Expanded(
           child: _buildStatCard(
+            context,
             icon: Icons.local_fire_department_rounded,
             iconColor: Colors.orange,
             value: '${progress?.readingStreak ?? 4} Days',
@@ -509,6 +516,7 @@ class ProgressScreen extends StatelessWidget {
         const SizedBox(width: 16),
         Expanded(
           child: _buildStatCard(
+            context,
             icon: Icons.bookmark_added_rounded,
             iconColor: Colors.green,
             value: '12',
@@ -519,18 +527,20 @@ class ProgressScreen extends StatelessWidget {
     );
   }
 
-  Widget _buildStatCard({
+  Widget _buildStatCard(
+    BuildContext context, {
     required IconData icon,
     required Color iconColor,
     required String value,
     required String label,
   }) {
+    final cs = Theme.of(context).colorScheme;
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
-        color: Colors.white,
+        color: cs.surface,
         borderRadius: BorderRadius.circular(16),
-        border: Border.all(color: Colors.grey[200]!),
+        border: Border.all(color: cs.outlineVariant),
       ),
       child: Column(
         children: [
@@ -541,12 +551,12 @@ class ProgressScreen extends StatelessWidget {
             style: GoogleFonts.inter(
               fontSize: 18,
               fontWeight: FontWeight.bold,
-              color: AppColors.inkLight,
+              color: cs.onSurface,
             ),
           ),
           Text(
             label,
-            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
+            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
           ),
         ],
       ),
@@ -554,16 +564,16 @@ class ProgressScreen extends StatelessWidget {
   }
 
   Widget _buildBottomCta(BuildContext context) {
+    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
     return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
-        color: AppColors.backgroundLight,
         gradient: LinearGradient(
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
           colors: [
-            AppColors.backgroundLight.withValues(alpha: 0),
-            AppColors.backgroundLight,
+            scaffoldBg.withValues(alpha: 0),
+            scaffoldBg,
           ],
         ),
       ),
@@ -599,7 +609,7 @@ class ProgressScreen extends StatelessWidget {
               'View Table of Contents',
               style: GoogleFonts.inter(
                 fontSize: 14,
-                color: AppColors.textMuted,
+                color: Theme.of(context).colorScheme.onSurfaceVariant,
               ),
             ),
           ),
diff --git a/lib/screens/search_screen.dart b/lib/screens/search_screen.dart
index 7570c15..48bb3d1 100644
--- a/lib/screens/search_screen.dart
+++ b/lib/screens/search_screen.dart
@@ -66,8 +66,6 @@ class _SearchScreenState extends State<SearchScreen> {
 
   @override
   Widget build(BuildContext context) {
-    final isDark = Theme.of(context).brightness == Brightness.dark;
-
     return Scaffold(
       body: SafeArea(
         child: CustomScrollView(
@@ -99,12 +97,10 @@ class _SearchScreenState extends State<SearchScreen> {
                     // Search bar
                     Container(
                       decoration: BoxDecoration(
-                        color: isDark ? AppColors.surfaceDark : AppColors.paperLight,
+                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(
-                          color: isDark
-                              ? Colors.white.withOpacity(0.08)
-                              : Colors.black.withOpacity(0.06),
+                          color: Theme.of(context).colorScheme.outlineVariant,
                         ),
                       ),
                       child: TextField(
@@ -286,14 +282,12 @@ class _CategoryCard extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final isDark = Theme.of(context).brightness == Brightness.dark;
+    final cs = Theme.of(context).colorScheme;
     return Container(
       decoration: BoxDecoration(
-        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+        color: cs.surface,
         borderRadius: BorderRadius.circular(16),
-        border: Border.all(
-          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
-        ),
+        border: Border.all(color: cs.outlineVariant),
       ),
       child: Material(
         color: Colors.transparent,
@@ -347,7 +341,7 @@ class _UserBookCard extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final isDark = Theme.of(context).brightness == Brightness.dark;
+    final cs = Theme.of(context).colorScheme;
 
     return GestureDetector(
       onTap: onTap,
@@ -355,13 +349,9 @@ class _UserBookCard extends StatelessWidget {
         width: 140,
         margin: const EdgeInsets.only(right: 12),
         decoration: BoxDecoration(
-          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+          color: cs.surface,
           borderRadius: BorderRadius.circular(16),
-          border: Border.all(
-            color: isDark
-                ? Colors.white.withOpacity(0.06)
-                : Colors.black.withOpacity(0.06),
-          ),
+          border: Border.all(color: cs.outlineVariant),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
diff --git a/lib/screens/settings_screen.dart b/lib/screens/settings_screen.dart
index 941af3e..ba654e9 100644
--- a/lib/screens/settings_screen.dart
+++ b/lib/screens/settings_screen.dart
@@ -173,10 +173,10 @@ class _SettingsTile extends StatelessWidget {
 
     return Container(
       decoration: BoxDecoration(
-        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
+        color: Theme.of(context).colorScheme.surface,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(
-          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
+          color: Theme.of(context).colorScheme.outlineVariant,
         ),
       ),
       child: ListTile(
diff --git a/lib/screens/upgrade_screen.dart b/lib/screens/upgrade_screen.dart
index 13f9813..fc50231 100644
--- a/lib/screens/upgrade_screen.dart
+++ b/lib/screens/upgrade_screen.dart
@@ -11,8 +11,10 @@ class UpgradeScreen extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+    final isDark = Theme.of(context).brightness == Brightness.dark;
     return Scaffold(
-      backgroundColor: AppColors.paperLight,
+      backgroundColor: isDark ? AppColors.paperDark : AppColors.paperLight,
       body: SafeArea(
         child: Column(
           children: [
@@ -23,7 +25,7 @@ class UpgradeScreen extends StatelessWidget {
                 padding: const EdgeInsets.all(16),
                 child: IconButton(
                   icon: const Icon(Icons.close_rounded),
-                  color: AppColors.textMuted,
+                  color: cs.onSurfaceVariant,
                   onPressed: () => Navigator.of(context).pop(),
                 ),
               ),
@@ -71,7 +73,7 @@ class UpgradeScreen extends StatelessWidget {
                       style: GoogleFonts.libreBaskerville(
                         fontSize: 32,
                         fontWeight: FontWeight.w400,
-                        color: AppColors.inkLight,
+                        color: cs.onSurface,
                         height: 1.2,
                       ),
                     ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
@@ -84,7 +86,7 @@ class UpgradeScreen extends StatelessWidget {
                       textAlign: TextAlign.center,
                       style: GoogleFonts.inter(
                         fontSize: 15,
-                        color: AppColors.textMuted,
+                        color: cs.onSurfaceVariant,
                         height: 1.5,
                       ),
                     ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
@@ -93,6 +95,7 @@ class UpgradeScreen extends StatelessWidget {
 
                     // Features
                     _buildFeatureItem(
+                      context: context,
                       icon: Icons.palette_rounded,
                       iconColor: AppColors.primary,
                       title: 'Illustrated explanations',
@@ -101,6 +104,7 @@ class UpgradeScreen extends StatelessWidget {
                     ),
                     const SizedBox(height: 16),
                     _buildFeatureItem(
+                      context: context,
                       icon: Icons.play_circle_rounded,
                       iconColor: Colors.purple,
                       title: 'Short visual clips',
@@ -109,6 +113,7 @@ class UpgradeScreen extends StatelessWidget {
                     ),
                     const SizedBox(height: 16),
                     _buildFeatureItem(
+                      context: context,
                       icon: Icons.wifi_off_rounded,
                       iconColor: Colors.green,
                       title: 'Offline reading',
@@ -141,8 +146,8 @@ class UpgradeScreen extends StatelessWidget {
                             Navigator.of(context).pop();
                           },
                           style: ElevatedButton.styleFrom(
-                            backgroundColor: AppColors.inkLight,
-                            foregroundColor: Colors.white,
+                            backgroundColor: cs.inverseSurface,
+                            foregroundColor: cs.onInverseSurface,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(14),
@@ -173,7 +178,7 @@ class UpgradeScreen extends StatelessWidget {
                           'Restore Purchases',
                           style: GoogleFonts.inter(
                             fontSize: 12,
-                            color: AppColors.textMuted,
+                            color: cs.onSurfaceVariant,
                           ),
                         ),
                       ),
@@ -182,7 +187,7 @@ class UpgradeScreen extends StatelessWidget {
                         height: 4,
                         margin: const EdgeInsets.symmetric(horizontal: 8),
                         decoration: BoxDecoration(
-                          color: Colors.grey[300],
+                          color: cs.outlineVariant,
                           shape: BoxShape.circle,
                         ),
                       ),
@@ -192,7 +197,7 @@ class UpgradeScreen extends StatelessWidget {
                           'Terms',
                           style: GoogleFonts.inter(
                             fontSize: 12,
-                            color: AppColors.textMuted,
+                            color: cs.onSurfaceVariant,
                           ),
                         ),
                       ),
@@ -213,13 +218,15 @@ class UpgradeScreen extends StatelessWidget {
     required String title,
     required String subtitle,
     required int delay,
+    required BuildContext context,
   }) {
+    final cs = Theme.of(context).colorScheme;
     return Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
-            color: Colors.white.withValues(alpha: 0.6),
+            color: cs.surface,
             borderRadius: BorderRadius.circular(16),
-            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
+            border: Border.all(color: cs.outlineVariant),
           ),
           child: Row(
             children: [
@@ -242,7 +249,7 @@ class UpgradeScreen extends StatelessWidget {
                       style: GoogleFonts.libreBaskerville(
                         fontSize: 15,
                         fontWeight: FontWeight.w500,
-                        color: AppColors.inkLight,
+                        color: cs.onSurface,
                       ),
                     ),
                     const SizedBox(height: 2),
@@ -250,7 +257,7 @@ class UpgradeScreen extends StatelessWidget {
                       subtitle,
                       style: GoogleFonts.inter(
                         fontSize: 12,
-                        color: AppColors.textMuted,
+                        color: cs.onSurfaceVariant,
                       ),
                     ),
                   ],
diff --git a/lib/state/book_provider.dart b/lib/state/book_provider.dart
index 02c9304..2d77ff5 100644
--- a/lib/state/book_provider.dart
+++ b/lib/state/book_provider.dart
@@ -298,8 +298,10 @@ class BookProvider extends ChangeNotifier {
         LearningBlock(
           id: blockId,
           tag: slideTitle,
+          type: _normalizeBlockType(block.type),
           headline: headline,
           content: body,
+          quote: block.type == 'quote' ? (block.text.isNotEmpty ? block.text : body) : null,
           takeaway: block.type == 'takeaway' ? body : null,
           imageUrl: imageUrl,
           pendingImagePrompt: pendingPrompt,
@@ -350,6 +352,32 @@ class BookProvider extends ChangeNotifier {
     }
   }
 
+  /// Normalize backend block type to one of: quote, insight, scene, takeaway
+  String _normalizeBlockType(String type) {
+    switch (type) {
+      case 'quote':
+        return 'quote';
+      case 'scene':
+      case 'visual':
+      case 'emotion':
+        return 'scene';
+      case 'takeaway':
+        return 'takeaway';
+      case 'insight':
+      case 'reveal':
+      case 'tension':
+      case 'core_idea':
+      case 'explanation':
+      case 'example':
+      case 'nuance':
+      case 'contrast':
+      case 'reflection':
+      case 'lyric_scroll':
+      default:
+        return 'insight';
+    }
+  }
+
   /// Extract headline from block (first sentence or type-based)
   String _extractHeadline(ContentBlock block) {
     // Prefer headline field
@@ -500,6 +528,7 @@ class BookProvider extends ChangeNotifier {
           LearningBlock(
             id: '${_currentBookId}_ch${i + 1}_loading',
             tag: 'LOADING',
+            type: 'insight',
             headline: 'Loading Chapter ${i + 1}...',
             content: 'AI is processing this chapter. Please wait...',
             estimatedReadTime: 30,
@@ -789,6 +818,7 @@ class BookProvider extends ChangeNotifier {
         LearningBlock(
           id: '${_currentBookId}_ch${chapterNum}_0',
           tag: 'CONTENT',
+          type: 'insight',
           headline: 'Chapter $chapterNum Content',
           content: preview,
           estimatedReadTime: _estimateReadTime(preview),
@@ -1105,6 +1135,7 @@ class BookProvider extends ChangeNotifier {
                 LearningBlock(
                   id: '${_currentBookId}_ch${chNum}_loading',
                   tag: 'LOADING',
+                  type: 'insight',
                   headline: 'Loading Chapter $chNum...',
                   content: 'AI is processing this chapter. Please wait...',
                   estimatedReadTime: 30,
@@ -1327,6 +1358,7 @@ class BookProvider extends ChangeNotifier {
         updatedBlocks[blockIndex] = LearningBlock(
           id: targetBlock.id,
           tag: targetBlock.tag,
+          type: targetBlock.type,
           headline: targetBlock.headline,
           content: targetBlock.content,
           quote: targetBlock.quote,
diff --git a/lib/theme/app_theme.dart b/lib/theme/app_theme.dart
index a26105a..bbdeb8c 100644
--- a/lib/theme/app_theme.dart
+++ b/lib/theme/app_theme.dart
@@ -14,8 +14,12 @@ class AppTheme {
         primaryContainer: AppColors.primaryLight.withOpacity(0.12),
         secondary: AppColors.secondary,
         onSecondary: Colors.white,
-        surface: AppColors.surfaceLight,
+        surface: const Color(0xFFFFF7ED), // Warm peach cream (Orange 50)
         onSurface: AppColors.inkLight,
+        onSurfaceVariant: AppColors.textMuted,
+        outline: AppColors.textMuted,
+        outlineVariant: const Color(0xFFE8DDD3), // Warm border
+        surfaceContainerHighest: const Color(0xFFFFEDD5), // Orange 100
         error: AppColors.error,
         onError: Colors.white,
       ),
@@ -36,11 +40,11 @@ class AppTheme {
       ),
       cardTheme: CardThemeData(
         elevation: 0,
-        color: AppColors.surfaceLight,
+        color: const Color(0xFFFFF7ED),
         surfaceTintColor: Colors.transparent,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
-          side: BorderSide(color: AppColors.inkLight.withOpacity(0.06)),
+          side: const BorderSide(color: Color(0xFFE8DDD3)),
         ),
       ),
       elevatedButtonTheme: ElevatedButtonThemeData(
@@ -92,7 +96,7 @@ class AppTheme {
         labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
       ),
       bottomSheetTheme: const BottomSheetThemeData(
-        backgroundColor: AppColors.surfaceLight,
+        backgroundColor: Color(0xFFFFF7ED),
         surfaceTintColor: Colors.transparent,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
@@ -150,6 +154,10 @@ class AppTheme {
         onSecondary: Colors.white,
         surface: AppColors.surfaceDark,
         onSurface: AppColors.inkDark,
+        onSurfaceVariant: AppColors.textMutedDark,
+        outline: AppColors.textMutedDark,
+        outlineVariant: const Color(0xFF334155), // Slate 700
+        surfaceContainerHighest: const Color(0xFF263245), // Slate 800.5
         error: AppColors.error,
         onError: Colors.white,
       ),
diff --git a/lib/theme/theme_provider.dart b/lib/theme/theme_provider.dart
index 551f496..5ec4d3d 100644
--- a/lib/theme/theme_provider.dart
+++ b/lib/theme/theme_provider.dart
@@ -1,30 +1,53 @@
 import 'package:flutter/material.dart';
+import 'package:shared_preferences/shared_preferences.dart';
 
 /// Provider for managing theme mode (light/dark/system).
-/// Extends [ChangeNotifier] to notify listeners when theme changes.
+/// Persists the user's preference across app restarts via SharedPreferences.
 class ThemeProvider extends ChangeNotifier {
-  /// Private theme mode variable, defaulting to system theme.
+  static const _prefKey = 'flashbook_theme_mode';
+
   ThemeMode _themeMode = ThemeMode.system;
 
-  /// Getter for the current theme mode.
+  ThemeProvider() {
+    _loadFromPrefs();
+  }
+
   ThemeMode get themeMode => _themeMode;
 
-  /// Check if dark mode is currently active.
   bool get isDarkMode => _themeMode == ThemeMode.dark;
 
-  /// Toggle between light and dark theme modes.
-  ///
-  /// [isDark] - If true, switches to dark mode; if false, switches to light mode.
   void toggleTheme(bool isDark) {
     _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
+    _saveToPrefs();
     notifyListeners();
   }
 
-  /// Set theme mode to a specific value.
-  ///
-  /// [mode] - The [ThemeMode] to set (light, dark, or system).
   void setThemeMode(ThemeMode mode) {
     _themeMode = mode;
+    _saveToPrefs();
+    notifyListeners();
+  }
+
+  Future<void> _loadFromPrefs() async {
+    final prefs = await SharedPreferences.getInstance();
+    final saved = prefs.getString(_prefKey);
+    if (saved == 'dark') {
+      _themeMode = ThemeMode.dark;
+    } else if (saved == 'light') {
+      _themeMode = ThemeMode.light;
+    }
     notifyListeners();
   }
+
+  Future<void> _saveToPrefs() async {
+    final prefs = await SharedPreferences.getInstance();
+    switch (_themeMode) {
+      case ThemeMode.dark:
+        await prefs.setString(_prefKey, 'dark');
+      case ThemeMode.light:
+        await prefs.setString(_prefKey, 'light');
+      case ThemeMode.system:
+        await prefs.remove(_prefKey);
+    }
+  }
 }
diff --git a/lib/widgets/block_renderer.dart b/lib/widgets/block_renderer.dart
new file mode 100644
index 0000000..842dfca
--- /dev/null
+++ b/lib/widgets/block_renderer.dart
@@ -0,0 +1,576 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_animate/flutter_animate.dart';
+import 'package:google_fonts/google_fonts.dart';
+import '../theme/app_colors.dart';
+import '../models/models.dart';
+
+/// BlockRenderer ??? dispatches to the right visual treatment based on block.type.
+/// Types: quote, insight, scene, takeaway
+class BlockRenderer extends StatelessWidget {
+  final LearningBlock block;
+  final bool hasImageBackground;
+  final double fontSize;
+  final bool isBold;
+
+  const BlockRenderer({
+    super.key,
+    required this.block,
+    this.hasImageBackground = false,
+    this.fontSize = 18.0,
+    this.isBold = false,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    switch (block.type) {
+      case 'quote':
+        return _QuoteCard(
+          block: block,
+          hasImage: hasImageBackground,
+          fontSize: fontSize,
+        );
+      case 'scene':
+        return _SceneCard(
+          block: block,
+          hasImage: hasImageBackground,
+          fontSize: fontSize,
+          isBold: isBold,
+        );
+      case 'takeaway':
+        return _TakeawayCard(
+          block: block,
+          hasImage: hasImageBackground,
+          fontSize: fontSize,
+        );
+      case 'insight':
+      default:
+        return _InsightCard(
+          block: block,
+          hasImage: hasImageBackground,
+          fontSize: fontSize,
+          isBold: isBold,
+        );
+    }
+  }
+}
+
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+// QUOTE CARD ??? Large serif typography, quote mark accent
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+class _QuoteCard extends StatelessWidget {
+  final LearningBlock block;
+  final bool hasImage;
+  final double fontSize;
+
+  const _QuoteCard({
+    required this.block,
+    required this.hasImage,
+    required this.fontSize,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+    final quoteText = block.quote ?? block.content;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        // Decorative quote mark
+        Text(
+          '\u201C',
+          style: GoogleFonts.libreBaskerville(
+            fontSize: 64,
+            fontWeight: FontWeight.w700,
+            height: 0.8,
+            color: hasImage
+                ? Colors.white.withValues(alpha: 0.4)
+                : AppColors.primary.withValues(alpha: 0.3),
+          ),
+        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
+
+        // Quote text ??? large italic serif
+        Text(
+          quoteText,
+          style: GoogleFonts.libreBaskerville(
+            fontSize: fontSize + 4,
+            fontStyle: FontStyle.italic,
+            fontWeight: FontWeight.w400,
+            color: hasImage
+                ? Colors.white
+                : cs.onSurface,
+            height: 1.7,
+            letterSpacing: 0.2,
+            shadows: hasImage
+                ? [
+                    Shadow(
+                      color: Colors.black.withValues(alpha: 0.6),
+                      blurRadius: 10,
+                      offset: const Offset(0, 2),
+                    ),
+                  ]
+                : null,
+          ),
+        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
+
+        const SizedBox(height: 24),
+
+        // Accent line + source/context
+        Row(
+          children: [
+            Container(
+              width: 32,
+              height: 2,
+              decoration: BoxDecoration(
+                color: AppColors.primary,
+                borderRadius: BorderRadius.circular(1),
+              ),
+            ),
+            const SizedBox(width: 12),
+            Expanded(
+              child: Text(
+                block.headline,
+                style: GoogleFonts.inter(
+                  fontSize: 13,
+                  fontWeight: FontWeight.w600,
+                  color: hasImage
+                      ? Colors.white.withValues(alpha: 0.7)
+                      : cs.onSurfaceVariant,
+                  letterSpacing: 0.3,
+                ),
+                maxLines: 2,
+                overflow: TextOverflow.ellipsis,
+              ),
+            ),
+          ],
+        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
+      ],
+    );
+  }
+}
+
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+// INSIGHT CARD ??? Main explanation text with headline
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+class _InsightCard extends StatelessWidget {
+  final LearningBlock block;
+  final bool hasImage;
+  final double fontSize;
+  final bool isBold;
+
+  const _InsightCard({
+    required this.block,
+    required this.hasImage,
+    required this.fontSize,
+    required this.isBold,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        // Insight icon + label
+        Row(
+          children: [
+            Container(
+              padding: const EdgeInsets.all(6),
+              decoration: BoxDecoration(
+                color: hasImage
+                    ? Colors.white.withValues(alpha: 0.15)
+                    : AppColors.accentBlue.withValues(alpha: 0.1),
+                borderRadius: BorderRadius.circular(8),
+              ),
+              child: Icon(
+                Icons.lightbulb_outline_rounded,
+                size: 16,
+                color: hasImage ? Colors.white : AppColors.accentBlue,
+              ),
+            ),
+            const SizedBox(width: 10),
+            Text(
+              'INSIGHT',
+              style: GoogleFonts.inter(
+                fontSize: 10,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 2,
+                color: hasImage
+                    ? Colors.white.withValues(alpha: 0.6)
+                    : AppColors.accentBlue,
+              ),
+            ),
+          ],
+        ).animate().fadeIn(duration: 300.ms),
+
+        const SizedBox(height: 20),
+
+        // Headline
+        Text(
+          block.headline,
+          style: GoogleFonts.inter(
+            fontSize: 26,
+            fontWeight: FontWeight.w800,
+            color: hasImage ? Colors.white : cs.onSurface,
+            height: 1.2,
+            letterSpacing: -0.5,
+            shadows: hasImage
+                ? [
+                    Shadow(
+                      color: Colors.black.withValues(alpha: 0.5),
+                      blurRadius: 8,
+                      offset: const Offset(0, 2),
+                    ),
+                  ]
+                : null,
+          ),
+        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
+
+        const SizedBox(height: 20),
+
+        // Content body
+        Text(
+          block.content,
+          style: GoogleFonts.libreBaskerville(
+            fontSize: fontSize,
+            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
+            color: hasImage
+                ? Colors.white.withValues(alpha: 0.95)
+                : cs.onSurface.withValues(alpha: 0.85),
+            height: 1.8,
+            shadows: hasImage
+                ? [
+                    Shadow(
+                      color: Colors.black.withValues(alpha: 0.5),
+                      blurRadius: 6,
+                      offset: const Offset(0, 1),
+                    ),
+                  ]
+                : null,
+          ),
+        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
+      ],
+    );
+  }
+}
+
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+// SCENE CARD ??? Cinematic feel, larger text, atmospheric
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+class _SceneCard extends StatelessWidget {
+  final LearningBlock block;
+  final bool hasImage;
+  final double fontSize;
+  final bool isBold;
+
+  const _SceneCard({
+    required this.block,
+    required this.hasImage,
+    required this.fontSize,
+    required this.isBold,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        // Scene marker
+        Container(
+          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
+          decoration: BoxDecoration(
+            color: hasImage
+                ? Colors.white.withValues(alpha: 0.15)
+                : AppColors.accentWarm.withValues(alpha: 0.1),
+            borderRadius: BorderRadius.circular(20),
+            border: Border.all(
+              color: hasImage
+                  ? Colors.white.withValues(alpha: 0.2)
+                  : AppColors.accentWarm.withValues(alpha: 0.25),
+            ),
+          ),
+          child: Row(
+            mainAxisSize: MainAxisSize.min,
+            children: [
+              Icon(
+                Icons.movie_filter_rounded,
+                size: 14,
+                color: hasImage ? Colors.white : AppColors.accentWarm,
+              ),
+              const SizedBox(width: 6),
+              Text(
+                'SCENE',
+                style: GoogleFonts.inter(
+                  fontSize: 10,
+                  fontWeight: FontWeight.w800,
+                  letterSpacing: 2,
+                  color: hasImage
+                      ? Colors.white.withValues(alpha: 0.8)
+                      : AppColors.accentWarm,
+                ),
+              ),
+            ],
+          ),
+        ).animate().fadeIn(duration: 300.ms),
+
+        const SizedBox(height: 24),
+
+        // Headline ??? cinematic large
+        Text(
+          block.headline,
+          style: GoogleFonts.libreBaskerville(
+            fontSize: 30,
+            fontWeight: FontWeight.w700,
+            color: hasImage ? Colors.white : cs.onSurface,
+            height: 1.2,
+            shadows: hasImage
+                ? [
+                    Shadow(
+                      color: Colors.black.withValues(alpha: 0.6),
+                      blurRadius: 12,
+                      offset: const Offset(0, 3),
+                    ),
+                  ]
+                : null,
+          ),
+        ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.15, end: 0),
+
+        const SizedBox(height: 24),
+
+        // Content ??? narrative style
+        Text(
+          block.content,
+          style: GoogleFonts.libreBaskerville(
+            fontSize: fontSize + 1,
+            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
+            fontStyle: FontStyle.italic,
+            color: hasImage
+                ? Colors.white.withValues(alpha: 0.92)
+                : cs.onSurface.withValues(alpha: 0.8),
+            height: 1.9,
+            shadows: hasImage
+                ? [
+                    Shadow(
+                      color: Colors.black.withValues(alpha: 0.5),
+                      blurRadius: 6,
+                      offset: const Offset(0, 1),
+                    ),
+                  ]
+                : null,
+          ),
+        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
+      ],
+    );
+  }
+}
+
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+// TAKEAWAY CARD ??? Key points with bullet styling
+// ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
+class _TakeawayCard extends StatelessWidget {
+  final LearningBlock block;
+  final bool hasImage;
+  final double fontSize;
+
+  const _TakeawayCard({
+    required this.block,
+    required this.hasImage,
+    required this.fontSize,
+  });
+
+  @override
+  Widget build(BuildContext context) {
+    final cs = Theme.of(context).colorScheme;
+    // Split content into bullet points if it contains newlines or bullet chars
+    final points = _extractPoints(block.content);
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        // Takeaway header
+        Row(
+          children: [
+            Container(
+              padding: const EdgeInsets.all(6),
+              decoration: BoxDecoration(
+                color: hasImage
+                    ? Colors.white.withValues(alpha: 0.15)
+                    : AppColors.success.withValues(alpha: 0.1),
+                borderRadius: BorderRadius.circular(8),
+              ),
+              child: Icon(
+                Icons.bookmark_rounded,
+                size: 16,
+                color: hasImage ? Colors.white : AppColors.success,
+              ),
+            ),
+            const SizedBox(width: 10),
+            Text(
+              'KEY TAKEAWAY',
+              style: GoogleFonts.inter(
+                fontSize: 10,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 2,
+                color: hasImage
+                    ? Colors.white.withValues(alpha: 0.7)
+                    : AppColors.success,
+              ),
+            ),
+          ],
+        ).animate().fadeIn(duration: 300.ms),
+
+        const SizedBox(height: 20),
+
+        // Headline
+        Text(
+          block.headline,
+          style: GoogleFonts.inter(
+            fontSize: 24,
+            fontWeight: FontWeight.w800,
+            color: hasImage ? Colors.white : cs.onSurface,
+            height: 1.2,
+            letterSpacing: -0.3,
+            shadows: hasImage
+                ? [
+                    Shadow(
+                      color: Colors.black.withValues(alpha: 0.5),
+                      blurRadius: 8,
+                      offset: const Offset(0, 2),
+                    ),
+                  ]
+                : null,
+          ),
+        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
+
+        const SizedBox(height: 20),
+
+        // Bullet points or content
+        if (points.length > 1)
+          ...points.asMap().entries.map((entry) {
+            final i = entry.key;
+            final point = entry.value;
+            return Padding(
+              padding: const EdgeInsets.only(bottom: 14),
+              child: Row(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Container(
+                    width: 6,
+                    height: 6,
+                    margin: const EdgeInsets.only(top: 8),
+                    decoration: BoxDecoration(
+                      color: hasImage
+                          ? Colors.white.withValues(alpha: 0.6)
+                          : AppColors.success,
+                      shape: BoxShape.circle,
+                    ),
+                  ),
+                  const SizedBox(width: 12),
+                  Expanded(
+                    child: Text(
+                      point,
+                      style: GoogleFonts.inter(
+                        fontSize: fontSize - 1,
+                        fontWeight: FontWeight.w500,
+                        color: hasImage
+                            ? Colors.white.withValues(alpha: 0.92)
+                            : cs.onSurface.withValues(alpha: 0.85),
+                        height: 1.6,
+                        shadows: hasImage
+                            ? [
+                                Shadow(
+                                  color: Colors.black.withValues(alpha: 0.4),
+                                  blurRadius: 4,
+                                ),
+                              ]
+                            : null,
+                      ),
+                    ),
+                  ),
+                ],
+              ),
+            ).animate().fadeIn(
+              delay: (200 + i * 100).ms,
+              duration: 400.ms,
+            ).slideX(begin: 0.05, end: 0);
+          })
+        else
+          Text(
+            block.content,
+            style: GoogleFonts.inter(
+              fontSize: fontSize,
+              fontWeight: FontWeight.w500,
+              color: hasImage
+                  ? Colors.white.withValues(alpha: 0.92)
+                  : cs.onSurface.withValues(alpha: 0.85),
+              height: 1.7,
+              shadows: hasImage
+                  ? [
+                      Shadow(
+                        color: Colors.black.withValues(alpha: 0.4),
+                        blurRadius: 4,
+                      ),
+                    ]
+                  : null,
+            ),
+          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
+
+        // Takeaway summary box (if block has takeaway field)
+        if (block.takeaway != null) ...[
+          const SizedBox(height: 24),
+          Container(
+            padding: const EdgeInsets.all(16),
+            decoration: BoxDecoration(
+              color: hasImage
+                  ? Colors.white.withValues(alpha: 0.12)
+                  : AppColors.success.withValues(alpha: 0.06),
+              borderRadius: BorderRadius.circular(14),
+              border: Border.all(
+                color: hasImage
+                    ? Colors.white.withValues(alpha: 0.15)
+                    : AppColors.success.withValues(alpha: 0.2),
+              ),
+            ),
+            child: Row(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Icon(
+                  Icons.auto_awesome_rounded,
+                  size: 18,
+                  color: hasImage ? Colors.white.withValues(alpha: 0.7) : AppColors.success,
+                ),
+                const SizedBox(width: 10),
+                Expanded(
+                  child: Text(
+                    block.takeaway!,
+                    style: GoogleFonts.inter(
+                      fontSize: 14,
+                      fontWeight: FontWeight.w600,
+                      color: hasImage ? Colors.white : cs.onSurface,
+                      height: 1.5,
+                    ),
+                  ),
+                ),
+              ],
+            ),
+          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
+        ],
+      ],
+    );
+  }
+
+  /// Extract bullet points from content text
+  List<String> _extractPoints(String content) {
+    // Split on newlines and filter empty lines
+    final lines = content
+        .split(RegExp(r'\n'))
+        .map((l) => l.replaceFirst(RegExp(r'^[\s???\-??????\*]+'), '').trim())
+        .where((l) => l.isNotEmpty)
+        .toList();
+
+    return lines.length > 1 ? lines : [content];
+  }
+}
diff --git a/lib/widgets/learning_card.dart b/lib/widgets/learning_card.dart
index 7b96c50..7beb9d0 100644
--- a/lib/widgets/learning_card.dart
+++ b/lib/widgets/learning_card.dart
@@ -17,6 +17,7 @@ import 'package:gal/gal.dart';
 import 'package:universal_html/html.dart' as html;
 import 'lyric_flow_widget.dart';
 import 'note_input_dialog.dart';
+import 'block_renderer.dart';
 
 /// Learning Card widget - Instagram Reels style with image background.
 /// When image is present, shows it as full background with light overlay.
@@ -194,7 +195,7 @@ class _LearningCardState extends State<LearningCard> {
               children: [
                 // Top section: Progress bar
                 Padding(
-                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
+                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
                   child: _buildProgressIndicator(),
                 ),
 
@@ -202,7 +203,7 @@ class _LearningCardState extends State<LearningCard> {
                 Expanded(
                   child: SingleChildScrollView(
                     physics: const BouncingScrollPhysics(),
-                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
+                    padding: const EdgeInsets.fromLTRB(20, 32, 68, 24),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
@@ -214,41 +215,7 @@ class _LearningCardState extends State<LearningCard> {
 
                         const SizedBox(height: 16),
 
-                        // Headline
-                        Text(
-                              widget.block.headline,
-                              style: GoogleFonts.inter(
-                                fontSize: 28,
-                                fontWeight: FontWeight.w800,
-                                color:
-                                    _hasImage
-                                        ? Colors.white
-                                        : Theme.of(
-                                          context,
-                                        ).textTheme.headlineLarge?.color,
-                                height: 1.2,
-                                letterSpacing: -0.5,
-                                shadows:
-                                    _hasImage
-                                        ? [
-                                          Shadow(
-                                            color: Colors.black.withValues(
-                                              alpha: 0.5,
-                                            ),
-                                            blurRadius: 8,
-                                            offset: const Offset(0, 2),
-                                          ),
-                                        ]
-                                        : null,
-                              ),
-                            )
-                            .animate()
-                            .fadeIn(delay: 100.ms, duration: 400.ms)
-                            .slideY(begin: 0.1, end: 0),
-
-                        const SizedBox(height: 20),
-
-                        // Content text
+                        // Type-aware content rendering
                         _needsLyricFlow
                             ? LyricFlowWidget(
                               text: widget.block.content,
@@ -266,43 +233,12 @@ class _LearningCardState extends State<LearningCard> {
                                           ),
                               hasImageBackground: _hasImage,
                             )
-                            : Text(
-                              widget.block.content,
-                              style: GoogleFonts.libreBaskerville(
+                            : BlockRenderer(
+                                block: widget.block,
+                                hasImageBackground: _hasImage,
                                 fontSize: widget.fontSize,
-                                fontWeight: widget.isBold ? FontWeight.bold : FontWeight.normal,
-                                color:
-                                    _hasImage
-                                        ? Colors.white.withValues(alpha: 0.95)
-                                        : Theme.of(context)
-                                                .textTheme
-                                                .bodyLarge
-                                                ?.color
-                                                ?.withValues(alpha: 0.85) ??
-                                            AppColors.inkLight.withValues(
-                                              alpha: 0.85,
-                                            ),
-                                height: 1.8,
-                                shadows:
-                                    _hasImage
-                                        ? [
-                                          Shadow(
-                                            color: Colors.black.withValues(
-                                              alpha: 0.5,
-                                            ),
-                                            blurRadius: 6,
-                                            offset: const Offset(0, 1),
-                                          ),
-                                        ]
-                                        : null,
+                                isBold: widget.isBold,
                               ),
-                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
-
-                        // Takeaway box
-                        if (widget.block.takeaway != null) ...[
-                          const SizedBox(height: 28),
-                          _buildTakeawayBox(widget.block.takeaway!),
-                        ],
 
                         // Bottom spacing
                         const SizedBox(height: 100),
@@ -310,12 +246,6 @@ class _LearningCardState extends State<LearningCard> {
                     ),
                   ),
                 ),
-
-                // Bottom info bar
-                Padding(
-                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
-                  child: _buildBottomInfo(),
-                ),
               ],
             ),
           ),
@@ -547,104 +477,6 @@ class _LearningCardState extends State<LearningCard> {
     );
   }
 
-  Widget _buildTakeawayBox(String takeaway) {
-    return Container(
-      padding: const EdgeInsets.all(16),
-      decoration: BoxDecoration(
-        color:
-            _hasImage
-                ? Colors.white.withValues(alpha: 0.15)
-                : Theme.of(context).cardColor,
-        borderRadius: BorderRadius.circular(16),
-        border: Border.all(
-          color:
-              _hasImage
-                  ? Colors.white.withValues(alpha: 0.2)
-                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
-        ),
-      ),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          Text(
-            'TAKEAWAY',
-            style: GoogleFonts.inter(
-              fontSize: 10,
-              fontWeight: FontWeight.bold,
-              letterSpacing: 1.5,
-              color:
-                  _hasImage
-                      ? Colors.white.withValues(alpha: 0.7)
-                      : Theme.of(
-                        context,
-                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
-            ),
-          ),
-          const SizedBox(height: 8),
-          Text(
-            takeaway,
-            style: GoogleFonts.inter(
-              fontSize: 14,
-              fontWeight: FontWeight.w500,
-              color:
-                  _hasImage
-                      ? Colors.white
-                      : Theme.of(context).textTheme.bodyMedium?.color,
-              height: 1.5,
-              shadows:
-                  _hasImage
-                      ? [
-                        Shadow(
-                          color: Colors.black.withValues(alpha: 0.3),
-                          blurRadius: 4,
-                        ),
-                      ]
-                      : null,
-            ),
-          ),
-        ],
-      ),
-    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
-  }
-
-  Widget _buildBottomInfo() {
-    return Row(
-      mainAxisAlignment: MainAxisAlignment.start,
-      children: [
-        Container(
-          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
-          decoration: BoxDecoration(
-            color:
-                _hasImage
-                    ? Colors.white.withValues(alpha: 0.15)
-                    : Theme.of(context).cardColor,
-            borderRadius: BorderRadius.circular(12),
-          ),
-          child: Text(
-            '${(widget.block.estimatedReadTime / 60).ceil()} min read',
-            style: GoogleFonts.inter(
-              fontSize: 12,
-              fontWeight: FontWeight.w500,
-              color:
-                  _hasImage
-                      ? Colors.white
-                      : Theme.of(context).textTheme.bodySmall?.color,
-              shadows:
-                  _hasImage
-                      ? [
-                        Shadow(
-                          color: Colors.black.withValues(alpha: 0.3),
-                          blurRadius: 4,
-                        ),
-                      ]
-                      : null,
-            ),
-          ),
-        ),
-      ],
-    );
-  }
-
   Widget _buildFloatingActions(BuildContext context) {
     return Opacity(
       opacity: 0.7,
@@ -790,14 +622,14 @@ class _LearningCardState extends State<LearningCard> {
     bool isActive = false,
     required VoidCallback onTap,
   }) {
+    final cs = Theme.of(context).colorScheme;
     return Material(
-      color:
-          _hasImage
-              ? Colors.black.withValues(alpha: 0.3)
-              : Theme.of(context).cardColor,
+      color: _hasImage
+          ? Colors.black.withValues(alpha: 0.3)
+          : cs.surfaceContainerHighest,
       borderRadius: BorderRadius.circular(20),
-      elevation: _hasImage ? 0 : 2,
-      shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
+      elevation: _hasImage ? 0 : 1,
+      shadowColor: cs.shadow.withValues(alpha: 0.08),
       child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(20),
@@ -807,14 +639,9 @@ class _LearningCardState extends State<LearningCard> {
           alignment: Alignment.center,
           child: Icon(
             icon,
-            color:
-                isActive
-                    ? AppColors.accentGold
-                    : (_hasImage
-                        ? Colors.white
-                        : Theme.of(
-                          context,
-                        ).iconTheme.color?.withValues(alpha: 0.6)),
+            color: isActive
+                ? AppColors.accentGold
+                : (_hasImage ? Colors.white : cs.onSurfaceVariant),
             size: 22,
           ),
         ),
diff --git a/pubspec.lock b/pubspec.lock
index 400a18b..83f097f 100644
--- a/pubspec.lock
+++ b/pubspec.lock
@@ -166,6 +166,11 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "3.4.1"
+  flutter_driver:
+    dependency: transitive
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   flutter_lints:
     dependency: "direct dev"
     description:
@@ -200,6 +205,11 @@ packages:
     description: flutter
     source: sdk
     version: "0.0.0"
+  fuchsia_remote_debug_protocol:
+    dependency: transitive
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   gal:
     dependency: "direct main"
     description:
@@ -240,6 +250,11 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "4.1.2"
+  integration_test:
+    dependency: "direct dev"
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   leak_tracker:
     dependency: transitive
     description:
@@ -432,6 +447,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "2.1.8"
+  process:
+    dependency: transitive
+    description:
+      name: process
+      sha256: c6248e4526673988586e8c00bb22a49210c258dc91df5227d5da9748ecf79744
+      url: "https://pub.dev"
+    source: hosted
+    version: "5.0.5"
   provider:
     dependency: "direct main"
     description:
@@ -581,6 +604,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.4.1"
+  sync_http:
+    dependency: transitive
+    description:
+      name: sync_http
+      sha256: "7f0cd72eca000d2e026bcd6f990b81d0ca06022ef4e32fb257b30d3d1014a961"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.3.1"
   synchronized:
     dependency: transitive
     description:
@@ -661,6 +692,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.1.1"
+  webdriver:
+    dependency: transitive
+    description:
+      name: webdriver
+      sha256: "2f3a14ca026957870cfd9c635b83507e0e51d8091568e90129fbf805aba7cade"
+      url: "https://pub.dev"
+    source: hosted
+    version: "3.1.0"
   win32:
     dependency: transitive
     description:
diff --git a/pubspec.yaml b/pubspec.yaml
index bad496f..f4c2c07 100644
--- a/pubspec.yaml
+++ b/pubspec.yaml
@@ -38,6 +38,8 @@ dependencies:
 dev_dependencies:
   flutter_test:
     sdk: flutter
+  integration_test:
+    sdk: flutter
   flutter_lints: ^5.0.0
 
 flutter:
```
