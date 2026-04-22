import 'package:flutter/material.dart';

class FoodTrackingPage extends StatefulWidget {
  final String orderId;
  final double totalPrice;

  const FoodTrackingPage({
    super.key,
    this.orderId = "FOOD789", // 默认订单号
    this.totalPrice = 0.0,    // 接收上一页传来的总价
  });

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  // 模拟状态码 (1: Order Taken, 2: Food Ordered, 3: Food Delivering, 4: Order Dropped)
  int _currentStatus = 1;
  bool _isLoading = false;

  // 模拟执行 API 4: 获取实时进度 (GET /api/order/tracking)
  Future<void> _fetchFoodStatus() async {
    setState(() {
      _isLoading = true;
    });

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      // 模拟跑腿员在另一端操作，状态递增
      if (_currentStatus < 4) {
        _currentStatus++;
      }
      _isLoading = false;
    });
    
    // 实际对接时使用：
    // var response = await http.get(Uri.parse('.../api/order/tracking?order_id=${widget.orderId}'));
    // setState(() { _currentStatus = jsonDecode(response.body)['status_code']; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Food Delivering', // 顶部标题
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Chat 标志
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onPressed: () => print("Open Chat with Runner"),
          ),
        ],
      ),
      // 下拉刷新组件
      body: RefreshIndicator(
        onRefresh: _fetchFoodStatus,
        color: Colors.blue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
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
              const SizedBox(height: 10),
              // 下拉刷新提示
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_double_arrow_down, color: Colors.grey, size: 16),
                    Text(" Swipe down to refresh status", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 4 点进度图 (点与横线连接)
              _buildFoodTimeline(),

              const SizedBox(height: 50),

              // 订单总价显示卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Order Total",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    Text(
                      "RM ${widget.totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 底部 Receive 按钮
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            // 逻辑：只有 4 个点全部黑完 (_currentStatus == 4) 才能点击
            onPressed: _currentStatus == 4 
              ? () => print("Order Received!") 
              : null, 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A), // 深蓝色
              disabledBackgroundColor: Colors.grey[300], // 浅色 (未完成状态)
              disabledForegroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: _currentStatus == 4 ? 5 : 0,
            ),
            child: Text(
              _currentStatus == 4 ? "Receive" : "Food is on the way...",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // 构建外卖专用进度条
  Widget _buildFoodTimeline() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepDot(1),
            _buildStepLine(1),
            _buildStepDot(2),
            _buildStepLine(2),
            _buildStepDot(3),
            _buildStepLine(3),
            _buildStepDot(4),
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

  Widget _buildStepDot(int step) {
    bool active = _currentStatus >= step;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: active ? Colors.black87 : Colors.grey[300],
        shape: BoxShape.circle,
      ),
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
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}