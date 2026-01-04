import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'state/state.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

/// Main App widget - root of the application.
/// Sets up Material theme, providers, and routing.
class FlashbookApp extends StatelessWidget {
  const FlashbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Setup all state providers
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ApiConfig()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
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

            // Theme configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Initial route
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

/// App initializer - handles auth state, API config, and initial navigation.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for auth to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      final progressProvider = context.read<ReadingProgressProvider>();
      final bookmarkProvider = context.read<BookmarkProvider>();
      final apiConfig = context.read<ApiConfig>();
      final bookProvider = context.read<BookProvider>();

      // Initialize demo data
      progressProvider.setUserId(authProvider.userId);
      bookmarkProvider.setUserId(authProvider.userId);

      // Attempt Connection to Prod URL (with Fallback)
      await apiConfig.initializeWithFallback();

      // Connect BookProvider to ApiConfig
      bookProvider.setApiConfig(apiConfig);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ApiConfig>(
      builder: (context, authProvider, apiConfig, child) {
        // Show loading while auth is initializing or API is checking
        if (authProvider.isLoading || !_isInitialized || apiConfig.isChecking) {
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

        // Show entry screen directly
        return const EntryScreen();
      },
    );
  }
}
