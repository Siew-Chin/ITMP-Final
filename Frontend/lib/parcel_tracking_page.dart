import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'chat_page.dart'; 
import 'user_proof_photo_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ParcelTrackingPage extends StatefulWidget {
  final String orderId;
  final double totalPrice;
  final String studentID;
  final StreamChatClient client;

  const ParcelTrackingPage({
    super.key,
    required this.orderId,      
    required this.totalPrice,   
    required this.studentID,
    required this.client,
  });

  @override
  State<ParcelTrackingPage> createState() => _ParcelTrackingPageState();
}

class _ParcelTrackingPageState extends State<ParcelTrackingPage> {
  // 状态码 (0: Waiting, 1: Order Taken, 2: ID Taken, 3: Parcel Taken, 4: Dropped)
  int _currentStatus = 0; 
  String? _runnerId;
  String? _proofImageUrl; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchParcelStatus(); 
    // 设置每 3 秒轮询一次
    _timer = Timer.periodic(const Duration(seconds: 3), (t) => _fetchParcelStatus());
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  // --- API 调用：获取实时进度 ---
  Future<void> _fetchParcelStatus() async {
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
      debugPrint("Parcel Polling error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // 统一背景颜色
      appBar: AppBar(
        title: const Text('Parcel Tracking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          // Chat 按钮逻辑：只有有人接单且获取到 runnerId 才能聊天
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
      body: RefreshIndicator(
        onRefresh: _fetchParcelStatus,
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

              // 第一点：判断是否在等待中
              if (_currentStatus == 0) 
                _buildWaitingContent() 
              else 
                _buildTrackingContent(),

              const SizedBox(height: 50),

              // 价格卡片：使用 Total To Collect
              _buildPriceCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- 等待接单时的显示内容 ---
  Widget _buildWaitingContent() {
    return Column(
      children: [
        const CircularProgressIndicator(color: Colors.orange),
        const SizedBox(height: 30),
        const Text(
          "Finding a Runner...",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Text(
            "We are notifying nearby runners about your parcel order. Please stay on this page.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }

  // --- 接单后的追踪内容 ---
  Widget _buildTrackingContent() {
    return Column(
      children: [
        const Text(
          "Runner is handling your parcel",
          style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 30),
        _buildParcelTimeline(),
      ],
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
            "Total To Collect", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)
          ),
          Text(
            "RM ${widget.totalPrice.toStringAsFixed(2)}", 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)
          ),
        ],
      ),
    );
  }

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
            _currentStatus == 4 ? "Receive & View Proof" : "Waiting for Runner...",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- 进度条构建组件 (Parcel 专用) ---
  Widget _buildParcelTimeline() {
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
            _buildStepLabel("ID\nTaken", 2),
            _buildStepLabel("Parcel\nTaken", 3),
            _buildStepLabel("Dropped", 4),
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