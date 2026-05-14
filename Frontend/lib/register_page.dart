import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_page.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

final baseUrl = kIsWeb
    ? 'http://127.0.0.1:5000' // Chrome
    : 'http://10.0.2.2:5000'; // Emulator

// Register page
class Register extends StatefulWidget {
  final StreamChatClient client;
  const Register({super.key, required this.client});

  @override
  State<Register> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerStudentID = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerContactNumber =
      TextEditingController();
  final TextEditingController _controllerDorm = TextEditingController();

  // Register user function
  Future<void> registerUser() async {
    String name = _controllerName.text.trim();
    String studentID = _controllerStudentID.text.trim();
    String password = _controllerPassword.text.trim();
    String contactNumber = _controllerContactNumber.text.trim();
    String dorm = _controllerDorm.text.trim();

    // Check empty fields
    if (name.isEmpty ||
        studentID.isEmpty ||
        password.isEmpty ||
        contactNumber.isEmpty ||
        dorm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "student_id": studentID,
          "password": password,
          "contact": contactNumber,
          "dorm": dorm,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Go to service page after register success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePage(studentID: studentID, client: widget.client),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? "Register Failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error: Cannot connect")),
      );
    }
  }

  @override
  void dispose() {
    _controllerName.dispose();
    _controllerStudentID.dispose();
    _controllerPassword.dispose();
    _controllerContactNumber.dispose();
    _controllerDorm.dispose();
    super.dispose();
  }

  // Input field widget
  Widget _entryField(
    String title,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: title,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Background
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
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),

            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new, 
                          color: Color(0xFF6C8EF5),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F3A5A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Page title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3A5A),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _entryField('Name', _controllerName),
                  const SizedBox(height: 12),

                  _entryField('Student ID', _controllerStudentID),
                  const SizedBox(height: 12),

                  _entryField(
                    'Password',
                    _controllerPassword,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),

                  _entryField(
                    'Contact Number (01X-XXXXXXX)',
                    _controllerContactNumber,
                  ),
                  const SizedBox(height: 12),

                  _entryField('Dorm', _controllerDorm),
                  const SizedBox(height: 28),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C8EF5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 5,
                        shadowColor: Colors.blue.withValues(alpha:0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}