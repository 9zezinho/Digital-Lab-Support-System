import 'package:dis/firestore_service.dart';
import 'package:dis/dialog/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../code_editor_screen.dart';

/// This class represents the session page for the lab assistant. It allows
/// the lab assistant to view and interact with the queue of students who
/// have made requests, including sorting and filtering the requests,viewing
/// code snippets, and marking requests as attended.

class LabAssistantSessionPage extends StatefulWidget {
  final String sessionId;

  const LabAssistantSessionPage({super.key, required this.sessionId});

  @override
  State<LabAssistantSessionPage> createState() =>
      _LabAssistantSessionPageState();
}

class _LabAssistantSessionPageState extends State<LabAssistantSessionPage> {
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
        appBar: AppBar(
          title: Text("Lab Assistant - Session"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                //Fetch the session name and display
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestoreService.fetchSessionQueue(widget.sessionId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var sessionData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String sessionName =
                          sessionData['sessionName'] ?? "Session Name here";

                      return Column(
                        children: [
                          Text(
                            "Session: $sessionName",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      // Handle error
                      return Text('Error: ${snapshot.error}');
                    } else {
                      // Handle loading state
                      return CircularProgressIndicator();
                    }
                  },
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
                const SizedBox(height: 10),

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
                          List studentQueue = sessionData['studentQueue'] ?? [];

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
                                .where(
                                    (req) => req['requestType'] == _filterType)
                                .toList();
                          }

                          return ListView.builder(
                              itemCount: studentQueue.length,
                              itemBuilder: (context, index) {
                                var student = studentQueue[index];
                                DateTime requestTime =
                                    student['requestedAt'].toDate();
                                String formattedTime =
                                    DateFormat('hh:mm a').format(requestTime);
                                String requestId = student['requestId'];
                                String requestType = student['requestType'];

                                //Safely get code snippet
                                String? codeSnippet = student['codeSnippet'];
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
                                                fontWeight: FontWeight.bold)),
                                        Text("Requested At: $formattedTime"),

                                        //Show the issue message if present
                                        if (student['issueMessage'] != null &&
                                            student['issueMessage'].isNotEmpty)
                                          Text(
                                            "Issue: ${student['issueMessage']}",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
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
                                                margin: EdgeInsets.only(top: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(5),
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
                                                    showFullCode[requestId] =
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

                                              if (codeOutput[requestId] != null)
                                                Text(
                                                    "Output: ${codeOutput[requestId]}"),
                                            ],
                                          ),

                                        Row(
                                          children: [
                                            if (requestType == "sign-off")
                                              ElevatedButton(
                                                //Button for sign-off
                                                onPressed: () async {
                                                  await _firestoreService
                                                      .removeRequest(
                                                          widget.sessionId,
                                                          requestId,
                                                        "sign-off");

                                                  if (context.mounted) {
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (context) =>
                                                          SuccessDialog(message:
                                                          "Request marked as attended!",),
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
                                                        SuccessDialog(message:
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
                        }))
              ],
            )));
  }
}
