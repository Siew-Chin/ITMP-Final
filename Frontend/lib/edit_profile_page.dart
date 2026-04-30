import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String studentID;
  const EditProfilePage({super.key, required this.studentID});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  //Image picker and controllers
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerStudentID = TextEditingController(); 
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerContactNumber = TextEditingController();
  final TextEditingController _controllerDorm = TextEditingController();

  //Pick image function
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

  //Update profile function
  Future<void> registerUser() async {
    String name = _controllerName.text.trim();
    String studentID = widget.studentID; // Student ID is passed from previous page, not editable
    String password = _controllerPassword.text.trim();
    String contactNumber = _controllerContactNumber.text.trim();
    String dorm = _controllerDorm.text.trim();

    if (name.isEmpty || studentID.isEmpty || password.isEmpty || contactNumber.isEmpty || dorm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:5000/update_profile');

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        // Optionally navigate back or to another page
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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

  // Entry field widget
  Widget _entryField(String title, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
      //Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
            Color(0xFFEAF3FF), // 很浅蓝
            Color(0xFFD6E8FF), // 中浅蓝
            Color(0xFFBFD9FF), // 柔蓝
            ],
          )
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar with icon and title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF6C8EF5),
                        size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Edit Profile",
                          style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F3A5A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Profile picture and info
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                        ),
                      ),    
                      // Edit icon
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            alignment: Alignment.center,
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C8EF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),

              //Input fields
              const SizedBox(height: 20),
              _entryField('Name', _controllerName),
              const SizedBox(height: 10),
              TextField(
                controller: _controllerStudentID,
                enabled: false, // Student ID is not editable
                decoration: InputDecoration(
                  hintText: "Student ID: ${widget.studentID}",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _entryField('Password', _controllerPassword, isPassword: true),
              const SizedBox(height: 10),
              _entryField('Contact Number (01X-XXXXXXX)', _controllerContactNumber),
              const SizedBox(height: 10),
              _entryField('Dorm', _controllerDorm),
              const SizedBox(height: 20),

              // Save button
              Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () {registerUser(); // 调用联网函数
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C8EF5),
                          foregroundColor: Colors.white,
                          padding:EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                          shadowColor: Colors.blue.withOpacity(0.3),
                          shape:RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),                      
                        child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        )
      ) 
    );
  }
}