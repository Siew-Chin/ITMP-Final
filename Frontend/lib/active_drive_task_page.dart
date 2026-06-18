//18
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_page.dart'; 
import 'runner_payment_confirm_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ActiveDriveTaskPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  final StreamChatClient client;
  const ActiveDriveTaskPage({
    Key? key,
    required this.order,
    required this.runnerId,
    required this.client,
  }) : super(key: key);

  @override
  State<ActiveDriveTaskPage> createState() => _ActiveDriveTaskPageState();
}

class _ActiveDriveTaskPageState extends State<ActiveDriveTaskPage> {
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
        Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/order/detail/${widget.order['order_id']}'),//API 20: runner side get order detail
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', 
        },
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
    //Update order status and navigator to payment confirmation page
    setState(() => isLoading = true);
    final url = Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/order/update_status'); //API 5: Update Status
    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
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

        if (nextS == 4) {

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RunnerPaymentConfirmPage(
                studentID: widget.runnerId,
                orderId: widget.order['order_id'].toString(),
                amount: double.tryParse(widget.order['delivery_fee'].toString()) ?? 0.0,
                customerName: widget.order['customer_name'] ?? "User",
                customerStudentID: liveOrder?['requester_id']?.toString() ?? widget.order['requester_id']?.toString() ?? "N/A",
                customerContact: widget.order['requester_contact']?.toString() ?? "N/A",
                client: widget.client,
              ),
            ),
          );
        } else {
          setState(() => isLoading = false);
          
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Update Error: $e");
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
          "Ride Progress",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        // --- Chat Button in AppBar ---
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              final String targetId = liveOrder?['requester_id']?.toString() ?? 
                                      widget.order['requester_id']?.toString() ?? 
                                      '';
              if (targetId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: Requester ID not found")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatPage(
                  client: widget.client,
                  currentUserId: widget.runnerId,
                  otherUserId: targetId,
                )),
              );
            },
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
        child: SafeArea(
          child: SingleChildScrollView( 
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Order SUmmary Card ---
                  _summaryCard("Ride"),
                  const SizedBox(height: 25),
                  // --- Note Box ---
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
                    "Please verify the passenger identity. Drive safely and follow traffic rules.\n\nCollect payment at the end of the ride.",
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    "Task Steps",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _stepBtn(
                    "1. Picking Up Passenger",
                    1,
                    2,
                    const Color(0xFF4A90E2),
                  ),
                  const SizedBox(height: 12),
                  _stepBtn(
                    "2. Arrive at Pickup Point",
                    2,
                    3,
                    const Color(0xFF4A90E2),
                  ),
                  const SizedBox(height: 12),
                  _stepBtn("3. Finish Ride", 3, 4, const Color(0xFF4A90E2)),
                  const SizedBox(height: 40),
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
      ),
    );
  }

   // --- UI ---
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
        _rowSummary("Contact", liveOrder?['requester_contact'] ?? "N/A"),
        const SizedBox(height: 8),
        _rowSummary("Pickup Point", liveOrder?['pickup_point'] ?? "N/A"),
        const SizedBox(height: 8),
        _rowSummary("Dropoff Point", liveOrder?['dropoff_point'] ?? "N/A"),
        const SizedBox(height: 8),
        _rowSummary("Ride Details", liveOrder?['ride_details'] ?? "N/A"),
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
  // --- Reusable UI components ---
  Widget _rowSummary(
    String l,
    String v, {
      Color valueColor = Colors.black,
    }
  ) =>
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
  // --- Note Box and Step Button ---
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
   // --- Exit Button ---
  Widget _escapeBtn() => TextButton.icon(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.exit_to_app, color: Colors.black54),
    label: const Text(
      "Return to Marketplace",
      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
    ),
  );
}
