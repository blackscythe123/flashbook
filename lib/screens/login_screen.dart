import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;

  const LoginScreen({super.key, this.prefillEmail});

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
  bool _rememberMe = false;
  String? _pendingSignupEmail;
  String? _pendingSignupPassword;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    if (!remember || !mounted) return;

    setState(() {
      _rememberMe = true;
      _emailController.text = prefs.getString('saved_email') ?? '';
    });
  }

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
    late final bool success;

    if (_isSignUp) {
      success = await auth.createAccount(email, password);
      if (success) {
        _pendingSignupEmail = email;
        _pendingSignupPassword = password;
      }
    } else {
      success = await auth.signInWithEmail(email, password);
    }

    if (!mounted) return;

    if (!success) {
      final error = auth.errorMessage;
      if (error != null && error.isNotEmpty) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: GoogleFonts.plusJakartaSans()),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (_isSignUp && error == 'An account with this email already exists.') {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => LoginScreen(prefillEmail: email),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(code);
    if (!success || !mounted) return;

    final email = _pendingSignupEmail ?? auth.pendingVerificationEmail;
    final password = _pendingSignupPassword;

    if (email == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verified. Please sign in.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isSignUp = false;
        _codeController.clear();
      });
      return;
    }

    final signedIn = await auth.signInWithEmail(email, password);
    if (!mounted) return;

    if (!signedIn) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Could not sign in automatically.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: cs.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
    );
  }

  Widget _buildAuthForm(AuthProvider auth) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 40,
                  color: cs.onPrimary,
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
              color: cs.onSurface,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            _isSignUp ? 'Create your account to get started' : 'Welcome back',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: cs.outline,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 36),

          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.outline.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
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

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                      decoration: _inputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: cs.secondary,
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

                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (_) => setState(() => _rememberMe = !_rememberMe),
                        ),
                        Text(
                          'Remember me',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: cs.secondary,
                          ),
                        ),
                      ],
                    ),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorBanner(auth.errorMessage!),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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

          TextButton(
            onPressed: () {
              auth.clearError();
              setState(() => _isSignUp = !_isSignUp);
            },
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _isSignUp
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.outline,
                    ),
                  ),
                  TextSpan(
                    text: _isSignUp ? 'Sign In' : 'Sign Up',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(AuthProvider auth) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: Color(0xFF22C55E),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 20),
        Text(
          'Check your email',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to',
          style: GoogleFonts.inter(fontSize: 14, color: cs.outline),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 2),
        Text(
          auth.pendingVerificationEmail ?? '',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 28),

        Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: cs.outline.withValues(alpha: 0.2),
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
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 12,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 12,
                        color: cs.outline.withValues(alpha: 0.3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                      child: auth.isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text(
                              'Verify & Continue',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.primary,
            ),
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
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: cs.outline,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: cs.outline,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: cs.secondary, size: 20),
      prefixIconColor: cs.secondary,
      suffixIconColor: cs.secondary,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildErrorBanner(String message) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.error,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
