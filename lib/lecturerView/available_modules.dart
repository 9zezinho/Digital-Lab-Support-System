import 'package:dis/dialog/create_session_dialog.dart';
import 'package:dis/firestore_service.dart';
import 'package:flutter/material.dart';

/// This class displays a list of modules assigned to a lecturer. It fetches
/// the list of assigned modules from a Firestore database and displays them
/// to the user. The lecturer can tap on a module to create a session for it
/// through a dialog box.
///
/// This widgets provides:
/// - A list of available modules assigned ot the specified lecturer.
/// - A dialog for creating a new session for a specific module when tapped.
/// - Real - time updates of the modules list using 'StreamBuilder'.

class AvailableModules extends StatefulWidget{
  final String lecturerId;

  const AvailableModules({super.key, required this.lecturerId});

  @override
  State<AvailableModules> createState() => _AvailableModulesState();
}

class _AvailableModulesState extends State<AvailableModules> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Modules"),
      ),
      body: StreamBuilder<List<String>>(
          stream: _firestoreService.fetchAssignedModules(widget.lecturerId),
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            List<String> listOfAssignedModules = snapshot.data ?? [];

            if(listOfAssignedModules.isEmpty) {
              return Center(
                child: Text("No modules assigned"),
              );
            }

            return ListView.builder(
                itemCount: listOfAssignedModules.length,
                itemBuilder: (context, index) {
                  String moduleName = listOfAssignedModules[index];

                  return Card(
                    child: ListTile(
                      title: Text(moduleName),
                      trailing: Icon(Icons.add),
                      onTap: () {
                        showDialog(context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return CreateSessionDialog(
                                  lecturerId: widget.lecturerId,
                                  moduleName: moduleName,
                              );
                            }
                        );
                      },
                    ),
                  );
              },
            );
          }),
    );
  }}
