import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dis/adminView/module.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// This class represents the registration screen of the application
///
/// It allows new users (students by defaults) to create an account using
/// an email and password. Upon successful registration:
/// - the user is added to Firebase Authentication
/// - A corresponding document is created in Firestore under the 'users'
/// collection, with the role set as 'student'

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegistered = false; //Track registration success

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);

        //Get user id:
        String uid = userCredential.user!.uid;

        //Create a list of all modules with role 'student'
        List<Map<String, String>> defaultModules = Module.predefinedModules
            .map((module) => {
                  'name': module.name,
                  'role': 'student',
                })
            .toList();

        //Save User Data to Firestore
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "fullName": _fullNameController.text,
          "email": _emailController.text,
          "uid": uid, //Store the user ID
          "role": "student",
          "createdAt": DateTime.now(),
          "modules": defaultModules,
        });

        if (mounted) {
          //check if the widget is still in the widget tree
          setState(() {
            _isRegistered = true;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Registration Successful")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Registration Failed!!!")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
        child: Text("Register"),
      )),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(
              'Welcome to the Sign-Up Page!',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                color: Colors.black,
              ),
            ),
            Container(
                width: 358,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color.fromRGBO(37, 156, 210, 1.0),
                ),
                child: _isRegistered
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "You can login now",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                            child: Icon(Icons.arrow_back),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            //Full name Field
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: "Full Name",
                              ),
                              validator: (value) => value!.isEmpty
                                  ? "Please enter your full name"
                                  : null,
                            ),
                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: "Email"),
                              validator: (value) => value!.isEmpty
                                  ? "Please enter your email"
                                  : null,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration:
                                  InputDecoration(labelText: "Password"),
                              obscureText: true,
                              validator: (value) => value!.length < 6
                                  ? "Password must be at least 6 characters"
                                  : null,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                                onPressed: _register, child: Text("Register"))
                          ],
                        )))
          ])),
    );
  }
}
