import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/processing_screen.dart';
import '../state/book_provider.dart';
import '../theme/app_colors.dart';

Future<void> pickAndUploadPDF(BuildContext context) async {
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

    final bookProvider = context.read<BookProvider>();
    await bookProvider.uploadPdf(
      path: file.path,
      bytes: file.bytes,
      filename: file.name,
    );

    if (!context.mounted) return;

    if (!bookProvider.hasUploadedPdf) {
      final message =
          bookProvider.errorMessage ?? 'Could not process selected PDF.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.surface),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProcessingScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file picker: $e'),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }
}
