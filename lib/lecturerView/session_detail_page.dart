import 'package:dis/firestore_service.dart';
import 'package:dis/dialog/success_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../code_editor_screen.dart';
import '../dialog/confirmation_dialog.dart';

/// This Stateful widget represents the session detail page for the lecturer.
/// It allows lecturer to view and interact with the queue of students who have
/// made requests, including sorting and filtering the requests, viewing code
/// snippets, marking requests as attended and also closing the session.

class SessionDetailPage extends StatefulWidget {
  final String sessionId;

  const SessionDetailPage({
    super.key,
    required this.sessionId,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isAscending = true;
  String _filterType = "All";

  //Create a map to store the "Show full Code" state for each student
  Map<String, bool> showFullCode = {};
  Map<String, String> codeOutput = {}; //Stores output for each request

  //Toggle sorting order(ascending/descending)
  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Session Details")),
        body: StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.fetchSessionQueue(widget.sessionId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              var sessionData = snapshot.data!.data() as Map<String, dynamic>;
              String sessionName = sessionData['sessionName'];
              String sessionCode = sessionData['sessionCode'];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Session: $sessionName",
                        style: TextStyle(fontSize: 20)),
                    Text("Join Code: $sessionCode",
                        style: TextStyle(fontSize: 17)),
                    const SizedBox(
                      height: 20,
                    ),

                    //Sort and filtering options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleSortOrder,
                          child: Text(_isAscending
                              ? "Sort: Oldest First"
                              : "Sort: Newest First"),
                        ),
                        DropdownButton<String>(
                          value: _filterType,
                          items: [
                            DropdownMenuItem(
                                value: "All", child: Text("All requests")),
                            DropdownMenuItem(
                                value: "sign-off",
                                child: Text("Sign-Off Requests")),
                            DropdownMenuItem(
                                value: "assistance",
                                child: Text("Assistance Request")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    //Display the queue
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
                              List studentQueue =
                                  sessionData['studentQueue'] ?? [];

                              //Sort the queue by request time
                              studentQueue.sort((a, b) {
                                DateTime timeA = a['requestedAt'].toDate();
                                DateTime timeB = b['requestedAt'].toDate();
                                return _isAscending
                                    ? timeA.compareTo(timeB)
                                    : timeB.compareTo(timeA);
                              });

                              //Filter the queue based on the selected request type
                              if (_filterType != "All") {
                                studentQueue = studentQueue
                                    .where((req) =>
                                        req['requestType'] == _filterType)
                                    .toList();
                              }

                              return ListView.builder(
                                  itemCount: studentQueue.length,
                                  itemBuilder: (context, index) {
                                    var student = studentQueue[index];
                                    DateTime requestTime =
                                        student['requestedAt'].toDate();
                                    String formattedTime = DateFormat('hh:mm a')
                                        .format(requestTime);
                                    String requestId = student['requestId'];
                                    String requestType = student['requestType'];

                                    //Safely get code snippet
                                    String? codeSnippet =
                                        student['codeSnippet'];
                                    List<String> codeLines =
                                        codeSnippet?.split('\n') ?? [];
                                    String previewCode = codeLines.length > 1
                                        ? "${codeLines.take(1).join('\n')}\n..."
                                        : codeSnippet ?? "";

                                    //Ensure each request has an entry in showFullCode map
                                    showFullCode[requestId] =
                                        showFullCode[requestId] ?? false;

                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "${student['name']} - ${student['requestType']}",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                "Requested At: $formattedTime"),

                                            //Show the issue message if present
                                            if (student['issueMessage'] !=
                                                    null &&
                                                student['issueMessage']
                                                    .isNotEmpty)
                                              Text(
                                                "Issue: ${student['issueMessage']}",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),

                                            //Show code snippet if available
                                            if (codeSnippet != null &&
                                                codeSnippet.isNotEmpty)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Code Attached:",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.all(8),
                                                    margin:
                                                        EdgeInsets.only(top: 5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Text(
                                                      showFullCode[requestId]!
                                                          ? codeSnippet
                                                          : previewCode,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        showFullCode[
                                                                requestId] =
                                                            !showFullCode[
                                                                requestId]!;
                                                      });
                                                    },
                                                    child: Text(
                                                      showFullCode[requestId]!
                                                          ? "Show Less"
                                                          : "Show More",
                                                      style: TextStyle(
                                                          color: Colors.blue),
                                                    ),
                                                  ),

                                                  if (codeOutput[requestId] !=
                                                      null)
                                                    Text(
                                                        "Output: ${codeOutput[requestId]}"),
                                                ],
                                              ),

                                            Row(
                                              children: [
                                                if(requestType == "sign-off")
                                                  ElevatedButton( //Button for sign-off
                                                    onPressed: () async {
                                                      await _firestoreService
                                                          .removeRequest(
                                                          widget.sessionId,
                                                          requestId, "sign-off");

                                                      if (context.mounted) {
                                                        showDialog(
                                                          context: context,
                                                          barrierDismissible: false,
                                                          builder: (context) =>
                                                              SuccessDialog(
                                                                message:
                                                                "Signed-off",
                                                              ),
                                                        );
                                                      }
                                                    },
                                                    child: Text("Sign-Off"),
                                                  ),

                                                if (codeSnippet != "")
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CodeEditorScreen(
                                                            initialCode:
                                                                codeSnippet ??
                                                                    "",
                                                            // Pass the initial code
                                                            requestId:
                                                                requestId,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child:
                                                        Text("Open in editor"),
                                                  ),

                                                Spacer(),

                                                // Button for attended
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    await _firestoreService
                                                        .removeRequest(
                                                        widget.sessionId,
                                                        requestId, null);

                                                    if (context.mounted) {
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (context) =>
                                                            SuccessDialog(
                                                              message:
                                                              "Request marked as attended!",
                                                            ),
                                                      );
                                                    }
                                                  },
                                                  child: Text("Mark as Attended"),
                                                ),

                                              ],
                                            ),

                                          ],
                                        ),
                                        //       trailing:
                                      ),
                                    );
                                  });
                            })),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) => ConfirmationDialog(
                              title: "Close Session",
                              content: "Are you sure you want to close the session?",
                              confirmText: "Yes",
                              cancelText: "No",
                              onConfirm: () {
                                _firestoreService.closeSession(widget.sessionId);
                                Navigator.pop(context);
                              },
                            )
                        );
                      },
                      child: Text("Close Session"),
                    ),
                  ],
                ),
              );
            }));
  }
}
