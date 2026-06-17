//1
import 'package:flutter/material.dart';
import 'register_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_page.dart'; 
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

// Login Page
class Login extends StatefulWidget {
  final StreamChatClient client;
  const Login({super.key, required this.client});
  

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final TextEditingController _controllerStudentID = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> loginUser() async {
    String sID = _controllerStudentID.text.trim();
    String pw = _controllerPassword.text.trim();

    if (sID.isEmpty) {
      _showSnackBar("Please enter Student ID");
      return;
    }
    if (pw.isEmpty) {
      _showSnackBar("Please enter Password");
      return;
    }

    
    final url = Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/login');//API 2: login

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', 
        },
        body: jsonEncode({
          "student_id": sID,
          "password": pw,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePage(studentID: sID, client: widget.client),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? "Login Failed");
      }
    } catch (e) {
      _showSnackBar("Error: Cannot connect to server");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent, 
        behavior: SnackBarBehavior.floating, 
      ),
    );
  }

  Widget _entryField(String title, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
            Color(0xFFEAF3FF), 
            Color(0xFFD6E8FF),
            Color(0xFFBFD9FF),
            ],
          )
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      "assets/logo.png",
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    _entryField(
                      "Student ID", _controllerStudentID),
                    const SizedBox(height: 10),
                    _entryField("Password", _controllerPassword, isPassword: true),
                    // Login button
                    Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            loginUser(); 
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C8EF5),
                            foregroundColor: Colors.white,
                            padding:const EdgeInsets.symmetric(vertical: 16),
                            elevation: 5,
                            shadowColor: const Color(0xFF6C8EF5).withValues(alpha:0.3),
                            shape:RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),                      
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ),
                   const SizedBox(height: 10),
                  // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Register(client: widget.client),
                              ),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              color: Color(0xFF6C8EF5),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    )
                  ]
                ),
              ),
            )
          )
        )
      )
    );
  }
}