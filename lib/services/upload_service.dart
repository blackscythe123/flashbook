import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../screens/processing_screen.dart';
import '../state/book_provider.dart';

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
    if (file.path == null && file.bytes == null) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Uploading ${file.name}...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final bookProvider = context.read<BookProvider>();
    await bookProvider.uploadPdfToS3(
      bytes: file.bytes ?? const <int>[],
      filename: file.name,
      title: file.name.replaceAll('.pdf', ''),
    );

    if (!context.mounted) return;

    if (bookProvider.currentBookId == null) {
      final message =
          bookProvider.errorMessage ?? 'Could not process selected PDF.';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $message',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: cs.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final uploadedBookId = bookProvider.currentBookId!;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF22C55E),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'Upload complete! Processing...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) => ProcessingScreen(
              bookId: uploadedBookId,
              fileName: file.name,
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
