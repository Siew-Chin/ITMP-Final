import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

//16
class ActiveFoodTaskPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  const ActiveFoodTaskPage({
    Key? key,
    required this.order,
    required this.runnerId,
  }) : super(key: key);

  @override
  State<ActiveFoodTaskPage> createState() => _ActiveFoodTaskPageState();
}

class _ActiveFoodTaskPageState extends State<ActiveFoodTaskPage> {
  int currentStatus = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentStatus = int.tryParse(widget.order['status_code'].toString()) ?? 1;
    if (currentStatus == 0) currentStatus = 1;
  }

  Future<void> _updateStatus(int s) async {
    setState(() => isLoading = true);
    final url = Uri.parse('http://10.0.2.2:5000/api/order/update_status');
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "next_status": s,
          "runner_id": widget.runnerId,
        }),
      );
      if (res.statusCode == 200) {
        setState(() {
          currentStatus = s;
          isLoading = false;
        });
        if (s == 4) _finish();
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _finish() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delivered!"),
        content: const Text("Earnings added to your wallet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Food Progress",
          style: TextStyle(color: Colors.black87),
        ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryCard(),
                const SizedBox(height: 25),
                const Text(
                  "Note:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _noteBox(
                  "Please check the food items carefully. Ensure the packaging is secure before delivery.\n\nCollect money from customer upon arrival.",
                ),
                const SizedBox(height: 35),
                const Text(
                  "Task Steps",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _stepBtn("1. Food Collected", 1, 2, Colors.orange),
                const SizedBox(height: 12),
                _stepBtn("2. Arrived at Dorm", 2, 3, Colors.orange),
                const SizedBox(height: 12),
                _stepBtn("3. Delivered (Finish)", 3, 4, Colors.orange),
                const Spacer(),
                _escapeBtn(),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
      ],
    ),
    child: Column(
      children: [
        _rowSummary("Stall", widget.order['shop_name'] ?? "Subway"),
        const SizedBox(height: 8),
        _rowSummary("Dorm", widget.order['dropoff_point'] ?? "G1 Dorm"),
        const SizedBox(height: 8),
        _rowSummary("Collect", "RM ${widget.order['total_price'] ?? '15.5'}"),
      ],
    ),
  );
  Widget _rowSummary(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      Text(
        v,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ],
  );
  Widget _noteBox(String t) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
    ),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    ),
  );
  Widget _stepBtn(String l, int a, int t, Color c) {
    bool done = currentStatus > a;
    bool active = currentStatus == a;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: done
            ? Colors.grey.shade400
            : (active ? c : Colors.white.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: active ? () => _updateStatus(t) : null,
      child: Text(
        done ? "$l (Done)" : l,
        style: TextStyle(
          color: (active || done) ? Colors.white : Colors.black45,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _escapeBtn() => TextButton.icon(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.close, color: Colors.black54),
    label: const Text(
      "Back to Menu",
      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
    ),
  );
}
