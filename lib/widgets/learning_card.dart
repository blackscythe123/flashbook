import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../state/state.dart';
import 'lyric_flow_widget.dart';

/// Learning Card widget - Instagram Reels style with image background.
/// When image is present, shows it as full background with light overlay.
/// Text is white with shadow for readability on images.
class LearningCard extends StatefulWidget {
  final LearningBlock block;
  final Chapter? chapter;
  final String bookTitle;
  final double progress;
  final bool isFirst;
  final bool isLast;
  final bool isLoading;

  const LearningCard({
    super.key,
    required this.block,
    required this.chapter,
    required this.bookTitle,
    required this.progress,
    this.isFirst = false,
    this.isLast = false,
    this.isLoading = false,
  });

  @override
  State<LearningCard> createState() => _LearningCardState();
}

class _LearningCardState extends State<LearningCard> {
  bool get _hasImage => widget.block.imageUrl != null;
  bool get _needsLyricFlow => widget.block.content.length > 300;
  bool _isGeneratingImage = false;

  @override
  void initState() {
    super.initState();
    _triggerLazyImageGeneration();
  }

  /// Trigger lazy image generation if block has pending prompt
  void _triggerLazyImageGeneration() {
    if (widget.block.pendingImagePrompt != null &&
        widget.block.imageUrl == null &&
        !_isGeneratingImage) {
      _isGeneratingImage = true;

      // Generate image in background
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bookProvider = context.read<BookProvider>();
        bookProvider.generateImageForBlock(widget.block.id).then((imageUrl) {
          if (mounted) {
            setState(() {
              _isGeneratingImage = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.block.tag == 'LOADING') {
      return _buildLoadingCard(context);
    }

    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (if available)
          if (_hasImage) _buildImageBackground(),

          // Gradient overlay for text readability
          if (_hasImage) _buildGradientOverlay(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top section: Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: _buildProgressIndicator(),
                ),

                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag
                        if (widget.block.tag != null)
                          _buildTag(
                            widget.block.tag!,
                          ).animate().fadeIn(duration: 300.ms),

                        const SizedBox(height: 16),

                        // Headline
                        Text(
                              widget.block.headline,
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color:
                                    _hasImage
                                        ? Colors.white
                                        : AppColors.inkLight,
                                height: 1.2,
                                letterSpacing: -0.5,
                                shadows:
                                    _hasImage
                                        ? [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 20),

                        // Content text
                        _needsLyricFlow
                            ? LyricFlowWidget(
                              text: widget.block.content,
                              textColor:
                                  _hasImage
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : AppColors.inkLight.withValues(
                                        alpha: 0.85,
                                      ),
                              hasImageBackground: _hasImage,
                            )
                            : Text(
                              widget.block.content,
                              style: GoogleFonts.libreBaskerville(
                                fontSize: 18,
                                color:
                                    _hasImage
                                        ? Colors.white.withValues(alpha: 0.95)
                                        : AppColors.inkLight.withValues(
                                          alpha: 0.85,
                                        ),
                                height: 1.8,
                                shadows:
                                    _hasImage
                                        ? [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                        : null,
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                        // Takeaway box
                        if (widget.block.takeaway != null) ...[
                          const SizedBox(height: 28),
                          _buildTakeawayBox(widget.block.takeaway!),
                        ],

                        // Bottom spacing
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom info bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _buildBottomInfo(),
                ),
              ],
            ),
          ),

          // Floating action buttons (top-right)
          Positioned(
            top: 100,
            right: 12,
            child: _buildFloatingActions(context),
          ),

          // Swipe hint (first card only)
          if (widget.isFirst)
            Positioned(bottom: 80, left: 0, right: 0, child: _buildSwipeHint()),
        ],
      ),
    );
  }

  /// Full-screen image background
  Widget _buildImageBackground() {
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: widget.block.imageUrl!,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: AppColors.backgroundLight,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: AppColors.backgroundLight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image unavailable',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  /// Gradient overlay for text readability on image backgrounds
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final waitTime = bookProvider.estimatedWaitSeconds;

    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
            const SizedBox(height: 24),
            Text(
              'Generating Content...',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.inkLight,
              ),
            ),
            const SizedBox(height: 12),
            if (waitTime > 0)
              Text(
                'Estimated wait: ~$waitTime seconds',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'AI is summarizing this chapter for you',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            if (bookProvider.loadingError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bookProvider.loadingError!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widget.progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accentGold],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:
            _hasImage
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _hasImage
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        tag.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: _hasImage ? Colors.white : AppColors.primary,
          shadows:
              _hasImage
                  ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }

  Widget _buildTakeawayBox(String takeaway) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _hasImage
                ? Colors.white.withValues(alpha: 0.15)
                : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _hasImage
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAKEAWAY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color:
                  _hasImage
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.inkLight.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            takeaway,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _hasImage ? Colors.white : AppColors.inkLight,
              height: 1.5,
              shadows:
                  _hasImage
                      ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                      : null,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildBottomInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                _hasImage
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(widget.block.estimatedReadTime / 60).ceil()} min read',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _hasImage ? Colors.white : AppColors.textMuted,
              shadows:
                  _hasImage
                      ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bookmark
          Consumer<BookmarkProvider>(
            builder: (context, provider, child) {
              final isBookmarked = provider.isBlockBookmarked(widget.block.id);
              return _buildActionButton(
                icon:
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                isActive: isBookmarked,
                onTap: () {
                  provider.toggleBookmark(
                    bookId: widget.bookTitle,
                    chapterId: widget.chapter?.id ?? '',
                    blockId: widget.block.id,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          // Share
          _buildActionButton(
            icon: Icons.share_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // More
          _buildActionButton(
            icon: Icons.more_vert_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('More options coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _hasImage ? Colors.black.withValues(alpha: 0.3) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: _hasImage ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color:
                isActive
                    ? AppColors.accentGold
                    : (_hasImage
                        ? Colors.white
                        : AppColors.inkLight.withValues(alpha: 0.6)),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Column(
          children: [
            Text(
              'Swipe up to continue',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textMuted),
          ],
        )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn()
        .then()
        .fadeOut(delay: 2.seconds);
  }
}
