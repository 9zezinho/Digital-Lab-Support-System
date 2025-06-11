import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dis/lecturerView/lecturer_dashboard.dart';
import 'package:dis/adminView/admin_dashboard.dart';
import 'package:dis/labAssistantView/lab_assistant_dashboard.dart';
import 'package:dis/registration/auth_helper.dart';
import 'package:dis/registration/register_page.dart';
import 'package:dis/studentView/student_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

/// This class represents the login screen of the application.
///
/// It provides two authentication options:
/// - Email and password login for all registered users
/// - Google Sign-In using Firebase Authentication.
///
/// On Successful Login, it fetches the user's role from Firestore and
/// navigates them to the corresponding dashboard

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final String logcatTag = "LoginTag";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async{
      try {
        UserCredential userCredential =  await FirebaseAuth
            .instance.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
        );

        //Log user authentication result
        if (userCredential.user != null){
          log("user logged in: ${userCredential.user!.uid}", name: logcatTag);

          //Get user data from Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore
              .instance.collection('users')
              .doc(userCredential.user!.uid).get();
          String role = userDoc['role']; //Get role from Firestore

          if (mounted) {
            if (role == 'admin'){
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) =>
                      AdminDashboard()));
            } else if (role == 'student') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) =>
                      StudentDashboard()));
            } else if (role == 'lab_assistant') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) =>
                      LabAssistantDashboard()));
            } else {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) =>
                      LecturerDashboard()));
            }

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Login Successful"))
            );
          }
        } else {
          log("Login failed", name: logcatTag);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Login Failed:"))
            );
          }
        }

      } catch (e) {
        if (mounted){
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login Failed: ${e.toString()}"))
          );
        }

      }

  }

  //Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    final userCredential = await AuthHelper.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 358,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color.fromRGBO(37, 156, 210, 1.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: "Email"),
                        validator: (value) => value!.isEmpty ?
                        "Please enter your email" : null,
                      ),
                      const SizedBox(height: 16,),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                            labelText: "Password"),
                        validator: (value) => value!.isEmpty ?
                        "Please enter your password" : null,
                      ),
                      const SizedBox(height: 16),
                      //Continue Button
                      PrimaryButton(
                        onTap: () async{
                          await _login();
                        },
                        borderRadius: 8,
                        fontSize: 14,
                        height: 48,
                        width: 326,
                        text: 'Continue',
                        textColor: Colors.black,
                        bgColor: Colors.white,

                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      PrimaryTextButton(
                        title: 'Forgot password?',
                        fontSize: 14,
                        onPressed: () {},
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      const DividerRow(),
                      const SizedBox(height: 32),
                      //Google Sign-In
                      PrimaryButton(
                        onTap: () async {
                          final userCredential =
                          await AuthHelper.signInWithGoogle();
                          if(userCredential != null) {
                            _login();
                          } else {
                            print("Login Failed");
                          }
                        },
                        borderRadius: 8,
                        fontSize: 14,
                        height: 48,
                        width: 326,
                        text: 'Login with Google',
                        textColor: Colors.black,
                        bgColor: Colors.white,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      PrimaryTextButton(
                        title: 'Don’t have an account? Sign up',
                        fontSize: 14,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>
                                  RegisterPage())
                          );
                        },
                        textColor: Colors.white,
                      )
                    ],
                  )
                )
              ],
            )));
  }
}

// Custom Button
class PrimaryButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? fontSize;
  final IconData? iconData;
  final Color? textColor, bgColor;

  const PrimaryButton(
      {super.key,
        required this.onTap,
        required this.text,
        this.width,
        this.height,
        this.borderRadius,
        this.fontSize,
        required this.textColor,
        required this.bgColor,
        this.iconData});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius ?? 8),
      child: Container(
        height: height ?? 55,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconData != null) ...[
                Icon(
                  iconData,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize ?? 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        )
      )
    );
  }
}

// Divider
class DividerRow extends StatelessWidget {
  const DividerRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        const Expanded(child: Divider())
      ],
    );
  }
}

//Custom Text button
class PrimaryTextButton extends StatelessWidget {
  const PrimaryTextButton(
      {super.key,
        required this.onPressed,
        required this.title,
        required this.fontSize,
        required this.textColor});
  final Function() onPressed;
  final String title;
  final double fontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: Text(
        title,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
    );
  }
}
