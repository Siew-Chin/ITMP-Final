//24
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'chat_page.dart';
import 'user_proof_photo_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class TrackingDeliveryPage extends StatefulWidget {
  final String orderId;
  final String studentID; 
  final double totalPrice; 
  final StreamChatClient client; 

  const TrackingDeliveryPage({
    super.key, 
    required this.orderId, 
    required this.studentID,
    required this.totalPrice,
    required this.client,
  });

  @override
  State<TrackingDeliveryPage> createState() => _TrackingDeliveryPageState();
}

class _TrackingDeliveryPageState extends State<TrackingDeliveryPage> {
  int _currentStatus = 0; // Order status code
  String? _runnerId; // Runner ID for chat
  String? _proofImageUrl; // Proof photo URL from runner
  Timer? _timer; // Timer for polling

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus(); // Initial fetch to get current status immediately
    _timer = Timer.periodic(const Duration(seconds: 3), (t) => _fetchOrderStatus());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed to prevent memory leaks
    super.dispose();
  }
  Future<void> _fetchOrderStatus() async {
    final url = Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/order/tracking/${widget.orderId}');//API4: GetProgress
    try {
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _currentStatus = data['status_code'] ?? 0;
            _runnerId = data['runner_id'];
            _proofImageUrl = data['proof_photo'];
          });
        }
      }
    } catch (e) {
      debugPrint("Food Polling error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF3FF),
              Color(0xFFD6E8FF),
              Color(0xFFBFD9FF),
            ],
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Item Delivering', 
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
            // --- Chat Button: Only show if order is taken and runner ID is available ---
              TextButton.icon(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close, color: Colors.black),
                label: const Text(
                  "Exit",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              if (_currentStatus > 0 && _runnerId != null) 
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                onPressed: () {
                  final String targetRunnerId = _runnerId?.toString() ?? '';

                if (targetRunnerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Waiting for driver to connect...")),
                  );
                  return;
                }

              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    currentUserId: widget.studentID,
                    otherUserId: targetRunnerId, 
                    client: widget.client,
                  )
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrderStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Order ID: ${widget.orderId}",
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              _buildItemTimeline(),
              const SizedBox(height: 50),
              _buildPriceCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- Price Card showing total price ---
  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total To Pay", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)
            ),
          Text("RM ${widget.totalPrice.toStringAsFixed(2)}", 
               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  // --- Bottom Button ---
  Widget _buildBottomButton() {
    bool canContinue = _currentStatus == 4 && _proofImageUrl != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: canContinue ? () {
            _timer?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserProofPhotoPage(
                  studentID: widget.studentID,
                  orderId: widget.orderId,
                  imageUrl: _proofImageUrl!,
                  client: widget.client,
                ),
              ),
            );
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(
            _currentStatus == 4 ? "Receive & View Proof" : "Item is delivering...",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- Timeline Progress UI ---
  Widget _buildItemTimeline() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepDot(1), _buildStepLine(1), _buildStepDot(2), _buildStepLine(2), _buildStepDot(3), _buildStepLine(3), _buildStepDot(4),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepLabel("Order\nTaken", 1),
            _buildStepLabel("Item\nPicking", 2),
            _buildStepLabel("Item\nPicked", 3),
            _buildStepLabel("Order\nDropped", 4),
          ],
        ),
      ],
    );
  }

  // --- Step Dot ---
  Widget _buildStepDot(int step) {
    bool active = _currentStatus >= step;
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: active ? Colors.black87 : Colors.grey[300], shape: BoxShape.circle),
      child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }

  // --- Step Line ---
  Widget _buildStepLine(int step) {
    bool active = _currentStatus > step;
    return Expanded(child: Container(height: 3, color: active ? Colors.black87 : Colors.grey[300]));
  }

  // --- Step Label ---
  Widget _buildStepLabel(String text, int step) {
    bool active = _currentStatus >= step;
    return SizedBox(
      width: 70,
      child: Text(text, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black87 : Colors.grey),
      ),
    );
  }
}