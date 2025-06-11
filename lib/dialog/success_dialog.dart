import 'package:flutter/material.dart';

/// A custom success dialog that displays a confirmation message with a
/// checkmark icon.
///
/// This dialog is automatically dismissed after 1.5 seconds using a delayed
/// function in the 'initState' method.
///
/// The message displayed is passed in via the [message] parameter.

class SuccessDialog extends StatefulWidget {
  final String message;

  const SuccessDialog({super.key, required this.message});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog after 1.5s
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // SizedBox(height: 5),
            // Text("Request marked as attended."),
          ],
        ),
      ),
    );
  }
}

