import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A custom dialog widget used to create a new lab support session
///
/// This widget displays a modal dialog where a lecturer can input a
/// session name for a selected module. Upon confirmation, the session
/// is saved to Firestore with a randomly generated 6-digit session code

class CreateSessionDialog extends StatelessWidget {
  final String lecturerId;
  final String moduleName;
  CreateSessionDialog({super.key,
    required this.lecturerId, required this.moduleName});

  final TextEditingController _sessionNameController = TextEditingController();

  //Generate random 6-digit code
  String _generateSessionCode() {
    var random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  //Create a new session
  Future<void> _createSession() async {
    String sessionCode = _generateSessionCode();

    await FirebaseFirestore.instance.collection('sessions').add({
      'sessionName': _sessionNameController.text,
      'sessionCode': sessionCode,
      'createdFor': moduleName,
      'lecturerId': lecturerId,
      'status': 'open', //initially open
      'createdAt': Timestamp.now(),
      'studentQueue': [],
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
            Text(
              "Create New Session",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20,),
            TextField(
              controller: _sessionNameController,
              decoration: InputDecoration(
                labelText: "Session Name",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                //Cancel Button
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: Text("Cancel"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                    onPressed: ()  {
                       _createSession();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Session Created Successfully"))
                      );
                      //Close Dialog after success
                      Navigator.of(context).pop();
                    },
                    child: Text("Create"),

                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
