//6
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'login_page.dart';
import 'runner_earning_history_page.dart';

class ProfilePage extends StatefulWidget {
  final String studentID;
  final StreamChatClient client;
  final VoidCallback? onProfileUpdated;
  const ProfilePage({super.key, required this.studentID, required this.client, this.onProfileUpdated,});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _networkImageUrl;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  double todayEarnings = 0;
  double totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  void _openAvatarPreview() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text("Profile Photo"),
        ),
        body: Center(
          child: (_networkImageUrl != null && _networkImageUrl!.isNotEmpty)
              ? InteractiveViewer(
                  child: Image.network(
                    _networkImageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white70,
                      );
                    },
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 120,
                  color: Colors.white70,
                ),
        ),
      ),
    ),
  );
}

  Future<void> loadProfileData() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse('http://10.0.2.2:5000/api/user/get_info/${widget.studentID}')),//API 23 Get user new info 
        http.get(Uri.parse('http://10.0.2.2:5000/api/runner/earnings?runner_id=${widget.studentID}')),//API 19: calculate Earnings
      ]).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final data = jsonDecode(results[0].body);
        setState(() {
          userData = jsonDecode(results[0].body);
          _networkImageUrl = data['image_url'];
          var earningsData = jsonDecode(results[1].body);
          todayEarnings = (earningsData["today_earning"] ?? 0).toDouble();
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

  Future<void> _handleLogout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login(client: widget.client)),
        (route) => false,
      );
    }
  }

  Widget _infoBox(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
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
          Expanded( 
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
        color: Colors.white.withValues(alpha: 0.85),
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        children: [
          const Text(
            "Profile",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F3A5A),
            ),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: _openAvatarPreview,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: (_networkImageUrl != null && _networkImageUrl!.isNotEmpty)
                  ? NetworkImage(_networkImageUrl!)
                  : const AssetImage("assets/user_image.png") as ImageProvider,
              child: (_networkImageUrl == null || _networkImageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            )
          ),

          const SizedBox(height: 20),
          Text(userData?["name"] ?? "Unknown User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2F3A5A))),
          Text("Student ID: ${widget.studentID}", style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage(studentID: widget.studentID))
            ).then((_)async {
              await loadProfileData();         
              widget.onProfileUpdated?.call();  
            }),
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
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RunnerEarningHistoryPage(
                        runnerId: widget.studentID,
                      ),
                    ),
                  ),
                  child: _earnCard(
                    title: "Today's",
                    amount: "RM ${todayEarnings.toStringAsFixed(2)}",
                    icon: Icons.today,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RunnerEarningHistoryPage(
                        runnerId: widget.studentID,
                      ),
                    ),
                  ),
                  child: _earnCard(
                    title: "Total",
                    amount: "RM ${totalEarnings.toStringAsFixed(2)}",
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                "Log Out",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30), 
        ],
      ),
    );
  }
}