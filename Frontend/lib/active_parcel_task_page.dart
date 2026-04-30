import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

//14
class ActiveParcelTaskPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  const ActiveParcelTaskPage({
    Key? key,
    required this.order,
    required this.runnerId,
  }) : super(key: key);

  @override
  State<ActiveParcelTaskPage> createState() => _ActiveParcelTaskPageState();
}

class _ActiveParcelTaskPageState extends State<ActiveParcelTaskPage> {
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
        title: const Text("Task Completed!"),
        content: const Text(
          "Great job. The money will be added to your account.",
        ),
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
          "Parcel Progress",
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
            colors: [Color(0xFFEAF3FF), Color(0xFFD6E8FF), Color(0xFFBFD9FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryCard("Parcel"),
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
                  "Please go to the dorm and take the student ID card to get the parcel.\n\nAfter drop the parcel, remember to collect money from customer.",
                ),
                const SizedBox(height: 35),
                const Text(
                  "Task Steps",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _stepBtn("1. ID Card Taken", 1, 2, Colors.green),
                const SizedBox(height: 12),
                _stepBtn("2. Parcel Taken", 2, 3, Colors.green),
                const SizedBox(height: 12),
                _stepBtn("3. Dropped (Finish)", 3, 4, Colors.green),
                const Spacer(),
                _escapeBtn(),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String type) => Container(
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
        _rowSummary("Customer", widget.order['customer_name'] ?? "ABC"),
        const SizedBox(height: 8),
        _rowSummary("Dorm", widget.order['dropoff_point'] ?? "D1 Dorm"),
        const SizedBox(height: 8),
        _rowSummary("Collect", "RM ${widget.order['total_price'] ?? '5.0'}"),
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
  Widget _noteBox(String text) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
    ),
    child: Text(
      text,
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
    icon: const Icon(Icons.exit_to_app, color: Colors.black54),
    label: const Text(
      "Exit to Dashboard",
      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
    ),
  );
}
