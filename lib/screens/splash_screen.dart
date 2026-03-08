import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/services.dart';
import '../state/auth_provider.dart';
import '../state/book_provider.dart';
import '../state/bookmark_provider.dart';
import '../state/reading_progress_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _lineController;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _lineWidth;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _lineWidth = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _lineController, curve: Curves.easeOut));

    _bootstrapFuture = _prepareAuthState();
    _startSequence();
  }

  Future<void> _prepareAuthState() async {
    final apiConfig = context.read<ApiConfig>();
    final authProvider = context.read<AuthProvider>();

    await apiConfig.initializeWithFallback();
    authProvider.setApiConfig(apiConfig);
    await authProvider.initialize();

    if (!mounted || !authProvider.isAuthenticated) return;

    final bookProvider = context.read<BookProvider>();
    final progressProvider = context.read<ReadingProgressProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();

    bookProvider.setApiConfig(apiConfig);
    bookProvider.setTokenGetter(() => authProvider.idToken);
    progressProvider.setUserId(authProvider.userId);
    bookmarkProvider.setUserId(authProvider.userId);

    final progressClient = BackendApiClient(apiConfig);
    progressClient.setTokenGetter(() => authProvider.idToken);
    progressProvider.setApiClient(progressClient);
  }

  Future<void> _startSequence() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _lineController.forward();
    await Future.delayed(const Duration(milliseconds: 1100));

    if (mounted) {
      await _navigate();
    }
  }

  Future<void> _navigate() async {
    await _bootstrapFuture;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool('hasSeenOnboarding') ??
        prefs.getBool('onboarding_complete') ??
        false;

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;

    Widget destination;
    if (!hasSeenOnboarding) {
      destination = const OnboardingScreen();
    } else if (!isLoggedIn) {
      destination = const LoginScreen();
    } else {
      destination = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: SlideTransition(
                position: _logoSlide,
                child: Text(
                  'flashbook',
                  style: GoogleFonts.syne(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _lineWidth,
              builder:
                  (_, __) => Container(
                    width: 48 * _lineWidth.value,
                    height: 2,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

