import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

/// BlockRenderer — dispatches to the right visual treatment based on block.type.
/// Types: quote, insight, scene, takeaway
class BlockRenderer extends StatelessWidget {
  final LearningBlock block;
  final bool hasImageBackground;
  final double fontSize;
  final bool isBold;

  const BlockRenderer({
    super.key,
    required this.block,
    this.hasImageBackground = false,
    this.fontSize = 18.0,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'quote':
        return _QuoteCard(
          block: block,
          hasImage: hasImageBackground,
          fontSize: fontSize,
        );
      case 'scene':
        return _SceneCard(
          block: block,
          hasImage: hasImageBackground,
          fontSize: fontSize,
          isBold: isBold,
        );
      case 'takeaway':
        return _TakeawayCard(
          block: block,
          hasImage: hasImageBackground,
          fontSize: fontSize,
        );
      case 'insight':
      default:
        return _InsightCard(
          block: block,
          hasImage: hasImageBackground,
          fontSize: fontSize,
          isBold: isBold,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// QUOTE CARD — Large serif typography, quote mark accent
// ─────────────────────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final LearningBlock block;
  final bool hasImage;
  final double fontSize;

  const _QuoteCard({
    required this.block,
    required this.hasImage,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final quoteText = block.quote ?? block.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decorative quote mark
        Text(
          '\u201C',
          style: GoogleFonts.libreBaskerville(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            height: 0.8,
            color: hasImage
                ? Colors.white.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

        // Quote text — large italic serif
        Text(
          quoteText,
          style: GoogleFonts.libreBaskerville(
            fontSize: fontSize + 4,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            color: hasImage
                ? Colors.white
                : cs.onSurface,
            height: 1.7,
            letterSpacing: 0.2,
            shadows: hasImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

        const SizedBox(height: 24),

        // Accent line + source/context
        Row(
          children: [
            Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                block.headline,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INSIGHT CARD — Main explanation text with headline
// ─────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final LearningBlock block;
  final bool hasImage;
  final double fontSize;
  final bool isBold;

  const _InsightCard({
    required this.block,
    required this.hasImage,
    required this.fontSize,
    required this.isBold,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Insight icon + label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: hasImage ? Colors.white : AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'INSIGHT',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppColors.accentBlue,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 20),

        // Headline
        Text(
          block.headline,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: hasImage ? Colors.white : cs.onSurface,
            height: 1.2,
            letterSpacing: -0.5,
            shadows: hasImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 20),

        // Content body
        Text(
          block.content,
          style: GoogleFonts.libreBaskerville(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: hasImage
                ? Colors.white.withValues(alpha: 0.95)
                : cs.onSurface.withValues(alpha: 0.85),
            height: 1.8,
            shadows: hasImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCENE CARD — Cinematic feel, larger text, atmospheric
// ─────────────────────────────────────────────────────────────
class _SceneCard extends StatelessWidget {
  final LearningBlock block;
  final bool hasImage;
  final double fontSize;
  final bool isBold;

  const _SceneCard({
    required this.block,
    required this.hasImage,
    required this.fontSize,
    required this.isBold,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scene marker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasImage
                ? Colors.white.withValues(alpha: 0.15)
                : AppColors.accentWarm.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.accentWarm.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_rounded,
                size: 14,
                color: hasImage ? Colors.white : AppColors.accentWarm,
              ),
              const SizedBox(width: 6),
              Text(
                'SCENE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.accentWarm,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 24),

        // Headline — cinematic large
        Text(
          block.headline,
          style: GoogleFonts.libreBaskerville(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: hasImage ? Colors.white : cs.onSurface,
            height: 1.2,
            shadows: hasImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.15, end: 0),

        const SizedBox(height: 24),

        // Content — narrative style
        Text(
          block.content,
          style: GoogleFonts.libreBaskerville(
            fontSize: fontSize + 1,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: FontStyle.italic,
            color: hasImage
                ? Colors.white.withValues(alpha: 0.92)
                : cs.onSurface.withValues(alpha: 0.8),
            height: 1.9,
            shadows: hasImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAKEAWAY CARD — Key points with bullet styling
// ─────────────────────────────────────────────────────────────
class _TakeawayCard extends StatelessWidget {
  final LearningBlock block;
  final bool hasImage;
  final double fontSize;

  const _TakeawayCard({
    required this.block,
    required this.hasImage,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Split content into bullet points if it contains newlines or bullet chars
    final points = _extractPoints(block.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Takeaway header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bookmark_rounded,
                size: 16,
                color: hasImage ? Colors.white : AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'KEY TAKEAWAY',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.success,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 20),

        // Headline
        Text(
          block.headline,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: hasImage ? Colors.white : cs.onSurface,
            height: 1.2,
            letterSpacing: -0.3,
            shadows: hasImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 20),

        // Bullet points or content
        if (points.length > 1)
          ...points.asMap().entries.map((entry) {
            final i = entry.key;
            final point = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.inter(
                        fontSize: fontSize - 1,
                        fontWeight: FontWeight.w500,
                        color: hasImage
                            ? Colors.white.withValues(alpha: 0.92)
                            : cs.onSurface.withValues(alpha: 0.85),
                        height: 1.6,
                        shadows: hasImage
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: (200 + i * 100).ms,
              duration: 400.ms,
            ).slideX(begin: 0.05, end: 0);
          })
        else
          Text(
            block.content,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: hasImage
                  ? Colors.white.withValues(alpha: 0.92)
                  : cs.onSurface.withValues(alpha: 0.85),
              height: 1.7,
              shadows: hasImage
                  ? [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        // Takeaway summary box (if block has takeaway field)
        if (block.takeaway != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: hasImage ? Colors.white.withValues(alpha: 0.7) : AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.takeaway!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasImage ? Colors.white : cs.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ],
    );
  }

  /// Extract bullet points from content text
  List<String> _extractPoints(String content) {
    // Split on newlines and filter empty lines
    final lines = content
        .split(RegExp(r'\n'))
        .map((l) => l.replaceFirst(RegExp(r'^[\s•\-–—\*]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return lines.length > 1 ? lines : [content];
  }
}
