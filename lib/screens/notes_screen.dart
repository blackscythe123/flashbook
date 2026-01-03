import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../state/state.dart';
import '../theme/app_colors.dart';
import '../widgets/note_input_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // We removed the 'initState' block because it causes crashes.
  // The code below handles everything automatically.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: AppColors.inkLight,
      ),
      backgroundColor: AppColors.backgroundLight,
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
                    // FIXED: Changed .withValues to .withOpacity
                    Icon(Icons.note_outlined, size: 64, color: AppColors.inkLight.withOpacity(0.3)),
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
                    // FIXED: Changed .withValues to .withOpacity
                    Icon(Icons.note_add_outlined, size: 64, color: AppColors.accentBlue.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No notes yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add notes while reading to see them here',
                      // FIXED: Changed .withValues to .withOpacity
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkLight.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteCard(context, noteProvider, note);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteProvider noteProvider, Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            Text(
              note.cardTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Note text
            Text(
              note.noteText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Metadata and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Saved ${_formatDate(note.updatedAt)}',
                    // FIXED: Changed .withValues to .withOpacity
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkLight.withOpacity(0.5),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: AppColors.accentBlue,
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

                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.red,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Note?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
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
                  ],
                ),
              ],
            ),
          ],
        ),
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