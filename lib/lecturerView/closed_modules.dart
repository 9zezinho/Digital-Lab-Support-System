import 'package:dis/firestore_service.dart';
import 'package:dis/lecturerView/closed_session.dart';
import 'package:flutter/material.dart';

/// This class displays a  list of modules assigned to a lecturer, specially
/// for closed sessions. The list of modules is fetched from the Firestore
/// database. The user can tap on a module to view the corresponding closed
/// session details.

class ClosedModules extends StatelessWidget {
  final String lecturerId;
   ClosedModules({super.key, required this.lecturerId});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modules"),
        centerTitle: true,
      ),
      body: StreamBuilder(
          stream: _firestoreService.fetchAssignedModules(lecturerId),
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
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                            ClosedSession(moduleName: moduleName,),
                          ),
                        );
                      },

                    ),
                  );
                }
            );

          })
    );
  }
}
