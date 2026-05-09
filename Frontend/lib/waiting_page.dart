import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'service_page.dart'; 

class WaitingPage extends StatefulWidget {
  final String orderId;
  final String studentID;
  final double totalPrice;
  final Widget targetPage; // 这个就是你在截图里定义的“第三列”页面

  const WaitingPage({
    super.key,
    required this.orderId,
    required this.studentID,
    required this.targetPage,
    required this.totalPrice,
  });

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkOrderStatus();
    });
  }

  Future<void> _checkOrderStatus() async {
    try {
      // 使用 API 4 检查状态
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/order/tracking/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int statusCode = data['status_code'] ?? 0;
        
        // 只要状态不是 0 (Available)，就代表有人接单了
        if (statusCode > 0) {
          _timer?.cancel(); 

          if (!mounted) return;

          // --- 关键修改：直接跳转到传进来的 targetPage ---
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => widget.targetPage,
            ),
          );
        }
      }
    } catch (e) {
      print("Polling error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 部分保持不变 ...
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF3FF), Color(0xFFBFD9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C8EF5)),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Finding a Runner...",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2F3A5A)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Your order #${widget.orderId} has been posted. Please wait while we match you with a runner.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
            const SizedBox(height: 50),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ServicePage(studentID: widget.studentID)),
                  (route) => false,
                );
              },
              child: const Text("Cancel and Go Back", style: TextStyle(color: Colors.redAccent)),
            )
          ],
        ),
      ),
    );
  }
}