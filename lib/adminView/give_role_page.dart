import 'package:dis/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// This class allows admin users to manage user roles to users.
///
/// This activity features:
/// - Searchable text field to select users by name
/// - Update roles(Lecturer, Lab Assistant and Student)

class GiveRolesPage extends StatefulWidget {
  const GiveRolesPage({super.key});

  @override
  State<GiveRolesPage> createState() => _GiveRolesPageState();
}

class _GiveRolesPageState extends State<GiveRolesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Manage User Roles")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {}); //Refresh list when searching
              },
            ),
            const SizedBox(height: 10,),

            //Filter dropdown
            DropdownButton(
              value: _selectedFilter,
                items: ["All", "Lab Assistant", "Student", "Lecturer"]
                    .map((filter) {
                  return DropdownMenuItem(value: filter,child: Text(filter));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
            ),

          const SizedBox(height: 10),

            //User List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _selectedFilter == "All"
                  ? _firestoreService.fetchUsers() //fetch all users
                  : _firestoreService.fetchUsers(
                    role: _selectedFilter.toLowerCase().replaceAll(" ", "_")),// Filter based on role
                builder: (context, snapshot) {
                  if(!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  var users = snapshot.data!.docs;
                  String searchQuery = _searchController.text.toLowerCase();

                  //Filter by search query
                  users = users.where((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    return userData['fullName'].toLowerCase().contains(searchQuery);
                  }).toList();

                  if (users.isEmpty) {
                    return Center(child: Text("No users found"));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context,index) {
                      var user = users[index].data() as Map<String, dynamic>;
                      String userId = users[index].id;
                      String role = user['role'];

                      return ListTile(
                        title:Text(user['fullName']),
                        subtitle: Text("Role: $role"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (newRole) async {
                            await _firestoreService
                                .updateUserRole(userId, newRole);
                            if(context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content:
                                  Text("User role updated to $newRole"))
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: "lab_assistant",
                                child: Text("Make Lab Assistant")),
                            PopupMenuItem(value: "student",
                                child: Text("Make Student")),
                            PopupMenuItem(value: "lecturer",
                                child: Text("Make Lecturer")),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            )
          ],
        ),
      )
    );
  }
}
