import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Visual Reveal Widget - tap/long-press to reveal image overlay.
/// Features smooth fade animation.
/// Design inspired by the Figma visual_reveal_interaction template.
class VisualRevealWidget extends StatefulWidget {
  final String imageUrl;

  const VisualRevealWidget({super.key, required this.imageUrl});

  @override
  State<VisualRevealWidget> createState() => _VisualRevealWidgetState();
}

class _VisualRevealWidgetState extends State<VisualRevealWidget>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  bool _isRevealed = false;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isRevealed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isRevealed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isRevealed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPressStart: (_) {
        setState(() => _isRevealed = true);
        _controller.forward();
      },
      onLongPressEnd: (_) {
        setState(() => _isRevealed = false);
        _controller.reverse();
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.backgroundLight,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder/Button layer
            _buildRevealButton(),

            // Image layer (revealed on tap)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 48,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    ),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.backgroundLight.withValues(alpha: 0.6),
                            AppColors.backgroundLight.withValues(alpha: 0.2),
                            AppColors.backgroundLight.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Press to Imagine',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.inkLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hold to reveal visualization',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Full screen visual reveal overlay.
/// Used for larger image reveals with more dramatic animation.
class FullScreenVisualReveal extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final VoidCallback onClose;

  const FullScreenVisualReveal({
    super.key,
    required this.imageUrl,
    this.caption,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Stack(
          children: [
            // Image
            Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.5),
                      );
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

            // Caption
            if (caption != null)
              Positioned(
                bottom: 100,
                left: 24,
                right: 24,
                child: Text(
                      caption!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

            // Close hint
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap anywhere to close',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),

            // Close button
            Positioned(
              top: 60,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: onClose,
              ).animate().fadeIn(duration: 300.ms),
            ),
          ],
        ),
      ),
    );
  }
}
