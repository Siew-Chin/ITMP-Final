//28
import 'package:flutter/material.dart';
import 'user_rating_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class UserProofPhotoPage extends StatefulWidget {
  final String studentID;
  final String orderId;
  final String imageUrl;
  final StreamChatClient client;

  const UserProofPhotoPage({
    super.key,
    required this.studentID,
    required this.orderId,
    required this.imageUrl,
    required this.client,
  });

  @override
  State<UserProofPhotoPage> createState() => _UserProofPhotoPageState();
}


class _UserProofPhotoPageState extends State<UserProofPhotoPage> {
  double? totalToCollect;
  bool isLoadingAmount = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentAmount();
  }

  Future<void> _fetchPaymentAmount() async {
    try {
      final res = await http.get(
        Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/order/tracking/${widget.orderId}'),//API4: GetProgress
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (mounted) {
          setState(() {
            totalToCollect = (data['total_to_collect'] as num?)?.toDouble();
            isLoadingAmount = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingAmount = false);
      }
    } catch (e) {
      debugPrint("Fetch payment amount error: $e");
      if (mounted) setState(() => isLoadingAmount = false);
    }
  }

  Widget _paymentReminder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF80CBC4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: Color(0xFF00796B), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLoadingAmount
                  ? "Checking payment amount..."
                  : "Please pay RM ${(totalToCollect ?? 0).toStringAsFixed(2)} to the runner.",
              style: const TextStyle(
                color: Color(0xFF00796B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        title: const Text ("Delivery Proof Photo"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.imageUrl, 
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) => 
                  const SizedBox(height: 300, child: Center(child: Icon(Icons.broken_image, size: 50))),
              ),
            ),
            const SizedBox(height:30),
            _paymentReminder(),
            const SizedBox(height: 24),
            const Text(
              "Please confirm your delivery",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height:30),
            //Confirm button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C8EF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: (){
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => UserRatingPage(
                      client: widget.client,
                      studentID: widget.studentID,
                      orderId: widget.orderId,
                    )
                  )
                );
              },
              child: const Text (
                "Confirm Delivery", style: TextStyle(fontSize:16),
              )
            ),
          ]
        )
      ) 
    );
  }
}
