import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// A screen that allows lab assistant and lecturer to edit and run code related
/// to specific request.
///
/// Features:
/// - Displays a preloaded code snipped passed via 'initialCode'
/// - Supports syntax highlighting and editing via 'CodeController'
/// - Allows lab assistant and lecturers to select multiple languages
/// - Executes code using Piston API
/// - Displays the output of the executed code in a dialog box

class CodeEditorScreen extends StatefulWidget {
  final String initialCode;
  final String requestId;

  const CodeEditorScreen({super.key, required this.initialCode, required this.requestId});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {

  late CodeController _controller;

  String _selectedLang = "java";

  //List of languages to choose from
  final List<String> _languages = ['java', 'python', 'c', 'cpp',
    'kotlin', 'haskell'];

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialCode,
    );
  }

//Function to execute code using Piston API
  Future<void> _runCode(String language, String code) async {
    const String apiUrl = "https://emkc.org/api/v2/piston/execute";

    String lang = language.toLowerCase();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "language": lang,
          "version": "*",
          "files": [{"content": code}],
        }),
      );

      if(response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _showResultDialog(result['run']['output'] ?? "No output");
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
     print("Error running code: $e");
    }
  }

  // Dialog showing the output
  void _showResultDialog(String output) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Execution Result"),
            content: Text(output),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              )
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Code Editor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            //Row for "Run" and language selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Select Language",
                    style: TextStyle(fontSize: 18),),

                    SizedBox(width: 20),
                    //Dropdown Button for language selection
                    DropdownButton<String>(
                        value: _selectedLang,
                        items: _languages.map((String language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(language.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLang = newValue!;
                          });
                        }),
                  ],
                )
              ],
            ),
            Row(
              children: [
                SizedBox(width: 230),
                Text(
                  "Run Code",
                  style: TextStyle(fontSize: 18),
                ),

                // SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _runCode(_selectedLang, _controller.text);
                  },
                  style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                    padding: EdgeInsets.all(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size:16
                  ),
                )
              ],
            ),

            Expanded(
              // child: SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
                child: CodeTheme(
                  data: CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
                    controller: _controller,
                    // maxLines: 150,
                  ),
              //   ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
