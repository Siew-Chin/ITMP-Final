//11
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'chat_page.dart';
import 'user_proof_photo_page.dart';

class TrackingDeliveryPage extends StatefulWidget {
  final String orderId;
  final String studentID; // 必填：用于 Chat
  final double totalPrice; // 初始价格

  const TrackingDeliveryPage({
    super.key, 
    required this.orderId, 
    required this.studentID,
    required this.totalPrice,
  });

  @override
  State<TrackingDeliveryPage> createState() => _TrackingDeliveryPageState();
}

class _TrackingDeliveryPageState extends State<TrackingDeliveryPage> {
  // 状态码 (1: Order Taken, 2: Food Ordered, 3: Food Delivering, 4: Order Dropped)
  int _currentStatus = 0; 
  String? _runnerId;
  String? _proofImageUrl; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus(); // 初始化查询
    // 设置每 3 秒轮询一次 API 4
    _timer = Timer.periodic(const Duration(seconds: 3), (t) => _fetchOrderStatus());
  }

  @override
  void dispose() {
    _timer?.cancel(); // 销毁页面时停止轮询
    super.dispose();
  }

  // --- API 调用：获取实时进度 ---
  Future<void> _fetchOrderStatus() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/order/tracking/${widget.orderId}');
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
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Item Delivering', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Chat 按钮逻辑：只有有人接单且获取到 runnerId 才能聊天
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
        onRefresh: _fetchOrderStatus,
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

              // 进度条
              _buildItemTimeline(),

              const SizedBox(height: 50),

              // 价格卡片
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
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    // 只有状态为 4 且后端上传了照片才能点击 Continue
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
            _currentStatus == 4 ? "Receive & View Proof" : "Item is delivering...",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- 进度条构建组件 ---
  Widget _buildItemTimeline() {
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
            _buildStepLabel("Item\nPicking", 2),
            _buildStepLabel("Item\nPicked", 3),
            _buildStepLabel("Order\nDropped", 4),
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
      width: 70,
      child: Text(text, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black87 : Colors.grey),
      ),
    );
  }
}