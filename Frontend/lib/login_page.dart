import 'package:flutter/material.dart';
import 'register_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'service_page.dart'; 
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

final baseUrl = kIsWeb
    ? 'http://127.0.0.1:5000'   // Chrome
    : 'http://10.0.2.2:5000';   // Emulator


// Login Page
class Login extends StatefulWidget {
  final StreamChatClient client;
  const Login({super.key, required this.client});
  

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  // 控制器
  final TextEditingController _controllerStudentID = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  // 1. 技术实现 & 数据来源：异步联网登录
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

    // 后端 Flask 地址 (Android 模拟器使用 10.0.2.2)
    final url = Uri.parse('http://10.0.2.2:5000/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": sID,
          "password": pw,
        }),
      );

      if (response.statusCode == 200) {
        // 登录成功逻辑
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

  // 输入框组件封装
  Widget _entryField(String title, TextEditingController controller,
      {bool isPassword = false}) {
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
            Color(0xFFEAF3FF), // 很浅蓝
            Color(0xFFD6E8FF), // 中浅蓝
            Color(0xFFBFD9FF), // 柔蓝
            ],
          )
        ),
      // 2. 布局安全：使用 SingleChildScrollView 包装，防止键盘弹出时溢出
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
                        onPressed: () {loginUser(); // 调用联网函数
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
                          fontWeight: FontWeight.bold),
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