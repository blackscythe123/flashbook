import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../state/state.dart';
import '../services/services.dart';
import 'login_screen.dart';

/// Settings screen — app configuration, account, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Appearance section
          _SectionHeader(title: 'Appearance')
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            themeProvider.isDarkMode
                                ? 'Dark mode'
                                : 'Light mode',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              );
            },
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Account section
          _SectionHeader(title: 'Account')
              .animate().fadeIn(delay: 120.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: Theme.of(context).colorScheme.primary,
            title: 'Account Info',
            subtitle: context.watch<AuthProvider>().user?.email ?? 'Not signed in',
          ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            title: 'Backend Status',
            subtitle: context.watch<ApiConfig>().isConnected ? 'Connected' : 'Disconnected',
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    context.watch<ApiConfig>().isConnected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // About section
          _SectionHeader(title: 'About')
              .animate().fadeIn(delay: 240.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: Theme.of(context).colorScheme.outline,
            title: 'Version',
            subtitle: '0.1.0',
          ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.code_rounded,
            iconColor: Theme.of(context).colorScheme.outline,
            title: 'Built with',
            subtitle: 'Flutter + AI',
          ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // Sign out
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.15)),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Icon(Icons.logout_rounded, size: 22, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () async {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionDuration: const Duration(milliseconds: 400),
                      transitionsBuilder:
                          (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ).animate().fadeIn(delay: 360.ms, duration: 400.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
        trailing: trailing,
      ),
    );
  }
}

