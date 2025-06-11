import 'package:flutter/material.dart';
import 'package:dis/firestore_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// A dialog widget used to collect anonymous lab session feedback
/// from students.
///
/// The dialog allows users to:
/// - Select lab difficulty using chips (Easy, Medium, Hard)
/// - Rate quality of assistance and waiting time using star rating bars
/// - Optionally leave written comments
///
/// Submits the collected feedback to Firestore using FirestoreService.
/// Intended to be shown at the end of session to help gather user insights.

class FeedbackDialog extends StatefulWidget {

  final String sessionId;
  const FeedbackDialog({super.key, required this.sessionId});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  double _assistanceRating = 0;
  double _waitingRating = 0;
  final TextEditingController _commentController = TextEditingController();
  String? _labDifficulty;

  final FirestoreService _firestoreService = FirestoreService();

  // Method to submit Feedback to database
  void _submitFeedback() async{
    String comment = _commentController.text.trim();
    print("Session ID used for Feedback: ${widget.sessionId}");

    await _firestoreService.uploadFeedback(
      widget.sessionId, _labDifficulty!, _assistanceRating,
        _waitingRating, comment
    );
  }

  //Star Rating
  Widget buildRatingBar(double value, void Function(double) onUpdate) {
    return RatingBar.builder(
      initialRating: 0,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: Colors.orangeAccent,
      ),
      onRatingUpdate: onUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Lab Feedback"),
      content:SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Feedback is completely anonymous!"),
            Text("How was lab task? "),
            Wrap(
                spacing: 8.0,
                children: ["Easy", "Medium", "Hard"].map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: _labDifficulty == option,
                    onSelected: (_) {
                      setState(() {
                        _labDifficulty = option;
                      });
                    },
                  );
                }).toList(),
            ),

            Text("How was the quality of assistance provided"),
            //Star Rating
            Center(
              child: buildRatingBar(_assistanceRating, (value) {
                setState(() => _assistanceRating = value);
              })
            ),

            Text("Rate your waiting times"),
            //Star Rating
            Center(
                child: buildRatingBar(_waitingRating, (value) {
                  setState(() => _waitingRating = value);
                })
            ),

            Text("Comments:"),
            //Additional Comments
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Write your comments here .....",
                border: OutlineInputBorder(),
              ),

            )
          ],
        ),
      ),

      //Buttons: Skip & Submit
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); //Close dialog
          },
          child: Text("Skip"),
        ),
        ElevatedButton(
          onPressed: () {
            _submitFeedback();
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(
                content: Text("Thank you for your Feedback!")));
            // Navigator.pop(context);
          },
          child: Text("Submit"),
        )
      ]
    );
  }

}