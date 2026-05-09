//7
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'chat_page.dart'; 
import 'user_rating_page.dart'; 

class PickupDropoffTrackingPage extends StatefulWidget {
  final String orderId;
  final double totalPrice;
  final String studentID; // 记得这里也要加 studentID 

  const PickupDropoffTrackingPage({
    super.key,
    required this.orderId,      
    required this.totalPrice,   
    required this.studentID,
  });

  @override
  State<PickupDropoffTrackingPage> createState() => _PickupDropoffTrackingPageState();
}

class _PickupDropoffTrackingPageState extends State<PickupDropoffTrackingPage> {
  // 状态码 (1: Order Taken, 2: Picking Up, 3: Arrived Pickup, 4: Dropped Off)
  int _currentStatus = 0; 
  String? _runnerId; // 司机 ID
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRideStatus(); // 初始化
    // 设置每 3 秒轮询一次 API 4
    _timer = Timer.periodic(const Duration(seconds: 3), (t) => _fetchRideStatus());
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  // --- API 调用：获取实时进度 ---
  Future<void> _fetchRideStatus() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/order/tracking/${widget.orderId}');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _currentStatus = data['status_code'] ?? 0;
            _runnerId = data['runner_id'];
          });
        }
      }
    } catch (e) {
      debugPrint("Ride Polling error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Ride Status', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Chat 按钮：有人接单且拿到司机 ID 时显示
          if (_currentStatus > 0 && _runnerId != null) 
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      studentID: widget.studentID,
                      runnerID: _runnerId!, 
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRideStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Order ID: ${widget.orderId}",
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),

              // 4 点进度图 (专为接送设计)
              _buildRideTimeline(),

              const SizedBox(height: 50),

              // 费用卡片
              _buildPriceCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total To Pay", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)
            ),
          Text("RM ${widget.totalPrice.toStringAsFixed(2)}", 
               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ]
      ),
    );
  }

  Widget _buildBottomButton() {
  bool canContinue = _currentStatus == 4;

  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: canContinue
            ? () {
                _timer?.cancel();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserRatingPage(
                      studentID: widget.studentID,
                      orderId: widget.orderId,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          _currentStatus == 4
              ? "Continue"
              : "Driver is on the way...",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

  // --- 搭车专用进度条 ---
  Widget _buildRideTimeline() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepDot(1), _buildStepLine(1), 
            _buildStepDot(2), _buildStepLine(2), 
            _buildStepDot(3), _buildStepLine(3), 
            _buildStepDot(4),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepLabel("Order\nTaken", 1), 
            _buildStepLabel("Picking Up\nPassenger", 2), 
            _buildStepLabel("Arrive\nPickup", 3), 
            _buildStepLabel("Dropped\nOff", 4),
          ],
        ),
      ],
    );
  }

  Widget _buildStepDot(int step) {
    bool active = _currentStatus >= step;
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: active ? Colors.black87 : Colors.grey[300], shape: BoxShape.circle),
      child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }

  Widget _buildStepLine(int step) {
    bool active = _currentStatus > step;
    return Expanded(child: Container(height: 3, color: active ? Colors.black87 : Colors.grey[300]));
  }

  Widget _buildStepLabel(String text, int step) {
    bool active = _currentStatus >= step;
    return SizedBox(
      width: 75,
      child: Text(text, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black87 : Colors.grey),
      ),
    );
  }
}