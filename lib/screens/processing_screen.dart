import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/state.dart';
import '../services/services.dart';
import 'learning_feed_screen.dart';

/// Processing screen - shows while book is being processed.
/// Features animated loading indicator and progress text.
/// Design inspired by the Figma processing/_preparation_screen template.
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _currentStep = 0;

  final List<String> _processingSteps = [
    'Analyzing book structure...',
    'Extracting key concepts...',
    'Generating learning blocks...',
    'Creating visual summaries...',
    'Optimizing for your learning style...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Start processing after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startProcessing() async {
    final bookProvider = context.read<BookProvider>();
    final progressProvider = context.read<ReadingProgressProvider>();
    final apiConfig = context.read<ApiConfig>();

    // Check if we have uploaded content to process
    final hasUploadedContent = bookProvider.hasUploadedPdf;
    final isLiveMode = apiConfig.isConnected && !apiConfig.isDemoMode;

    if (hasUploadedContent && isLiveMode) {
      // Process uploaded PDF with real backend
      debugPrint('ProcessingScreen: Processing uploaded content with LIVE API');

      // Update steps for live processing
      setState(() {
        _currentStep = 0;
      });

      // Start actual processing in background
      final uploadPath = bookProvider.uploadedPdfPath ?? 'uploaded.txt';
      final uploadContent = bookProvider.uploadedPdfContent;

      // Process with API - this is handled in BookProvider
      await bookProvider.processUploadedPdf(
        uploadPath,
        textContent: uploadContent,
      );

      // Animate through remaining steps quickly
      for (int i = 0; i < _processingSteps.length; i++) {
        if (mounted) {
          setState(() => _currentStep = i);
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } else {
      // Demo mode - animate through steps and use mock book
      debugPrint('ProcessingScreen: Using DEMO mode');

      // Animate through processing steps
      for (int i = 0; i < _processingSteps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _currentStep = i;
          });
        }
      }
    }

    // Wait a bit more then navigate
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      if (bookProvider.currentBook != null) {
        progressProvider.initializeProgress(bookProvider.currentBook!);
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  const LearningFeedScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated loading indicator
              _buildLoadingIndicator()
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 1500.ms,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),

              const SizedBox(height: 48),

              // Main title
              Text(
                'Preparing Your Book',
                style: GoogleFonts.libreBaskerville(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkLight,
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 24),

              // Progress steps
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _processingSteps[_currentStep],
                  key: ValueKey(_currentStep),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Progress bar
              _buildProgressBar(),

              const SizedBox(height: 16),

              // Step indicator
              Text(
                '${_currentStep + 1} of ${_processingSteps.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),

              const Spacer(flex: 2),

              // Tip text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI is structuring this book for optimal learning',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.inkLight.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),

          // Inner ring
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: (_currentStep + 1) / _processingSteps.length,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),

          // Center icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _processingSteps.length;

    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
