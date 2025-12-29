import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/api_config.dart';
import '../services/backend_api_client.dart';

/// Dialog for entering backend tunnel URL.
/// Shown on app start to configure API connection.
class BackendUrlDialog extends StatefulWidget {
  const BackendUrlDialog({super.key});

  @override
  State<BackendUrlDialog> createState() => _BackendUrlDialogState();
}

class _BackendUrlDialogState extends State<BackendUrlDialog> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isChecking = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with saved URL if exists
    final config = context.read<ApiConfig>();
    if (config.backendUrl != null) {
      _urlController.text = config.backendUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _useDemoMode();
      return;
    }

    // Validate URL format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _statusMessage = 'URL must start with http:// or https://';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking connection...';
      _isSuccess = false;
    });

    // Save URL and check connection
    final config = context.read<ApiConfig>();
    await config.setBackendUrl(url);

    final client = BackendApiClient(config);
    final isHealthy = await client.checkHealth();

    setState(() {
      _isChecking = false;
      if (isHealthy) {
        _statusMessage = '✓ Connected to backend!';
        _isSuccess = true;
      } else {
        _statusMessage = config.lastError ?? 'Failed to connect';
        _isSuccess = false;
      }
    });

    if (isHealthy) {
      // Wait a moment to show success message
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _useDemoMode() {
    final config = context.read<ApiConfig>();
    config.clearAndUseDemo();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
          backgroundColor: AppColors.paperLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backend Connection',
                            style: GoogleFonts.libreBaskerville(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connect to AI backend or use demo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // URL Input
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Tunnel URL',
                      hintText: 'https://your-tunnel.ngrok.io',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enabled: !_isChecking,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 12),

                // Status message
                if (_statusMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isSuccess
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (_isChecking)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _isSuccess
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 16,
                            color:
                                _isSuccess ? Colors.green : Colors.orange[700],
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  _isSuccess
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms),

                const SizedBox(height: 20),

                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to get a tunnel URL:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStep('1', 'Run backend: python main.py'),
                      _buildStep('2', 'Run ngrok: ngrok http 8080'),
                      _buildStep('3', 'Copy the https:// URL above'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Demo mode button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isChecking ? null : _useDemoMode,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColors.textMuted),
                        ),
                        child: Text(
                          'Use Demo',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Connect button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isChecking
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  'Connect',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the backend URL dialog
Future<bool?> showBackendUrlDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const BackendUrlDialog(),
  );
}
