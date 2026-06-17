//2
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart';

class Register extends StatefulWidget {
  final StreamChatClient client;
  const Register({super.key, required this.client});

  @override
  State<Register> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerStudentID = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerContactNumber = TextEditingController();
  final TextEditingController _controllerDorm = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

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
        dorm.isEmpty|| 
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields and upload a profile picture.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final url = Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/register');//API 1: register

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });

      request.fields['name'] = name;
      request.fields['student_id'] = studentID;
      request.fields['password'] = password;
      request.fields['contact'] = contactNumber;
      request.fields['dorm'] = dorm;
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image', 
        _selectedImage!.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoading = false);
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePage(studentID: studentID, client: widget.client),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? "Register Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error: Cannot connect")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
  }) 
  {
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
      body: Stack( 
        children: [
          Container(
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
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null 
                              ? FileImage(_selectedImage!) 
                              : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                          child: _selectedImage == null 
                              ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) 
                              : null,
                        ),
                      ),
                      const Text("Upload Photo", style: TextStyle(color: Color(0xFF2F3A5A))),

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
          if (_isLoading) 
                const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}