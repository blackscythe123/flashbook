import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/processing_screen.dart';

Future<void> pickAndUploadPDF(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    // On web, accessing file.path throws — check bytes only on web
    if (kIsWeb ? file.bytes == null : (file.path == null && file.bytes == null))
      return;
    if (!context.mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) =>
                ProcessingScreen(fileBytes: file.bytes, fileName: file.name),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: ${e.toString()}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: cs.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
