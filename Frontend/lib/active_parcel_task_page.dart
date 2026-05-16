//14
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_page.dart'; 
import 'runner_proof_photo_page.dart';

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
  int currentStatus = 1; // track current order status step
  bool isLoading = false; // loading indicator for status update
  Map<String, dynamic>? liveOrder; // store real-time order data
  bool isPageLoading = true; // initial page loading state

  @override
  void initState() {
    super.initState();
    currentStatus = int.tryParse(widget.order['status_code'].toString()) ?? 1;
    if (currentStatus == 0) currentStatus = 1;
    _refreshData();
  }

  Future<void> _refreshData() async {
  try {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/order/detail/${widget.order['order_id']}'),
    );
    if (res.statusCode == 200) {
      setState(() {
        liveOrder = jsonDecode(res.body);
        currentStatus = liveOrder!['status_code'];
        isPageLoading = false;
      });
    }
  } catch (e) {
    setState(() => isPageLoading = false);
  }
}

  Future<void> _updateStatus(int nextS) async {
    if (nextS == 4) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunnerProofPhotoPage( // 你需要创建这个页面
          orderId: widget.order['order_id'].toString(),
          runnerId: widget.runnerId,
        ),
      ),
    );
    return;
  }

    setState(() => isLoading = true);
    final url = Uri.parse('http://10.0.2.2:5000/api/order/update_status');
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "status_code": nextS,
          "runner_id": widget.runnerId,
        }),
      );
      if (res.statusCode == 200) {
        setState(() {
          currentStatus = nextS;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      // --- AppBar ---
      appBar: AppBar(
        title: const Text(
          "Parcel Progress",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        // --- Chat Button ---
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage(
                studentID: widget.order['requester_id'], // 拿到下单人 ID
                runnerID: widget.runnerId,
              )),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // --- Background ----
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF3FF), 
              Color(0xFFD6E8FF), 
              Color(0xFFBFD9FF)
            ],
          ),
        ),
        // --- Main Content ---
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Order Summary Card ---
                _summaryCard("Parcel"),
                const SizedBox(height: 25),
                // --- Note Section ---
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
                // --- Step Buttons ---
                const SizedBox(height: 15),
                _stepBtn("1. ID Card Taken", 1, 2, Colors.green),
                const SizedBox(height: 12),
                _stepBtn("2. Parcel Taken", 2, 3, Colors.green),
                const SizedBox(height: 12),
                _stepBtn("3. Dropped (Finish)", 3, 4, Colors.green),
                const Spacer(),
                // --- Exit Button ---
                _escapeBtn(),
                // --- Loading Indicator ---
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

  // --- Summary Card UI ---
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
        _rowSummary("Customer", liveOrder?['customer_name'] ?? "Unknown"),
        const SizedBox(height: 8),
        _rowSummary("Dorm", liveOrder?['dropoff_point'] ?? "N/A"),
        const SizedBox(height: 8),
        _rowSummary( 
          "Collect",
          "RM ${double.tryParse(
              liveOrder?['total_to_collect'].toString() ?? '0'
            )?.toStringAsFixed(2) ?? '0.00'}",
            valueColor: Colors.green,
        ), 
        _rowSummary(
          "Profit",
          "RM ${double.tryParse(
              liveOrder?['runner_profit'].toString() ?? '0'
            )?.toStringAsFixed(2) ?? '0.00'}",
            valueColor: Colors.blue,
        ),
      ],
    ),
  );
  // --- Row Summary UI ---
  Widget _rowSummary(
    String l,
    String v, {
    Color valueColor = Colors.black,
  }) =>
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- Note Box UI ---
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

  // --- Step Button UI ---
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

  // --- Exit Button UI ---
  Widget _escapeBtn() => TextButton.icon(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.exit_to_app, color: Colors.black54),
    label: const Text(
      "Exit to Dashboard",
      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
    ),
  );
