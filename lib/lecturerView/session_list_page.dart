import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dis/lecturerView/session_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:dis/firestore_service.dart';

/// This class represents a list of sessions based on the provided 'status'
/// ("open" or "closed"). This page fetches sessions from the Firestore database
/// and presents them in a list format.

class SessionListPage extends StatelessWidget {
  final String status; //"open" or "closed"

  SessionListPage({super.key, required this.status});
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(status == "open" ? "Live Sessions" : "Closed Sessions")),
      body: StreamBuilder<QuerySnapshot>(
        stream:  _firestoreService.fetchOpenSession(status),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
            child: CircularProgressIndicator()
          );
          }

          var sessions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context,index) {
              var session = sessions[index];
              String sessionId = session.id;
              String sessionName = session['sessionName'];
              String createdFor = session['createdFor'];

              return Card(
                child: ListTile(
                  title: Text(sessionName),
                  subtitle: Text("Module: $createdFor"),
                  trailing: status == "open"
                    ? Icon(Icons.arrow_forward) // go to session details
                    : null,
                  onTap: () {
                    if (status == "open")  {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SessionDetailPage(sessionId: sessionId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }
}
