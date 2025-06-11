import 'package:dis/dialog/confirmation_dialog.dart';
import 'package:dis/firestore_service.dart';
import 'package:dis/lecturerView/available_modules.dart';
import 'package:dis/lecturerView/closed_modules.dart';
import 'package:dis/registration/auth_helper.dart';
import 'package:flutter/material.dart';
import '../dashboard_button.dart';
import 'session_list_page.dart';

/// This widget represents teh dashboard for the lecturer. This dashboard
/// allows the lecturer to manage various aspects of their sessions including:
/// - Creating a new session.
/// - Viewing live session.
/// - Accessing findings from closed sessions.
/// - Logging out of the system.

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  String lecturerId = FirestoreService.userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Center(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Lecturer Dashboard"),
                Text("Manage your sessions",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black
                    )
                )
              ]
          ),
        )
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SizedBox(height: 110,),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  // Buttons: Create, Live and Closed
                  DashboardButton(
                      label: "Create\nSession",
                      icon: Icons.add_circle,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AvailableModules(
                                  lecturerId: lecturerId,
                                )));
                      }),
                  DashboardButton(
                      label: "Live\nSession",
                      icon: Icons.live_tv,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SessionListPage(status: "open")),
                        );
                      }),
                  DashboardButton(
                      label: "Findings",
                      icon: Icons.analytics_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ClosedModules(lecturerId: lecturerId)),
                        );
                      }),
                  DashboardButton(
                      label: "Logout",
                      icon: Icons.logout,
                      onTap: () {
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
                      }
                  )
                ],
              ),
            )
          ],
        )
      ),
    );
  }
}
