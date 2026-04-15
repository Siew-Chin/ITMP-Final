import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_main_menu.dart';

class InstructionsPage extends StatelessWidget {
  final String orderId; // 接收从上个页面传来的订单ID
  final String runnerId; // 接收当前跑腿员的学号

  const InstructionsPage({
    super.key,
    required this.orderId,
    required this.runnerId,
  });

  // 🛠️ 调用 API 13: 更新订单状态为 dropped
  Future<void> _updateToDropped(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/runner/dropped'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"order_id": orderId}),
      );

      if (response.statusCode == 200) {
        // 💡 成功后，清空页面栈并跳回 Main Menu
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => RunnerMainMenu(studentID: runnerId),
          ),
          (route) => false, // 这行代码保证用户不能按返回键回到指示页
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        title: const Text('Parcel'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Note :",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                "Please go to the dorm to collect Student ID or Staff ID.\n\nAfter collecting the parcel, please drop it at the dorm and remember to collect money from the customer.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _updateToDropped(context), // 💡 绑定点击事件
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: Colors.blue,
                    elevation: 5,
                  ),
                  child: const Text(
                    'Dropped',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// 这里的 main 函数是专门为了单页面运行测试加的
// --- 临时 main，用于单独测试这一页 ---
// 你运行这个文件时，模拟器会直接显示这一页
void main() {
  runApp(
    const MaterialApp(
      home: InstructionsPage(
        orderId: "TEST_ORDER", // 随便给个测试用的字符串
        runnerId: "TEST_RUNNER",
      ),
    ),
  );
}
