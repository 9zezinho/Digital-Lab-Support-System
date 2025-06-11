import 'package:dis/firestore_service.dart';
import 'package:dis/lecturerView/findings/session_finding.dart';
import 'package:flutter/material.dart';

/// This class displays a list of closed sessions for a given module. The
/// list of sessions is fetched from Firestore. The user can tap on a session
/// to view the details and findings for that session.


class ClosedSession extends StatelessWidget {
  final String moduleName;

  ClosedSession({super.key, required this.moduleName});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Closed Session Findings"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _firestoreService.fetchClosedSessionOfModule(moduleName),
        builder: (context,snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List<Map<String, String>> listOfClosedSession = snapshot.data ?? [];

          if(listOfClosedSession.isEmpty) {
            return Center(
              child: Text("No session has been created to this module.\n"
                  "Check if the session has been closed"),
            );
          }

          return ListView.builder(
              itemCount: listOfClosedSession.length,
              itemBuilder: (context, index) {
                String sessionName =
                    listOfClosedSession[index]['sessionName'] ?? "";
                String sessionId =
                    listOfClosedSession[index]['sessionId'] ?? "";

                return Card(
                  child: ListTile(
                    title: Text(sessionName),
                    trailing: Icon(Icons.arrow_forward),
                    onTap:() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                          SessionFinding(
                              sessionId: sessionId,
                              sessionName: sessionName))
                      );
                    }
                  )
                );
              }
          );
        },
      )
    );
  }
}
