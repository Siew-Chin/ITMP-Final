import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_new_app/service_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String studentID;
  const ProfilePage({super.key, required this.studentID});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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

  Widget _infoBox(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C8EF5), size: 24),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2F3A5A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F3A5A),
            ),
          )
        ],
      ),
    );
  }

  Widget _earnCard({required String title, required String amount, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical:18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C8EF5), size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2F3A5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F3A5A),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Background 
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
          child: Column(
            children: [
              Expanded(
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
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ServicePage(studentID: widget.studentID)),
                              );
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
                              "Profile",
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
            Stack(
                clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                      ),
                    ),    
                  ],
                ),

            //Name
            const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          "Name",
                          style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F3A5A),
                          ),
                        )
                      ),
                      const SizedBox(height: 12),

                      //Student ID
                      Center(
                        child: Text(
                          "Student ID: ${widget.studentID}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2F3A5A),
                          ),
                        )
                      ),
                      const SizedBox(height: 24),

                      //Edit Profile Button
                      Center(
                        child:SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditProfilePage(studentID: widget.studentID)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C8EF5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 5,
                            shadowColor: Colors.blue.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                      const SizedBox(height: 30),

                      //Contact Number
                      _infoBox(Icons.phone, "Contact Number", "Not set"),
                      const SizedBox(height: 14),
                      //Dorm
                      _infoBox(Icons.home, "Dorm", "Not set"),
                      const SizedBox(height: 14),

                      //Earning Section
                      Row(
                        children: [
                          Expanded(
                            child: _earnCard(
                              title: "Today's Earnings",
                              amount: "RM 0.00",
                              icon: Icons.today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _earnCard(
                              title: "Total Earnings",
                              amount: "RM 0.00",
                              icon: Icons.account_balance_wallet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),  
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}