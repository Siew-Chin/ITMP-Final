import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class TrackingDeliveryPage extends StatefulWidget {
  final String orderId;
  const TrackingDeliveryPage({Key? key, required this.orderId})
    : super(key: key);

  @override
  _TrackingDeliveryPageState createState() => _TrackingDeliveryPageState();
}

class _TrackingDeliveryPageState extends State<TrackingDeliveryPage> {
  int currentStatus = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _fetchProgress(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProgress() async {
    final url = Uri.parse(
      'http://10.0.2.2:5000/api/order/tracking?order_id=${widget.orderId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          currentStatus = jsonDecode(response.body)['status_code'] ?? 0;
        });
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
        title: const Text(
          "Track Delivery",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- MODERN TIMELINE ---
                  _buildTimeline(),

                  const SizedBox(height: 50),

                  // --- GLOWING CHAT BUTTON ---
                  InkWell(
                    onTap: () {}, // Navigate to Chat
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Chat with Runner",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Reminder: Amount to pay",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Text(
                    "RM 5.00",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- RECEIVED BUTTON (Only shows when status is 4) ---
                  if (currentStatus == 4) _buildReceivedButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    List<String> labels = ["Taken", "Picking", "Picked", "Dropped"];
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background line
            Container(
              height: 3,
              width: double.infinity,
              color: Colors.grey[300],
            ),
            // Progress line
            Row(
              children: [
                Expanded(
                  flex: currentStatus > 0 ? currentStatus - 1 : 0,
                  child: Container(height: 3, color: Colors.blueAccent),
                ),
                Expanded(flex: 4 - currentStatus, child: Container()),
              ],
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                bool isActive = currentStatus >= (index + 1);
                return _buildDot(isActive);
              }),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (label) => Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: labels.indexOf(label) + 1 <= currentStatus
                        ? Colors.blueAccent
                        : Colors.grey[400],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: active ? Colors.blueAccent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? Colors.blueAccent : Colors.grey[300]!,
          width: 3,
        ),
        boxShadow: active
            ? [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 6)]
            : [],
      ),
    );
  }

  Widget _buildReceivedButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
        ),
      ),
      child: const Center(
        child: Text(
          "Received Item",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
