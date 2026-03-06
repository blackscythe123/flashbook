import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      await auth.createAccount(email, password);
    } else {
      await auth.signInWithEmail(email, password);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(code);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verified! Please sign in.', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _isSignUp = false;
        _codeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, const Color(0xFF1A1040)]
                : [AppColors.paperLight, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.authState == AuthState.needsVerification) {
                    return _buildVerificationForm(auth);
                  }
                  return _buildAuthForm(auth);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 40,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 20),

          Text(
            'Flashbook',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.inkLight,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            _isSignUp ? 'Create your account to get started' : 'Welcome back',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted, height: 1.4),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 36),

          // Form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: Colors.white.withOpacity(0.06)) : null,
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : AppColors.inkLight),
                  decoration: _inputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : AppColors.inkLight),
                  decoration: _inputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (_isSignUp && v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                // Error
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(auth.errorMessage!),
                ],

                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            _isSignUp ? 'Create Account' : 'Sign In',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 250.ms, duration: 500.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 20),

          // Toggle
          TextButton(
            onPressed: () {
              auth.clearError();
              setState(() => _isSignUp = !_isSignUp);
            },
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                ),
                TextSpan(
                  text: _isSignUp ? 'Sign In' : 'Sign Up',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ]),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accentSage.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.accentSage),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 20),
        Text(
          'Check your email',
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.inkLight),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 2),
        Text(
          auth.pendingVerificationEmail ?? '',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.inkLight),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 28),

        // Code card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: Colors.white.withOpacity(0.06)) : null,
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 12,
                  color: isDark ? Colors.white : AppColors.inkLight,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 12,
                    color: AppColors.textMuted.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(auth.errorMessage!),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text('Verify & Continue',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 250.ms, duration: 500.ms)
            .slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            auth.clearError();
            auth.resetToLogin();
          },
          child: Text(
            'Back to Sign In',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.error, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
