import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'state/state.dart';
import 'screens/screens.dart';
import 'services/services.dart';

/// Main App widget - root of the application.
/// Sets up Material theme, providers, and routing.
class FlashbookApp extends StatelessWidget {
  const FlashbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ApiConfig()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ReadingProgressProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Flashbook',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

/// App initializer - handles API config, auth state, and initial navigation.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (mounted) {
      final apiConfig = context.read<ApiConfig>();
      final authProvider = context.read<AuthProvider>();
      final bookProvider = context.read<BookProvider>();
      final progressProvider = context.read<ReadingProgressProvider>();
      final bookmarkProvider = context.read<BookmarkProvider>();

      // 1. Connect to backend
      await apiConfig.initializeWithFallback();

      // 2. Wire auth → providers
      authProvider.setApiConfig(apiConfig);
      bookProvider.setApiConfig(apiConfig);

      // 3. Try restoring previous session
      await authProvider.initialize();

      // 4. If authenticated, wire tokens into API clients
      if (authProvider.isAuthenticated) {
        _wireAuth(
          authProvider,
          bookProvider,
          progressProvider,
          bookmarkProvider,
          apiConfig,
        );
      }

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  void _wireAuth(
    AuthProvider auth,
    BookProvider bookProvider,
    ReadingProgressProvider progressProvider,
    BookmarkProvider bookmarkProvider,
    ApiConfig apiConfig,
  ) {
    bookProvider.setTokenGetter(() => auth.idToken);
    progressProvider.setUserId(auth.userId);
    bookmarkProvider.setUserId(auth.userId);

    // Give progress provider its own API client for syncing
    final progressClient = BackendApiClient(apiConfig);
    progressClient.setTokenGetter(() => auth.idToken);
    progressProvider.setApiClient(progressClient);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ApiConfig>(
      builder: (context, authProvider, apiConfig, child) {
        // Still loading
        if (!_isInitialized || apiConfig.isChecking) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Auth loading
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not authenticated → onboarding or login
        if (!authProvider.isAuthenticated) {
          if (!_onboardingComplete) {
            return const OnboardingScreen();
          }
          return const LoginScreen();
        }

        // Wire auth on login (in case state changed)
        final bookProvider = context.read<BookProvider>();
        final progressProvider = context.read<ReadingProgressProvider>();
        final bookmarkProvider = context.read<BookmarkProvider>();
        _wireAuth(
          authProvider,
          bookProvider,
          progressProvider,
          bookmarkProvider,
          apiConfig,
        );

        // Authenticated → home with bottom nav
        return const HomeScreen();
      },
    );
  }
}
