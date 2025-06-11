import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dis/adminView/module.dart';
import 'package:dis/dialog/success_dialog.dart';
import 'package:dis/firestore_service.dart';
import 'package:flutter/material.dart';

/// This class allows admin users to assign predefined modules to
/// lecturer dynamically.
///
/// This screen features:
/// - A searchable 'Autocomplete' text field to select lecturers by name
/// - A checkbox-based multi-selection list of modules to assign
/// - Integration with Firestore via 'FirestoreService'

class AssignModule extends StatefulWidget {
  const AssignModule ({super.key});

  @override
  State<AssignModule> createState() => _AssignModuleState();
}

class _AssignModuleState extends State<AssignModule> {

  final FirestoreService _firestoreService = FirestoreService();
  List<Module> modules = Module.predefinedModules;
  TextEditingController _lecturerController = TextEditingController();

  List<String> selectedModules = [];
  String? selectedLecturer;
  String? selectedLecturerUid;
  List<Map<String, String>> lecturerNames = [];

  @override
  void initState(){
    super.initState();
    fetchLecturersFromDatabase();
  }

  //Simulate Fetched Lecturer
  void fetchLecturersFromDatabase() async {
    QuerySnapshot snapshot = await _firestoreService
        .fetchUsers(role: "lecturer").first;

    setState(() {
      lecturerNames = snapshot.docs
          .map((doc) => {
            'fullName': (doc['fullName'] as String).trim(),
            'uid': doc.id,
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign Module"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //Lecturer
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if(textEditingValue.text.isEmpty){
                  return const Iterable <Map<String, String>>.empty();
                }
                return lecturerNames.where((Map<String, String> lecturer) =>
                    lecturer['fullName']!.toLowerCase()
                        .contains(textEditingValue.text.toLowerCase())
                );
              },
              fieldViewBuilder: (BuildContext context,
                  controller,
                  FocusNode focusNode, VoidCallback onFieldSubmitted) {
                _lecturerController = controller;

                return TextField(
                  controller : controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Enter Lecturer by Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
              //Display just the fullName
              displayStringForOption: (Map<String, String> option){
                return option['fullName']?? '';
              },
              onSelected: (Map<String, String> selection) async {
                setState(() {
                  selectedLecturer = selection['fullName'];
                  selectedLecturerUid = selection['uid'];
                });

                //Fetch already assigned modules after selecting lecturer
                List<String> fetchedModules = await _firestoreService
                    .fetchAssignedModules(selectedLecturerUid!).first;

                // Safely update state only if widget is still mounted
                if(!mounted) return;

                setState(() {
                  selectedModules = fetchedModules;
                });
                //Dismiss the keyboard
                FocusScope.of(context).unfocus();
              },
            ),
            const SizedBox(height: 15,),
            Text("Select List of Modules"),

            //Multi-select Modules using Checkboxes
            Expanded(
              child:ListView(
                children: modules.map((module) {
                  return CheckboxListTile(
                    title: Text(module.name),
                    value: selectedModules.contains(module.name),
                    onChanged: (bool? selected) {
                      setState(() {
                        if(selected != null && selected){
                          selectedModules.add(module.name);
                        } else {
                          selectedModules.remove(module.name);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height:20),
            //Assign Button
            FilledButton(
              onPressed: () async {
                if(selectedLecturer == null){
                  //Show SnackBar message if no lecturer is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text("Please select a lecturer before assigning modules."),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                  return;
                }
                FocusScope.of(context).unfocus();

                _firestoreService.assignModules(
                    selectedLecturerUid!, selectedModules);

                //Show Success Dialog
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        SuccessDialog(message:
                        "Modules Assigned Successfully!"),
                  );
                  await Future.delayed(Duration(milliseconds: 150));

                  //Clear selection
                  setState(() {
                    _lecturerController.clear();
                    selectedModules.clear();
                  });
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      )
    );
  }

}