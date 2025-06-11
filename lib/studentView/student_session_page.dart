import 'package:dis/dialog/feedback_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dis/firestore_service.dart';
import 'package:intl/intl.dart';

/// This class represents the session page for a student user.
///
/// It allows the student to :
/// - Join and interact with a session's queue,
/// - Submit a request for "assistance" (with a message and optional code) or
/// "sign-off"
/// - View their active requests, including position in the queue and request time
/// - Expand and collapse their code snippets for better readability
/// - Receive and respond to feedback prompts triggered by the system

class StudentSessionPage extends StatefulWidget {
  final String sessionId;

  const StudentSessionPage({super.key, required this.sessionId});

  @override
  State<StudentSessionPage> createState() => _StudentSessionPageState();
}

class _StudentSessionPageState extends State<StudentSessionPage> {
  bool _isRequesting = false;
  String _selectedRequestType = "sign-off";
  String _codeSnippet = ""; //Store student's pasted code
  String _issuedMessage = "";

  // bool feedbackDialogShown = false;
  String _requestId = "";

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  //Create a map to store the "Show full Code" state for each student
  Map<String, bool> showFullCodeMap = {};

  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? lastSubmittedRequestId; // Store latest sign-off request

  //Request Assistance or Sign-OFf
  Future<void> _requestHelp() async {
    setState(() {
      _isRequesting = true;
    });
    try {
      //Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      //Get the 'fullName' field,
      String userName = userDoc.exists && userDoc.data() != null
          ? (userDoc['fullName'] ?? "Student")
          : "Student";

      //Generate Firestore Auto-ID by adding a document to the subcollection
      DocumentReference requestRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('requests')
          .doc();

      _requestId = requestRef.id;

      setState(() {
        lastSubmittedRequestId = _requestId;
      });

      //Add the info inside the studentQueue
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({
        "studentQueue": FieldValue.arrayUnion([
          {
            "uid": currentUserId,
            "name": userName,
            "requestType": _selectedRequestType,
            "requestedAt": Timestamp.now(),
            "requestId": _requestId,
            "codeSnippet":
                _selectedRequestType == "assistance" ? _codeSnippet : "",
            "issueMessage":
                _selectedRequestType == "assistance" ? _issuedMessage : "",
          }
        ])
      });

      setState(() {
        _isRequesting = false;
        _codeController.clear(); //Clear after submission
        _messageController.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Request Submitted')));
    } catch (e) {
      print("Error fetching user fullName: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Session Queue')),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                //Fetch the session name and display
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestoreService.fetchSessionQueue(widget.sessionId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error}"),
                      );
                    }

                    var sessionData =
                        snapshot.data?.data() as Map<String, dynamic>;

                    String sessionName =
                        sessionData['sessionName'] ?? "Session Name here";

                    //Extract Feedback triggers
                    var feedbackTriggers =
                        sessionData["feedbackTriggers"] ?? {};
                    var trigger = feedbackTriggers[currentUserId];

                    if (trigger != null && trigger["showDialog"] == true) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => FeedbackDialog(
                            sessionId: widget.sessionId,
                          ),
                        );
                      });

                      //Update the flag to false
                      _firestoreService.makeDialogFalse(
                        widget.sessionId,
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          "Session: $sessionName",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),

                DropdownButton<String>(
                  value: _selectedRequestType,
                  items: [
                    DropdownMenuItem(
                        value: "sign-off", child: Text("Request Sign-off")),
                    DropdownMenuItem(
                        value: "assistance", child: Text("Request Assistance")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRequestType = value!;
                    });
                  },
                ),
                const SizedBox(
                  height: 05,
                ),

                //Short message input
                if (_selectedRequestType == "assistance")
                  TextField(
                    controller: _messageController,
                    onChanged: (value) => _issuedMessage = value,
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: "Write your issue in short",
                      border: OutlineInputBorder(),
                    ),
                  ),

                //TextField (only for assistance req)
                if (_selectedRequestType == "assistance")
                  SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        child: TextFormField(
                          controller: _codeController,
                          onChanged: (value) => _codeSnippet = value,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            labelText: "Your Code Here",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )),

                //Submit request button
                ElevatedButton(
                  onPressed: _isRequesting
                      ? null
                      : () {
                          FocusScope.of(context).unfocus(); //close Keyboard
                          _requestHelp();
                        },
                  child: _isRequesting
                      ? CircularProgressIndicator()
                      : Text("Submit Request"),
                ),
                const SizedBox(
                  height: 10,
                ),

                Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: _firestoreService
                            .fetchSessionQueue(widget.sessionId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }
                          var sessionData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          List studentQueue = sessionData['studentQueue'] ?? [];

                          if (studentQueue.isEmpty) {
                            return Center(child: Text("No requests yet"));
                          }

                          //Find the current user's requests
                          List myRequests = studentQueue
                              .where(
                                  (student) => student['uid'] == currentUserId)
                              .toList();

                          if (myRequests.isEmpty) {
                            return Center(
                                child: Text("You have no active requests"));
                          }

                          return ListView.builder(
                              itemCount: myRequests.length,
                              itemBuilder: (context, index) {
                                var student = myRequests[index];
                                //Find the pos in queue
                                int pos = studentQueue.indexWhere((s) =>
                                        s['requestId'] ==
                                        student['requestId']) +
                                    1;

                                DateTime requestTime =
                                    student['requestedAt'].toDate();
                                String formattedTime =
                                    DateFormat('hh:mm a').format(requestTime);

                                // Only show code snippet for "assistance" requests
                                String previewCode = "";

                                // Safely check for null values in codeSnippet
                                if (student['requestType'] == 'assistance' &&
                                    student['codeSnippet'] != null &&
                                    student['codeSnippet'].isNotEmpty) {
                                  List<String> codeLines =
                                      student['codeSnippet']
                                          .toString()
                                          .split('\n');
                                  previewCode = codeLines.length > 3
                                      ? "${codeLines.take(3).join('\n')}\n..."
                                      : student['codeSnippet'] ??
                                          ''; // Safe fallback for null codeSnippet
                                }

                                return ListTile(
                                  title: Text(
                                      "${student['name']} - ${student['requestType']}"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Requested At: $formattedTime\nPosition in Queue: $pos"),
                                      // Check if there's an issue message before displaying it
                                      if (student['issueMessage'] != null &&
                                          student['issueMessage'].isNotEmpty)
                                        Text(
                                          "Issue: ${student['issueMessage'] ?? ''}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      // Show code snippet only if request type is "assistance"
                                      if (student['requestType'] ==
                                              'assistance' &&
                                          student['codeSnippet'] != null &&
                                          student['codeSnippet'].isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Code Attached:",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              margin: EdgeInsets.only(top: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Text(showFullCodeMap[
                                                          student[
                                                              'requestId']] ==
                                                      true
                                                  ? (student['codeSnippet'] ??
                                                      '')
                                                  : previewCode),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  showFullCodeMap[student[
                                                          'requestId']] =
                                                      !(showFullCodeMap[student[
                                                              'requestId']] ??
                                                          false);
                                                });
                                              },
                                              child: Text(
                                                showFullCodeMap[student[
                                                            'requestId']] ==
                                                        true
                                                    ? "Show Less"
                                                    : "Show More",
                                                style: TextStyle(
                                                    color: Colors.blue),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              });
                        }))
              ],
            )));
  }
}
