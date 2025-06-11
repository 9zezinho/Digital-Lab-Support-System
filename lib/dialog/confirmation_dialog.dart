import 'package:flutter/material.dart';

/// A reusable confirmation dialog widget for displaying yes/no
/// or confirm/cancel prompts.
///
/// This stateless widget creates a styled 'AlertDialog' with a title,
/// content message, and two action buttons (confirm and cancel).
///
/// This dialog features
/// - Customizable title, content, and button labels,
/// - Executes a user-defined 'onConfirm' callback when the button is pressed
/// - Automatically closes the dialog when either button is tapped.

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
           Navigator.of(context).pop();
           onConfirm();
          },
          child: Text(confirmText),
        )
      ]
    );
  }

}