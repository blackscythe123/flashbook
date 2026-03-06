import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

/// 3-page onboarding flow shown on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.auto_stories_rounded,
      iconGradient: [AppColors.primary, AppColors.secondary],
      title: 'Books as Reels',
      subtitle: 'Swipe through bite-sized learning cards\ncreated by AI from any book or PDF.',
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      iconGradient: [AppColors.accentGold, AppColors.accentClay],
      title: 'Learn in Seconds',
      subtitle: 'Key insights, quotes, and takeaways\ndelivered one card at a time.',
    ),
    _OnboardingPage(
      icon: Icons.bookmark_rounded,
      iconGradient: [AppColors.accentSage, Color(0xFF34D399)],
      title: 'Save What Matters',
      subtitle: 'Bookmark cards, add notes,\nand revisit your highlights anytime.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.backgroundDark, const Color(0xFF1A1040)]
                : [AppColors.backgroundLight, const Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildPage(page, index);
                  },
                ),
              ),

              // Dots + Button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: page.iconGradient.first.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(page.icon, size: 52, color: Colors.white),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 700.ms),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textMuted,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('sub_$index'))
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(begin: 0.15),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
  });
}
