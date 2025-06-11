import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dis/registration/auth_helper.dart';
import 'package:dis/firestore_service.dart';
import 'package:dis/labAssistantView/lab_assistant_session_page.dart';
import 'package:flutter/material.dart';
import '../dialog/confirmation_dialog.dart';

/// This class represents the main dashboard for a lab assistant.
/// It allows the lab assistant to join a session and view a list of queues.
/// The dashboard also includes a logout functionality for the user


class LabAssistantDashboard extends StatefulWidget {
  const LabAssistantDashboard({super.key});

  @override
  State<LabAssistantDashboard> createState() => _LabAssistantDashboardState();
}

class _LabAssistantDashboardState extends State<LabAssistantDashboard> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _sessionCodeController = TextEditingController();

  //Join a session using 6 digit code
  Future<void> _joinSessionD() async {
    String sessionCode = _sessionCodeController.text.trim();

    //Fetch session Id
    String? sessionId = await _firestoreService.joinSession(sessionCode);

    if(sessionId != null) {

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>
            LabAssistantSessionPage(sessionId: sessionId)),
      );
      _sessionCodeController.clear(); //Clear input
      setState(() {}); // Ensure UI updates

    } else {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session Not Found')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lab Assistant Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              children: [
                //Text filed for entering the session code
                TextField(
                  controller: _sessionCodeController,
                  decoration: InputDecoration(
                    labelText: "Enter 6-digit Session Code",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10,),

                ElevatedButton(
                  onPressed:()  {
                    _joinSessionD();
                    FocusScope.of(context).unfocus();
                  },
                  child: Text("Join Session"),
                ),
              ],
            ),

            const SizedBox(height: 20,),

            //Joined Session List
            Text("Joined Sessions", style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: _firestoreService.fetchJoinedSession("open"),
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return Center(child: CircularProgressIndicator(),);
                    }

                    if(snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.hasError}"));
                    }

                    if(!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No Live Sessions"),);
                    }

                    var sessions = snapshot.data!;

                    return ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          var session = sessions[index];
                          return ListTile(
                            title: Text(session["sessionName"]),
                            subtitle: Text("Code: ${session["sessionCode"]}"),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      LabAssistantSessionPage(
                                          sessionId: session.id),)
                              );
                            },
                          );
                        }
                    );
                  }
              ),
            )
          ],
        ),

      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue.shade800,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal:16.0
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        title: "Logout",
                        content: "Are you sure you want to log out?",
                        confirmText: "Logout",
                        cancelText: "Stay",
                        onConfirm: () {
                          AuthHelper.logout(context);
                        },
                      )
                  );
                },
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text("Logout", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],

          ),
        ),
      ),
    );
  }

}