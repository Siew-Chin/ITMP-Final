import 'package:flutter/material.dart';
import 'dart:convert';         
import 'package:http/http.dart' as http; 
import 'userOrRunner_page.dart';

// Register page
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerStudentID = TextEditingController(); 
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerContactNumber = TextEditingController();
  final TextEditingController _controllerDorm = TextEditingController();

  // 1. 按钮操作逻辑：整合联网请求
  Future<void> registerUser() async {
    // 获取输入内容并去空格
    String name = _controllerName.text.trim();
    String studentID = _controllerStudentID.text.trim();
    String password = _controllerPassword.text.trim();
    String contactNumber = _controllerContactNumber.text.trim();
    String dorm = _controllerDorm.text.trim();

    // 1 & 2. 错误提示：本地判空校验 (来自文件 2)
    if (name.isEmpty || studentID.isEmpty || password.isEmpty || contactNumber.isEmpty || dorm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:5000/register');

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
        // 2. 页面跳转方式：(虽然你选了 2，但我保留了传 studentID，因为下一页通常需要它)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserOrRunner(studentID: studentID),
          ),
        );
      } else {
        // 1. 错误提示：后端返回的错误 (来自文件 1)
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
                "Register", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _entryField('Name', _controllerName),
              const SizedBox(height: 10),
              _entryField('Student ID', _controllerStudentID),
              const SizedBox(height: 10),
              _entryField('Password', _controllerPassword, isPassword: true),
              const SizedBox(height: 10),
              _entryField('Contact Number (01X-XXXXXXX)', _controllerContactNumber),
              const SizedBox(height: 10),
              _entryField('Dorm', _controllerDorm),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(28.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      registerUser(); // 执行整合后的逻辑
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    // 1. 按钮文字：Register
                    child: const Text('Register'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryField(String title, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}