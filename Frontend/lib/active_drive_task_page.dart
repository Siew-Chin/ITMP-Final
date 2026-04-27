import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

//18
class ActiveDriveTaskPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  const ActiveDriveTaskPage({
    Key? key,
    required this.order,
    required this.runnerId,
  }) : super(key: key);

  @override
  State<ActiveDriveTaskPage> createState() => _ActiveDriveTaskPageState();
}

class _ActiveDriveTaskPageState extends State<ActiveDriveTaskPage> {
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
        title: const Text("Ride Finished!"),
        content: const Text("Payment confirmed."),
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
          "Ride Progress",
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
                _summaryCard(),
                const SizedBox(height: 25),
                const Text(
                  "Note:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _noteBox(
                  "Please verify the passenger identity. Drive safely and follow traffic rules.\n\nCollect payment at the end of the ride.",
                ),
                const SizedBox(height: 35),
                const Text(
                  "Task Steps",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _stepBtn(
                  "1. Passenger Picked Up",
                  1,
                  2,
                  const Color(0xFF4A90E2),
                ),
                const SizedBox(height: 12),
                _stepBtn(
                  "2. Arrived at Destination",
                  2,
                  3,
                  const Color(0xFF4A90E2),
                ),
                const SizedBox(height: 12),
                _stepBtn("3. Finish Ride", 3, 4, const Color(0xFF4A90E2)),
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
        _rowSummary("Passenger", widget.order['customer_name'] ?? "BCD"),
        const SizedBox(height: 8),
        _rowSummary("To", widget.order['dropoff_point'] ?? "Kipmall"),
        const SizedBox(height: 8),
        _rowSummary("Earning", "RM ${widget.order['delivery_fee'] ?? '8.0'}"),
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
      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
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
    icon: const Icon(Icons.arrow_back, color: Colors.black54),
    label: const Text(
      "Return to Dashboard",
      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
    ),
  );
}
