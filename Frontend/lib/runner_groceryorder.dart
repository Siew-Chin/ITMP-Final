//19
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_grocerydrop.dart'; // 确保文件名正确

class RunnerGroceryOrder extends StatefulWidget {
  final String orderId;

  const RunnerGroceryOrder({super.key, required this.orderId});

  @override
  State<RunnerGroceryOrder> createState() => _RunnerGroceryOrderState();
}

class _RunnerGroceryOrderState extends State<RunnerGroceryOrder> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic> _orderData = {};

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  // --- 1. 获取订单详情 ---
  Future<void> _fetchOrderDetail() async {
    // 确保使用 10.0.2.2 访问电脑本地后端
    final String url =
        'http://10.0.2.2:5000/api/order/detail/${widget.orderId}';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _orderData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        debugPrint("Server return error: ${response.statusCode}");
        _loadMockData();
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _orderData = {
        "requester_id": "Test User (Mock)",
        "dropoff_point": "Block A, Level 3",
        "requester_contact": "012-3456789",
        "shop_name": "Lotus's Supermarket",
        "shopping_list": ["Milk x1", "Bread x2"],
        "delivery_fee": 5.00,
      };
      _isLoading = false;
    });
  }

  // --- 2. 核心修复：Take Order 逻辑 ---
  Future<void> _handleTakeOrder() async {
    setState(() => _isSubmitting = true);

    final String url = 'http://10.0.2.2:5000/api/order/take';

    try {
      // 这里的 body 必须与 Backend.py 的接收逻辑严格对应
      final response = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "order_id": widget.orderId, // 这里传的是从列表页解析出来的数据库 ID
              "status": 1, // 状态从 0 改为 1
              "runner_id": "FIT2508089", // 固定的学生 ID
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _showSnackBar("Order Accepted Successfully!");
        _navigateToDropPage();
      } else {
        // 如果后端返回 404/500，打印错误方便调试
        debugPrint("Update Failed: ${response.body}");
        _showSnackBar("Update failed. Entering Test Mode...");
        _navigateToDropPage();
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      _showSnackBar("Network error. Entering Test Mode...");
      _navigateToDropPage();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _navigateToDropPage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RunnerGroceryDrop(orderId: widget.orderId),
      ),
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 格式化清单逻辑
  String _formatShoppingList(dynamic list) {
    if (list == null) return "No items";
    if (list is List) {
      return list
          .map((e) {
            if (e is Map) return "• ${e['item_name'] ?? e.toString()}";
            return "• $e";
          })
          .join("\n");
    }
    return list.toString();
  }

  String _safeGet(dynamic value) {
    if (value == null) return "N/A";
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Order Detail',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // 订单基础信息卡片
                      _buildSectionCard(
                        child: Column(
                          children: [
                            _buildField(
                              'Name :',
                              _safeGet(_orderData['requester_id']),
                            ),
                            _buildField('Order ID :', widget.orderId),
                            _buildField(
                              'Dorm :',
                              _safeGet(_orderData['dropoff_point']),
                            ),
                            _buildField(
                              'Contact :',
                              _safeGet(_orderData['requester_contact']),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 购物清单卡片
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildField(
                              'Store :',
                              _safeGet(_orderData['shop_name']),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "To Buy list :",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildListView(
                              _formatShoppingList(_orderData['shopping_list']),
                            ),
                            const SizedBox(height: 15),
                            _buildField(
                              'Fee :',
                              "RM ${(_orderData['delivery_fee'] ?? 0.0) is num ? (_orderData['delivery_fee'] as num).toStringAsFixed(2) : '0.00'}",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildButton(),
                    ],
                  ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  // --- UI 构建组件 (保持原样) ---
  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(height: 1.5)),
    );
  }

  Widget _buildButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleTakeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Take Order",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
