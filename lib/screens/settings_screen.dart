import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

/// Settings screen for app configuration.
/// Allows users to toggle dark mode and other app settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between light and dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (isDark) {
                  themeProvider.toggleTheme(isDark);
                },
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
