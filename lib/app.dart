import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
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
        ChangeNotifierProvider(create: (_) => ApiConfig()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => BookProvider()..initialize()),
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

/// App initializer - handles auth state, API config, and initial navigation.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _showUrlDialog = true;
  bool _dialogShowing = false; // Prevent multiple dialogs

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

      // Load any saved API URL
      await apiConfig.loadSavedUrl();

      // Connect BookProvider to ApiConfig
      bookProvider.setApiConfig(apiConfig);

      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onDialogComplete(bool? usedLiveMode) {
    if (mounted) {
      setState(() {
        _showUrlDialog = false;
        _dialogShowing = false;
      });

      // Update book provider with API config
      final apiConfig = context.read<ApiConfig>();
      final bookProvider = context.read<BookProvider>();
      bookProvider.setApiConfig(apiConfig);
    }
  }

  void _showDialog() {
    if (_dialogShowing) return; // Prevent multiple dialogs
    _dialogShowing = true;
    showBackendUrlDialog(context).then(_onDialogComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ApiConfig>(
      builder: (context, authProvider, apiConfig, child) {
        // Show loading while auth is initializing
        if (authProvider.isLoading || !_isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show URL dialog on first launch
        if (_showUrlDialog) {
          return Scaffold(
            body: Builder(
              builder: (context) {
                // Show dialog after build - use the guard method
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_showUrlDialog && !_dialogShowing) {
                    _showDialog();
                  }
                });

                return Container(
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
                );
              },
            ),
          );
        }

        // Show entry screen
        return const EntryScreen();
      },
    );
  }
}
