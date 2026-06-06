//12
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'chat_page.dart'; 
import 'user_proof_photo_page.dart'; // 确保你有这个页面
import 'package:stream_chat_flutter/stream_chat_flutter.dart'; // 导入 StreamChatClient

class FoodTrackingPage extends StatefulWidget {
  final String orderId;
  final double totalPrice;
  final String studentID; // 补充必填的 studentID
  final StreamChatClient client; // 补充必填的 StreamChatClient

  const FoodTrackingPage({
    super.key,
    required this.orderId,      
    required this.totalPrice,   
    required this.studentID,
    required this.client,
  });

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  // 状态码 (1: Order Taken, 2: Food Ordered, 3: Food Delivering, 4: Order Dropped)
  int _currentStatus = 0; 
  String? _runnerId;
  String? _proofImageUrl; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchFoodStatus(); // 初始化查询
    // 设置每 3 秒轮询一次 API 4
    _timer = Timer.periodic(const Duration(seconds: 3), (t) => _fetchFoodStatus());
  }

  @override
  void dispose() {
    _timer?.cancel(); // 销毁页面时停止轮询
    super.dispose();
  }

  // --- API 调用：获取实时进度 ---
  Future<void> _fetchFoodStatus() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/order/tracking/${widget.orderId}');//API4: GetProgress
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _currentStatus = data['status_code'] ?? 0;
            _runnerId = data['runner_id'];
            _proofImageUrl = data['proof_photo'];
          });
        }
      }
    } catch (e) {
      debugPrint("Food Polling error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      //Top Header
      appBar: AppBar(
        title: const Text(
          'Food Delivering', 
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold
            )
          ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton.icon(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, color: Colors.black),
            label: const Text(
              "Exit",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          if (_currentStatus > 0 && _runnerId != null) 
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
              onPressed: () {
                final String targetRunnerId = _runnerId?.toString() ?? '';

                if (targetRunnerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Waiting for driver to connect...")),
                  );
                  return;
                }

                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      currentUserId: widget.studentID,
                      otherUserId: targetRunnerId, // ✅ 使用处理后的 ID
                      client: widget.client,
                    )
                  ),
                );
              },
            ),
        ],
      ),
      // --- Background Gradient ---
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight, 
            colors:[
            Color(0xFFEAF3FF),
            Color(0xFFD6E8FF),
            Color(0xFFBFD9FF),
            ],
          ),
        ),
        // --- Main Content ---
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchFoodStatus,
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
                  _buildFoodTimeline(),
                  const SizedBox(height: 50),
                  _buildPriceCard(),
                ],
              ),
            ),
          ),
        ),
      ),
      // --- Bottom Button ---
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- Card showing total price ---
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
        ],
      ),
    );
  }

  // --- Bottom Button ---
  Widget _buildBottomButton() {
    bool canContinue = _currentStatus == 4 && _proofImageUrl != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: canContinue ? () {
              _timer?.cancel();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProofPhotoPage(
                    studentID: widget.studentID,
                    orderId: widget.orderId,
                    imageUrl: _proofImageUrl!,
                    client: widget.client,
                  ),
                ),
              );
            } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(
            _currentStatus == 4 
            ? "Receive & View Proof" 
            : "Food is on the way...",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- Food Timeline ---
  Widget _buildFoodTimeline() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepDot(1), _buildStepLine(1), _buildStepDot(2), _buildStepLine(2), _buildStepDot(3), _buildStepLine(3), _buildStepDot(4),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepLabel("Order\nTaken", 1),
            _buildStepLabel("Food\nOrdered", 2),
            _buildStepLabel("Food\nDelivering", 3),
            _buildStepLabel("Order\nDropped", 4),
          ],
        ),
      ],
    );
  }

  // --- Step Dot UI ---
  Widget _buildStepDot(int step) {
    bool active = _currentStatus >= step;
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: active ? Colors.black87 : Colors.grey[300], shape: BoxShape.circle),
      child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }

  // --- Step Line UI ---
  Widget _buildStepLine(int step) {
    bool active = _currentStatus > step;
    return Expanded(child: Container(height: 3, color: active ? Colors.black87 : Colors.grey[300]));
  }

   // --- Step Label UI ---
  Widget _buildStepLabel(String text, int step) {
    bool active = _currentStatus >= step;
    return SizedBox(
      width: 70,
      child: Text(text, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black87 : Colors.grey),
      ),
    );
  }
}