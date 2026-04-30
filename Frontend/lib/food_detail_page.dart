import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'active_food_task_page.dart';

class FoodDetailPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  const FoodDetailPage({Key? key, required this.order, required this.runnerId})
    : super(key: key);

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  bool isDetailsConfirmed = false;

  Future<void> _takeOrder() async {
    // Line 20: Updated to API Route 5 (Update Status)
    final url = Uri.parse('http://10.0.2.2:5000/api/order/update_status');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "next_status": 1, // Uses 'next_status' as required by API List
          "runner_id": widget.runnerId,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveFoodTaskPage(
              order: widget.order,
              runnerId: widget.runnerId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4E6), Color(0xFFFFE8CC), Color(0xFFFFD8A8)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Food Detail",
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        Icons.restaurant,
                        "Stall",
                        widget.order['shop_name']?.toString() ?? "Subway",
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.location_on,
                        "Dropoff",
                        widget.order['dropoff_point']?.toString() ?? "G1 Dorm",
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      _row(
                        Icons.fastfood,
                        "Food Price",
                        "RM ${widget.order['food_price']?.toString() ?? '12.5'}",
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.account_balance_wallet,
                        "Your Earning",
                        "RM ${widget.order['delivery_fee']?.toString() ?? '3.0'}",
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      const Text(
                        "Order Details:",
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.order['shopping_list']?.toString() ??
                            "Extra spicy sauce please",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _noteBox(),
                      const SizedBox(height: 20),
                      _checkboxArea(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _btn(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
      ),
      child: const Text(
        "Note: Please check the food items carefully. Ensure the packaging is secure before delivery. Collect money from customer upon arrival.",
        style: TextStyle(
          fontSize: 13,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.black45, fontSize: 15),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF333333),
          ),
        ),
      ],
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
        activeColor: Colors.orange,
        onChanged: (v) => setState(() => isDetailsConfirmed = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _btn() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDetailsConfirmed
            ? Colors.orange
            : Colors.grey.shade300,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      onPressed: isDetailsConfirmed ? _takeOrder : null,
      child: const Text(
        "Take Food Order",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
