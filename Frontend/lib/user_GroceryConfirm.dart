//9
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // 导入 Timer 用于自动刷新

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery Confirm UI',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F8FF),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const UserGroceryConfirm(
        orderId: "TEMP_ID_123",
      ), // 实际运行时请传入真实的 orderId
    );
  }
}

class UserGroceryConfirm extends StatefulWidget {
  final String? orderId; // 接收从下单页面传过来的 ID
  const UserGroceryConfirm({super.key, this.orderId});

  @override
  State<UserGroceryConfirm> createState() => _UserGroceryConfirmState();
}

class _UserGroceryConfirmState extends State<UserGroceryConfirm> {
  int currentStatus = 0;
  Timer? _timer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // 1. 页面打开时立刻查一次
    _fetchOrderStatus();
    // 2. 开启定时器，每 5 秒自动检查一次状态更新进度条
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchOrderStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 销毁页面时必须停止定时器，防止内存泄漏
    super.dispose();
  }

  // --- 对接后端：获取订单实时进度 ---
  Future<void> _fetchOrderStatus() async {
    if (_isSyncing) return;

    // 注意：此处 URL 对应你朋友文档编号 4：获取实时进度
    // 如果是模拟器用 10.0.2.2
    final String url =
        'http://10.0.2.2:5000/api/order/tracking?order_id=${widget.orderId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // 假设后端返回 {"status_code": 2, ...}
          currentStatus = data['status_code'] ?? 0;
        });
      }
    } catch (e) {
      print("Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Item Delivering',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // 使用 RefreshIndicator 实现你手绘的“下拉刷新”
      body: RefreshIndicator(
        onRefresh: _fetchOrderStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 确保内容不满也能下拉
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 进度条卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProgressLine(),
                    const SizedBox(height: 10),
                    const Text(
                      "swipe down to refresh",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Chat 按钮
              _buildActionButton(
                text: "Chat",
                color: Colors.white,
                textColor: Colors.blue,
                onPressed: () {
                  // TODO: 跳转到 Chat 页面
                },
                isBordered: true,
              ),
              const SizedBox(height: 20),

              // Received 按钮 (仅在状态为 4 时亮起)
              _buildActionButton(
                text: "Received",
                color: currentStatus >= 4
                    ? const Color(0xFF1A237E)
                    : Colors.grey.shade400,
                textColor: Colors.white,
                onPressed: currentStatus >= 4
                    ? () {
                        // TODO: 调用后端 API 确认收货并结束订单
                        print("Order Completed!");
                      }
                    : null,
                isBordered: false,
              ),
              const SizedBox(height: 40),

              // 底部提醒
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF00796B)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reminder: Your amount to pay is RM : ......',
                        style: TextStyle(
                          color: Color(0xFF00796B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 以下 UI 构建代码保持逻辑一致，但通过 currentStatus 驱动渲染 ---

  Widget _buildProgressLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep(1, "Order\nTaken"),
        _buildLine(1),
        _buildStep(2, "Picking\nUp"),
        _buildLine(2),
        _buildStep(3, "Item\nPicked"),
        _buildLine(3),
        _buildStep(4, "Item\nDropped"),
      ],
    );
  }

  Widget _buildStep(int stepIndex, String label) {
    bool isActive = currentStatus >= stepIndex;
    return Column(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.black : Colors.grey.shade400,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int lineIndex) {
    bool isActive = currentStatus > lineIndex;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.black : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 25),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
    required bool isBordered,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isBordered
                ? const BorderSide(color: Colors.blue)
                : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
