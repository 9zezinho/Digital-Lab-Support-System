import 'package:dis/registration/auth_helper.dart';
import 'package:dis/adminView/assign_modules_to_lecturer.dart';
import 'package:dis/adminView/give_role_page.dart';
import 'package:flutter/material.dart';
import '../dashboard_button.dart';
import '../dialog/confirmation_dialog.dart';

/// This class represents the Admin Dashboard Screen.
/// This dashboard is intended for users with administrative privileges. It
/// allows them to
///
/// - Assign roles to users
/// - Assign academic modules to Lecturer

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Admin Dashboard"),
                  Text("Assign roles & Manage modules",
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
            // SizedBox(height: 150,),
            Expanded(
              child:GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  DashboardButton(
                    label: "Give\nRoles",
                    icon:Icons.person,
                    onTap: () {
                      //Navigate to GiveRoles Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder:
                            (context) => GiveRolesPage()),
                      );
                    },
                  ),
                  DashboardButton(
                      label: "Assign Modules",
                      icon: Icons.book,
                      onTap: (){
                        //Navigate to Assign Modules
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder:
                              (context) => AssignModule()),
                        );
                      }
                  ),
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
              )
            )
          ],
        )
      ),

    );
  }

}