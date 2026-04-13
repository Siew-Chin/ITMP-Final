import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'parcelOrFood_page.dart'; 
import 'runner_main_menu.dart';

// User or Runner page
class UserOrRunner extends StatefulWidget {
  // 1. 数据传递：接收从登录/注册页传来的 studentID
  final String studentID;
  const UserOrRunner({super.key, required this.studentID});

  @override
  State<UserOrRunner> createState() => UserOrRunnerState();
}

class UserOrRunnerState extends State<UserOrRunner> {
  // 1. 后端交互：通知服务器角色选择
  Future<void> selectRole(String role) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/user/update_role');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": widget.studentID,
          "role": role,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // 2. 跳转目标：根据选择跳转到相应页面
        Widget nextPage;
        if (role == 'student') {
          // 跳转到 ParcelOrFood 页面并传 ID
          nextPage = ParcelOrFood(studentID: widget.studentID); 
        } else {
          // 跳转到 RunnerMainMenu 页面并传 ID
          nextPage = RunnerMainMenu(studentID: widget.studentID);
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
          );
      } else {
        // 错误处理
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update role. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error: Cannot connect to update role")),
      );
    }
  }

  // 2. UI 表现 & 图片处理：使用 Stack 和装饰容器封装卡片
  Widget _roleCard(String title, String imagePath, String roleValue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => selectRole(roleValue), // 点击触发后端同步和跳转
        child: Stack(
          children: [
            // 2. 图片处理：圆角裁剪和固定高度
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            // 2. UI 表现：右上角的角色标签
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Your Dorm'),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        leading: const Icon(Icons.menu),
      ),
      backgroundColor: Colors.blue[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Login as",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // 调用封装好的卡片组件
              _roleCard("User", "assets/user_image.png", "student"),
              const SizedBox(height: 20),
              _roleCard("Runner", "assets/runner_image.png", "runner"),
            ],
          ),
        ),
      ),
    );
  }
}

// 模拟跳转页面
class RunnerLoginPage extends StatelessWidget {
  const RunnerLoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Runner Login")));
  }
}