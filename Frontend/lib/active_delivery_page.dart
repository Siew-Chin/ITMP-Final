import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_main_menu.dart';

class ActiveDeliveryPage extends StatelessWidget {
  final Map order; // 接收完整的订单数据

  const ActiveDeliveryPage({
    super.key,
    required this.order,
  });

  // 1. 获取跑腿 ID (Runner ID)
  String get runnerId => "FIT2508089"; 

  // 2. 动态计算金额 (逻辑必须与详情页完全一致)
  double get totalMoney {
    int qty = int.tryParse(order['parcel_qty']?.toString() ?? '1') ?? 1;
    String type = order['type'] ?? 'parcel';
    
    if (type == 'parcel') {
      return qty < 5 ? qty * 2.0 : qty * 1.0;
    } else {
      double foodPrice = double.tryParse(order['price']?.toString() ?? '0') ?? 0.0;
      return foodPrice + 5.00;
    }
  }

  // 🛠️ API 调用：点击 Dropped 更新状态
  Future<void> _updateToDropped(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/runner/dropped'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"order_id": order['order_id']}),
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RunnerMainMenu(studentID: runnerId)),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String type = (order['type'] ?? 'parcel').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Active Delivery'),
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 💡 重点修改：这里是那个带警告图标的卡片
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
                    const SizedBox(height: 10),
                    const Text(
                      "Important Notes",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 30),
                    
                    // 💡 重点修改：根据类型显示不同的提示文案
                    Text(
                      type == 'parcel'
                          ? "1. Please go to the dorm to collect Student ID or Staff ID.\n\n2. After collecting the parcel, please drop it at the dorm and remember to collect money."
                          : "1. Please remember to get the receipt from the food stall.\n\n2. After dropping the food, remember to collect money from the customer.",
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // 💡 重点修改：金额同步！
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text("Amount to Collect:", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(
                            "RM ${totalMoney.toStringAsFixed(2)}", // 这里会显示 RM 2.00
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // 下方的大按钮
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _updateToDropped(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("MARK AS DROPPED", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}