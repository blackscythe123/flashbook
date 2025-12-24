import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/state.dart';
import 'screens/screens.dart';

/// Main App widget - root of the application.
/// Sets up Material theme, providers, and routing.
class FlashbookApp extends StatelessWidget {
  const FlashbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Setup all state providers
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProgressProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: MaterialApp(
        title: 'Flashbook',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Force light theme for demo
        // Initial route
        home: const AppInitializer(),
      ),
    );
  }
}

/// App initializer - handles auth state and initial navigation.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
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

      // Initialize demo data
      progressProvider.setUserId(authProvider.userId);
      bookmarkProvider.setUserId(authProvider.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while auth is initializing
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Always show entry screen for hackathon demo
        return const EntryScreen();
      },
    );
  }
}
