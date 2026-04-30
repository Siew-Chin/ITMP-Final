import 'package:flutter/material.dart';

class ParcelTrackingPage extends StatefulWidget {
  // 真实开发中，上一页在 Launch Order 成功后，应该把 orderId 传给这一页
  final String orderId; 
  final double totalPrice;

  const ParcelTrackingPage({
    super.key, 
    this.orderId = "ORD12345", // 暂时给个默认值
    this.totalPrice = 8.50,    // 暂时给个默认值
  });

  @override
  State<ParcelTrackingPage> createState() => _ParcelTrackingPageState();
}

class _ParcelTrackingPageState extends State<ParcelTrackingPage> {
  // 模拟从数据库获取的状态码 (1: 取单, 2: 拿ID卡, 3: 拿包裹, 4: 送达)
  int _currentStatus = 1; 
  bool _isLoading = false;

  // 模拟触发 API 4: 获取实时进度 (GET /api/order/tracking)
  Future<void> _fetchTrackingStatus() async {
    setState(() {
      _isLoading = true;
    });

    // 模拟网络请求延迟 1.5 秒
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      // 模拟跑腿员更新了状态 (这里为了演示，每次下拉刷新状态+1，直到4)
      if (_currentStatus < 4) {
        _currentStatus++; 
      }
      _isLoading = false;
    });
    
    // 真实场景下，你这里会发送 GET 请求到你的 Flask 后端：
    // var response = await http.get(Uri.parse('http://10.0.2.2:5000/api/order/tracking?order_id=${widget.orderId}'));
    // var data = jsonDecode(response.body);
    // setState(() { _currentStatus = data['status_code']; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Parcel Taking',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // 聊天标志 (Live Chat)
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onPressed: () {
              print("Open Live Chat with Runner!");
              // 之后这里可以跳转到你的 Chat Page
            },
          ),
        ],
      ),
      // 加入下拉刷新组件，连着你的 API 4
      body: RefreshIndicator(
        onRefresh: _fetchTrackingStatus,
        color: Colors.blue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 确保即使内容很少也能下拉刷新
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 订单号提示
              Center(
                child: Text(
                  "Order: ${widget.orderId}",
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // 下拉刷新提示
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe_down, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Swipe down to refresh status",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 横向 4 点进度条 (Timeline)
              _buildTimeline(),
              const SizedBox(height: 40),

              // 显示总价
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1), 
                      blurRadius: 10, 
                      spreadRadius: 2
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Price",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    Text(
                      "RM ${widget.totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), // 留出空间给底部的按钮
            ],
          ),
        ),
      ),
      
      // 底部 Continue 按钮
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            // 核心逻辑：只有当 _currentStatus == 4 时，onPressed 才有动作，按钮才会变深色
            onPressed: _currentStatus == 4
                ? () {
                    print("Order Completed! Proceeding to next page...");
                    // 连着你的 API 7 或跳转到评价页面
                  }
                : null, // null 会自动让按钮变成灰色/浅色 (Disabled 状态)
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A), // 深蓝色
              disabledBackgroundColor: Colors.grey[300], // 未完成时的浅色
              disabledForegroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: _currentStatus == 4 ? 5 : 0,
            ),
            child: Text(
              _currentStatus == 4 ? "Continue" : "Waiting for Runner...",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // 帮您手写的一个超美观的横向进度条组件
  Widget _buildTimeline() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(1),
            _buildLine(1),
            _buildDot(2),
            _buildLine(2),
            _buildDot(3),
            _buildLine(3),
            _buildDot(4),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Order\nTaken", 1),
            _buildLabel("ID\nTaken", 2),
            _buildLabel("Parcel\nTaken", 3),
            _buildLabel("Dropped", 4),
          ],
        ),
      ],
    );
  }

  // 画点 (灰色变黑色)
  Widget _buildDot(int step) {
    bool isCompleted = _currentStatus >= step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.black87 : Colors.grey[300],
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? Colors.black87 : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: isCompleted 
          ? const Icon(Icons.check, size: 14, color: Colors.white) 
          : null,
    );
  }

  // 画线
  Widget _buildLine(int step) {
    bool isCompleted = _currentStatus > step;
    return Expanded(
      child: Container(
        height: 4,
        color: isCompleted ? Colors.black87 : Colors.grey[300],
      ),
    );
  }

  // 画文字标签
  Widget _buildLabel(String text, int step) {
    bool isCompleted = _currentStatus >= step;
    return SizedBox(
      width: 60,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          color: isCompleted ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}