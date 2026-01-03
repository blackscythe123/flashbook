import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dialog for inputting/editing notes on learning cards.
class NoteInputDialog extends StatefulWidget {
  final String cardTitle;
  final String? initialText;
  final Function(String) onSave;

  const NoteInputDialog({
    Key? key,
    required this.cardTitle,
    this.initialText,
    required this.onSave,
  }) : super(key: key);

  @override
  State<NoteInputDialog> createState() => _NoteInputDialogState();
}

class _NoteInputDialogState extends State<NoteInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Note'),
          const SizedBox(height: 8),
          Text(
            widget.cardTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkLight.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        maxLines: 6,
        minLines: 4,
        decoration: InputDecoration(
          hintText: 'Write your thoughts, key takeaways, or questions...',
          hintStyle: TextStyle(color: AppColors.inkLight.withValues(alpha: 0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accentBlue.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.inkLight.withValues(alpha: 0.6)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onSave(_controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save Note'),
        ),
      ],
    );
  }
}
