//27
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'service_page.dart'; 
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class WaitingPage extends StatefulWidget {
  final String orderId;
  final String studentID;
  final double totalPrice;
  final Widget targetPage; // 这个就是你在截图里定义的“第三列”页面
  final StreamChatClient client;

  const WaitingPage({
    super.key,
    required this.orderId,
    required this.studentID,
    required this.targetPage,
    required this.totalPrice,
    required this.client,
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
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/order/tracking/${widget.orderId}'),//API4: GetProgress
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

  Future<void> _cancelOrder() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/order/cancel'),//API 27: Cancel Order (only if not taken by runner yet)
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.orderId,
          "requester_id": widget.studentID,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _timer?.cancel();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePage(
              studentID: widget.studentID,
              client: widget.client,
            ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to cancel this order.")),
        );
      }
    } catch (e) {
      debugPrint("Cancel order error: $e");
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
            ElevatedButton.icon(
              onPressed: () {
                _timer?.cancel();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServicePage(
                      studentID: widget.studentID,
                      client: widget.client,
                    ),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text("Exit and Continue Later"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C8EF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _cancelOrder,
              child: const Text(
                "Cancel Order",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}