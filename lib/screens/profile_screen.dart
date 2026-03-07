import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../state/state.dart';
import 'settings_screen.dart';

/// Profile screen — user stats, reading activity, and settings access.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, size: 24),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Avatar + info
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(auth.user?.email),
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      auth.user?.email ?? 'Reader',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.user?.isPremium == true ? 'Premium' : 'Free Plan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Stats row
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(value: '0', label: 'Books'),
                    Container(
                      width: 1,
                      height: 36,
                      color: cs.outlineVariant,
                    ),
                    _StatItem(value: '0', label: 'Cards Read'),
                    Container(
                      width: 1,
                      height: 36,
                      color: cs.outlineVariant,
                    ),
                    _StatItem(value: '0h', label: 'Time'),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 24),

              // Activity section
              Text(
                'Activity',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 12),

              // Reading streak card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.accentGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '0 Day Streak',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Start reading to build your streak!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 16),

              // Weekly goal card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weekly Goal',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '0 / 50 cards',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0,
                        minHeight: 8,
                        backgroundColor: cs.outlineVariant,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 32),

              // Quick actions
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.dark_mode_rounded,
                label: 'Dark Mode',
                trailing: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Switch(
                    value: theme.isDarkMode,
                    onChanged: (v) => theme.toggleTheme(v),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 8),

              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                onTap: () async {
                  await context.read<AuthProvider>().signOut();
                },
              ).animate().fadeIn(delay: 550.ms, duration: 400.ms),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String? email) {
    if (email == null || email.isEmpty) return 'R';
    return email[0].toUpperCase();
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, size: 22),
        title: Text(
          label,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
