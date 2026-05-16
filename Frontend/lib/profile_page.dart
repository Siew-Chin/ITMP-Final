import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'service_page.dart';
import 'edit_profile_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final String studentID;
  const ProfilePage({super.key, required this.studentID});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _selectedImage;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  double totalEarnings = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

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

  Future<void> loadProfileData() async {
    try {
      // 仅请求用户信息和收益，删除了反馈请求
      final results = await Future.wait([
        http.get(Uri.parse('http://10.0.2.2:5000/api/user/profile?student_id=${widget.studentID}')),
        http.get(Uri.parse('http://10.0.2.2:5000/api/runner/earnings?runner_id=${widget.studentID}')),
      ]).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        setState(() {
          userData = jsonDecode(results[0].body);
          var earningsData = jsonDecode(results[1].body);
          // 这里的 Key 必须与你 Flask 返回的一致 (total_earning)
          totalEarnings = (earningsData["total_earning"] ?? 0).toDouble();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Profile Load Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _infoBox(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C8EF5), size: 24),
          const SizedBox(width: 14),
          Expanded( // 增加 Expanded 防止长文本溢出
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF2F3A5A))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2F3A5A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earnCard({required String title, required String amount, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C8EF5), size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF2F3A5A))),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3A5A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF3FF), 
              Color(0xFFD6E8FF), 
              Color(0xFFBFD9FF)
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF6C8EF5)),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ServicePage(studentID: widget.studentID)),
                              );
                            },
                          ),
                          const Text("Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2F3A5A))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Profile Image
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                          child: _selectedImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(userData?["name"] ?? "Unknown User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2F3A5A))),
                      Text("Student ID: ${widget.studentID}", style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                      
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(studentID: widget.studentID))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C8EF5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        child: const Text("Edit Profile"),
                      ),

                      const SizedBox(height: 30),
                      _infoBox(Icons.phone, "Contact Number", userData?["contact"] ?? "Not set"),
                      const SizedBox(height: 14),
                      _infoBox(Icons.home, "Dorm", userData?["dorm"] ?? "Not set"),
                      const SizedBox(height: 20),

                      // Earnings Row
                      Row(
                        children: [
                          Expanded(child: _earnCard(title: "Today's", amount: "RM ${totalEarnings.toStringAsFixed(2)}", icon: Icons.today)),
                          const SizedBox(width: 12),
                          Expanded(child: _earnCard(title: "Total", amount: "RM ${totalEarnings.toStringAsFixed(2)}", icon: Icons.account_balance_wallet)),
                        ],
                      ),
                      const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}