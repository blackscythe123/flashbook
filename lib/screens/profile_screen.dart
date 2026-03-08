import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../state/state.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Profile screen — user stats, reading activity, and settings access.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _requestedBooks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedBooks) return;
      _requestedBooks = true;
      context.read<BookProvider>().fetchBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final books = context.watch<BookProvider>().userBooks;
    final progress = context.watch<ReadingProgressProvider>();

    final bookCount = books.length;
    final cardsRead = progress.totalCardsRead;
    final minutesRead = (cardsRead * 0.5).round();
    final timeDisplay =
        minutesRead >= 60
            ? '${(minutesRead / 60).toStringAsFixed(1)}h'
            : '${minutesRead}m';

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
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
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
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(auth.user?.email),
                          style: GoogleFonts.syne(
                            fontSize: 32,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.user?.isPremium == true ? 'Premium' : 'Free Plan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
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
                      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDark
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
                                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(value: '$bookCount', label: 'Books'),
                        Container(
                          width: 1,
                          height: 36,
                          color:
                              isDark
                                  ? Theme.of(context).colorScheme.onSurface.withValues(
                                    alpha: 0.08,
                                  )
                                  : Theme.of(context).colorScheme.surface.withValues(
                                    alpha: 0.06,
                                  ),
                        ),
                        _StatItem(value: '$cardsRead', label: 'Cards Read'),
                        Container(
                          width: 1,
                          height: 36,
                          color:
                              isDark
                                  ? Theme.of(context).colorScheme.onSurface.withValues(
                                    alpha: 0.08,
                                  )
                                  : Theme.of(context).colorScheme.surface.withValues(
                                    alpha: 0.06,
                                  ),
                        ),
                        _StatItem(value: timeDisplay, label: 'Time'),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.05),

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
                      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDark
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
                                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFF59E0B),
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
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Start reading to build your streak!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: 16),

              // Weekly goal card
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDark
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
                                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
                      ),
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
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '0 / 50 cards',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.secondary,
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
                            backgroundColor:
                                isDark
                                    ? Theme.of(context).colorScheme.onSurface.withValues(
                                      alpha: 0.06,
                                    )
                                    : Theme.of(context).colorScheme.surface.withValues(
                                      alpha: 0.06,
                                    ),
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.05),

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

              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  final isDarkMode = themeProvider.isDarkMode;
                  return GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outline, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDarkMode ? 'Dark Mode' : 'Light Mode',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  isDarkMode
                                      ? 'Tap to switch to light'
                                      : 'Tap to switch to dark',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: cs.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? const Color(0xFF1A1A1A)
                                      : const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? const Color(0xFFC41E24)
                                        : const Color(0xFF0B3061),
                                width: 1.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  alignment:
                                      isDarkMode
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? const Color(0xFFC41E24)
                                              : const Color(0xFF0B3061),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isDarkMode
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 8),

              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
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
          style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, size: 22),
        title: Text(
          label,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}

