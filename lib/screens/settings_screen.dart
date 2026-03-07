import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../state/state.dart';
import '../services/services.dart';

/// Settings screen — app configuration, account, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
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
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.secondary,
            title: 'Dark Mode',
            subtitle: 'Easier on the eyes at night',
            trailing: Consumer<ThemeProvider>(
              builder: (ctx, theme, _) => Switch(
                value: theme.isDarkMode,
                onChanged: (v) => theme.toggleTheme(v),
                activeThumbColor: AppColors.primary,
              ),
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Account section
          _SectionHeader(title: 'Account')
              .animate().fadeIn(delay: 120.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            title: 'Account Info',
            subtitle: context.watch<AuthProvider>().user?.email ?? 'Not signed in',
          ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            iconColor: AppColors.accentBlue,
            title: 'Backend Status',
            subtitle: context.watch<ApiConfig>().isDemoMode ? 'Demo Mode' : 'Connected',
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.watch<ApiConfig>().isDemoMode
                    ? AppColors.warning
                    : AppColors.success,
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
            iconColor: AppColors.textMuted,
            title: 'Version',
            subtitle: '0.1.0',
          ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.code_rounded,
            iconColor: AppColors.textMuted,
            title: 'Built with',
            subtitle: 'Flutter + AI',
          ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // Sign out
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withOpacity(0.15)),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Icon(Icons.logout_rounded, size: 22, color: AppColors.error),
              title: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
              onTap: () async {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) Navigator.of(context).pop();
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
          color: AppColors.textMuted,
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
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
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
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: trailing,
      ),
    );
  }
}
