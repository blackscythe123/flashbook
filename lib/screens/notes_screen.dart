import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../state/state.dart';
import '../theme/app_colors.dart';
import '../widgets/note_input_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: GoogleFonts.libreBaskerville(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer2<NoteProvider, BookProvider>(
        builder: (context, noteProvider, bookProvider, child) {
          final currentBook = bookProvider.currentBook;

          if (currentBook == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No book selected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final notes = noteProvider.getNotesForBook(currentBook.id);

          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.note_add_outlined,
                        size: 48,
                        color: AppColors.accentBlue.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No notes yet',
                      style: GoogleFonts.libreBaskerville(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add notes while reading to see them here',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return _buildNoteCard(context, noteProvider, notes[index])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: index * 60), duration: 300.ms)
                  .slideY(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteProvider noteProvider, Note note) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.cardTitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Note text
          Text(
            note.noteText,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          // Metadata and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(note.updatedAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Edit button
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.accentBlue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => NoteInputDialog(
                            cardTitle: note.cardTitle,
                            initialText: note.noteText,
                            onSave: (newText) {
                              if (newText.isNotEmpty) {
                                noteProvider.updateNote(note.id, newText);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Note updated')),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Delete button
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: cs.error),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Delete Note?',
                              style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.w600),
                            ),
                            content: Text(
                              'This action cannot be undone.',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: cs.error),
                                onPressed: () {
                                  noteProvider.deleteNote(note.id);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Note deleted')),
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}