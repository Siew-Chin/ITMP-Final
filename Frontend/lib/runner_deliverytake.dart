//21
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_deliverydrop.dart'; 
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class RunnerDeliveryTake extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  final StreamChatClient client;
  const RunnerDeliveryTake({
    Key? key, 
    required this.order, 
    required this.runnerId,
    required this.client})
      : super(key: key);

  @override
  State<RunnerDeliveryTake> createState() => _RunnerDeliveryTakeState();
}

class _RunnerDeliveryTakeState extends State<RunnerDeliveryTake> {
  bool isDetailsConfirmed = false;
  Map<String, dynamic>? detailedOrder;
  bool isLoading = true;

  double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/order/detail/${widget.order['order_id']}',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          detailedOrder = jsonDecode(response.statusCode == 200 ? response.body : "{}");
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _takeOrder() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/order/update_status');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "status_code": 1,
          "runner_id": widget.runnerId,
        }),
      );

      // 如果后端返回 400 或特定的错误码，说明订单状态已改变
      if (response.statusCode == 200) {
        // 成功领单
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RunnerDeliveryDrop(
              client: widget.client,
              order: detailedOrder ?? widget.order,
              runnerId: widget.runnerId,
            ),
          ),
        );
      } else {
        // 解析后端返回的消息，检查是否被取消
        final data = jsonDecode(response.body);
        
        // 假设后端在订单被取消时返回 status_code: -1 或者特定的 message
        if (data['current_status'] == -1 || response.statusCode == 400) {
          _showCancelDialog();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 弹出取消提示框
  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 强制用户点击按钮
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Order Cancelled"),
          ],
        ),
        content: const Text("Sorry, the user has already cancelled this order."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to runner page inside ServicePage
            },
            child: const Text(
              "Back to Menu",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double runnerProfit = _parsePrice(
      detailedOrder?['runner_profit'] ?? widget.order['runner_profit'],
    );

    double totalToCollect = _parsePrice(
      detailedOrder?['total_to_collect'] ?? widget.order['total_to_collect'],
    );

    bool isUrgent =
        detailedOrder?['is_urgent'] ?? widget.order['is_urgent'] ?? false;
        
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black87),),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FF), Color(0xFFD6E8FF), Color(0xFFBFD9FF)],
          ),
        ),
        child: SafeArea(
          bottom: false, // Fix: Allow gradient to bleed into the bottom navigation area
          child: isLoading 
            ? const Center(child: CircularProgressIndicator()) // 增加 Loading 显示
            : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Item Details",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        Icons.person,
                        "Customer",
                        (detailedOrder?['customer_name'] ?? widget.order['customer_name'] ?? "Loading...")
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.phone,
                        "Contact",
                        (detailedOrder?['requester_contact'] ?? widget.order['requester_contact'] ?? "123"),
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      _row(
                        Icons.location_on,
                        "Pickup Location",
                        (detailedOrder?['pickup_point']
                            ?? widget.order['pickup_point']
                            ?? "Unknown Location"),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.home,
                        "Dropoff Location",
                        (detailedOrder?['dropoff_point'] ?? widget.order['dropoff_point'] ?? "D1 Dorm"),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.person,
                        "Quantity",
                        (detailedOrder?['parcel_qty'] ?? widget.order['parcel_qty'] ?? 0).toString(),
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      const Text(
                        "Item Details:",
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        (detailedOrder?['item_details'] ?? widget.order['item_details'] ?? "No details available"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      // --- Pricing Section ---

                      _row(
                        Icons.attach_money,
                        "Your Profit",
                        "RM ${runnerProfit.toStringAsFixed(2)}",
                      ),

                      if (isUrgent)
                        const SizedBox(height: 10),

                      if (isUrgent)
                        _row(
                          Icons.bolt,
                          "Urgent Included",
                          "YES",
                        ),

                      const Divider(height: 30, color: Colors.black12),

                      _row(
                        Icons.payments,
                        "Total To Collect",
                        "RM ${totalToCollect.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 25),
                      _noteBox(totalToCollect),
                      const SizedBox(height: 20),
                      _checkboxArea(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _btn(),
                const SizedBox(height: 40), // Bottom padding for clean look
              ],
            ),
          ),
        ),
      ),
    );
  }

   Widget _noteBox(double collectAmount) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.redAccent.withValues(alpha: 0.15),
      ),
    ),
    child: Text(
      "Notice: Please collect RM ${collectAmount.toStringAsFixed(2)} from the customer after delivery.",
      style: const TextStyle(
        fontSize: 13,
        color: Colors.redAccent,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

  Widget _row(IconData icon, String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C8EF5), size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _checkboxArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: const Text(
          "I have read the details",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        value: isDetailsConfirmed,
        activeColor: const Color(0xFF4A90E2),
        onChanged: (v) => setState(() => isDetailsConfirmed = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _btn() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDetailsConfirmed
            ? const Color(0xFF4A90E2)
            : Colors.grey.shade300,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      onPressed: isDetailsConfirmed ? () async {
        // 1. 先刷新数据
        await _fetchOrderDetails();
        // 2. 检查状态
        if (detailedOrder?['status_code'] == -1) {
          _showCancelDialog();
        } else {
          // 3. 没被取消，正常领单
          _takeOrder();
        }
      } : null,
      child: const Text(
        "Take Order",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}