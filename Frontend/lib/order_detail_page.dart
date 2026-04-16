import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'active_delivery_page.dart'; // 这里是送货页

class OrderDetailPage extends StatefulWidget {
  final Map order;
  // 组长的学号，作为跑腿 ID
  final String runnerID = "FIT2508089"; 

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ✨ 核心修改：价格计算逻辑对齐后端
    // 拿着 parcel_qty 去计算赏金
    int qty = int.tryParse(widget.order['parcel_qty']?.toString() ?? '1') ?? 1;
    
    // 如果是 Food，保留你原来的 +RM 5 逻辑；
    // 如果是 Parcel，使用你的件数规则 (qty < 5 ? qty*2.0 : qty*1.0)
    String type = widget.order['type'] ?? 'parcel';
    double earnedMoney = 0.0;
    
    if (type == 'parcel') {
      earnedMoney = qty < 5 ? qty * 2.0 : qty * 1.0;
    } else {
      double foodPrice = double.tryParse(widget.order['price']?.toString() ?? '0') ?? 0.0;
      earnedMoney = foodPrice + 5.00;
    }

    String typeTitle = type.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('$typeTitle Details'),
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Divider(height: 30, thickness: 1.5),
                    
                    // 1. 用户基本信息
                    _buildDetailRow("Name", widget.order['requester_name'] ?? "Pending Name"),
                    _buildDetailRow("ID", widget.order['requester'] ?? widget.order['student_id'] ?? "Pending ID"),
                    _buildDetailRow("Dorm", widget.order['dorm'] ?? "Pending Dorm"),
                    _buildDetailRow("Contact", widget.order['contact'] ?? "Pending Contact"),
                    
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 15),

                    // ✨ 核心修改 2：加上你心心念念的 Number of parcel！
                    if (type == 'parcel')
                      _buildDetailRow(
                        "Number of parcel", 
                        "$qty",
                        isHighlight: true, // 加个高亮
                      ),

                    const SizedBox(height: 15),
                    const Text("Stall / Info:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        widget.order['stall_name'] ?? widget.order['details'] ?? widget.order['call_upon_arrival'] ?? "Not specified", 
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 3. 赏金计算显示
                    const Text("Money to be received:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 5),
                    if (type == 'parcel')
                       Text("(RM 2.00 / parcel)", style: TextStyle(fontSize: 14, color: Colors.grey[600]))
                    else
                       Text("(Food Price + RM 5.00 fee)", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 5),
                    Text(
                      "RM ${earnedMoney.toStringAsFixed(2)}", 
                      style: const TextStyle(fontSize: 32, color: Colors.blueAccent, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 4. CONFIRM PICKUP 按钮
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleTakeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CONFIRM PICKUP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 接单逻辑
  Future<void> _handleTakeOrder() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/runner/take'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "order_id": widget.order['order_id'],
          "runner_id": widget.runnerID, 
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        // ✨ 核心修改 3：接单成功后，直接跳到 ActiveDeliveryPage，跳过图 2
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveDeliveryPage(order: widget.order),
          ),
        );
      } else {
        _showError("Failed to take order. Maybe someone else took it?");
      }
    } catch (e) {
      _showError("Network Error: Could not connect to server");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // 辅助构建行，增加了高亮选项
  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // 稍微调宽一点，容纳 Number of parcel
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.bold, 
                fontSize: 16, 
                color: isHighlight ? Colors.blueAccent : Colors.grey,
              ),
            ),
          ),
          const Text(":  ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontSize: isHighlight ? 18 : 16, 
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w500,
                color: isHighlight ? Colors.blueAccent : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}