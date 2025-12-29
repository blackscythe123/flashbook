import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Lyric Flow Widget - Displays text like song lyrics flowing on screen.
/// Each line appears with a staggered animation, creating an immersive
/// reading experience similar to how lyrics appear in music apps.
class LyricFlowWidget extends StatefulWidget {
  final String text;
  final Color? textColor;
  final Duration lineDuration;
  final Duration lineDelay;
  final TextAlign textAlign;
  final double fontSize;
  final bool hasImageBackground;

  const LyricFlowWidget({
    super.key,
    required this.text,
    this.textColor,
    this.lineDuration = const Duration(milliseconds: 400),
    this.lineDelay = const Duration(milliseconds: 150),
    this.textAlign = TextAlign.center,
    this.fontSize = 18,
    this.hasImageBackground = false,
  });

  @override
  State<LyricFlowWidget> createState() => _LyricFlowWidgetState();
}

class _LyricFlowWidgetState extends State<LyricFlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> _lines;
  int _currentLineIndex = 0;
  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();
    _parseText();
    _controller = AnimationController(
      vsync: this,
      duration: _calculateTotalDuration(),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isAnimating = false);
      }
    });

    _startAnimation();
  }

  void _parseText() {
    // Split text into meaningful lines (by sentence or ~10 words)
    final sentences = widget.text.split(RegExp(r'(?<=[.!?])\s+'));
    _lines = [];

    for (final sentence in sentences) {
      final words = sentence.split(' ');
      if (words.length > 12) {
        // Split long sentences into chunks
        for (var i = 0; i < words.length; i += 8) {
          final end = (i + 8 > words.length) ? words.length : i + 8;
          _lines.add(words.sublist(i, end).join(' '));
        }
      } else {
        _lines.add(sentence);
      }
    }
  }

  Duration _calculateTotalDuration() {
    final totalMs =
        _lines.length *
        (widget.lineDuration.inMilliseconds + widget.lineDelay.inMilliseconds);
    return Duration(milliseconds: totalMs + 1000);
  }

  void _startAnimation() {
    _controller.forward();
    _animateLines();
  }

  void _animateLines() async {
    for (var i = 0; i < _lines.length; i++) {
      if (!mounted) return;
      await Future.delayed(widget.lineDelay);
      if (mounted) {
        setState(() => _currentLineIndex = i);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricFlowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _parseText();
      _currentLineIndex = 0;
      _isAnimating = true;
      _controller.reset();
      _controller.duration = _calculateTotalDuration();
      _startAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.textColor ?? AppColors.inkLight.withValues(alpha: 0.85);

    // Text shadows for image backgrounds
    final textShadows =
        widget.hasImageBackground
            ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ]
            : <Shadow>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Animated lines
        ...List.generate(_lines.length, (index) {
          final isVisible = index <= _currentLineIndex;
          final isCurrent = index == _currentLineIndex && _isAnimating;

          return AnimatedOpacity(
            duration: widget.lineDuration,
            opacity: isVisible ? 1.0 : 0.0,
            child: AnimatedSlide(
              duration: widget.lineDuration,
              offset: isVisible ? Offset.zero : const Offset(0, 0.3),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _lines[index],
                  textAlign: widget.textAlign,
                  style: GoogleFonts.libreBaskerville(
                    fontSize: widget.fontSize,
                    color:
                        isCurrent
                            ? textColor
                            : textColor.withValues(
                              alpha: isVisible ? 0.7 : 0.0,
                            ),
                    height: 1.8,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    shadows: textShadows,
                  ),
                ),
              ),
            ),
          );
        }),

        // Show "tap to see all" hint if animation is in progress
        if (_isAnimating)
          GestureDetector(
            onTap: () {
              setState(() {
                _currentLineIndex = _lines.length - 1;
                _isAnimating = false;
              });
            },
            child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Tap to reveal all',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                      shadows: textShadows,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 500.ms)
                .then()
                .fadeOut(duration: 500.ms),
          ),
      ],
    );
  }
}

/// Simplified version for preview without animation
class LyricFlowPreview extends StatelessWidget {
  final String text;
  final Color? textColor;
  final double fontSize;

  const LyricFlowPreview({
    super.key,
    required this.text,
    this.textColor,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.inkLight.withValues(alpha: 0.85);

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.libreBaskerville(
        fontSize: fontSize,
        color: color,
        height: 1.8,
      ),
    );
  }
}
