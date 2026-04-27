import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'active_drive_task_page.dart';

class DriveDetailPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  const DriveDetailPage({Key? key, required this.order, required this.runnerId})
    : super(key: key);

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  bool isDetailsConfirmed = false;

  Future<void> _takeOrder() async {
    // Line 20: Path changed to match API 5 from the list
    final url = Uri.parse('http://10.0.2.2:5000/api/order/update_status');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "next_status":
              1, // Using 'next_status' as defined in teammate's API list
          "runner_id": widget.runnerId,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveDriveTaskPage(
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
            colors: [Color(0xFFEAF3FF), Color(0xFFD6E8FF), Color(0xFFBFD9FF)],
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
                  "Drive Detail",
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
                        Icons.person,
                        "Passenger",
                        widget.order['customer_name']?.toString() ?? "BCD",
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.phone,
                        "Contact",
                        widget.order['requester_contact']?.toString() ?? "123",
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      _row(
                        Icons.directions_car,
                        "Pick-up",
                        widget.order['pickup_point']?.toString() ??
                            "Library L2",
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.location_on,
                        "Drop-off",
                        widget.order['dropoff_point']?.toString() ??
                            "Kipmall Sunsuria",
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      _row(
                        Icons.account_balance_wallet,
                        "Your Earning",
                        "RM ${widget.order['delivery_fee']?.toString() ?? '8.0'}",
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
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
      ),
      child: const Text(
        "Note: Please verify the passenger identity. Drive safely and follow traffic rules. Collect payment at the end of the ride.",
        style: TextStyle(
          fontSize: 13,
          color: Colors.blueAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4A90E2), size: 22),
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
          "I confirm I can take this ride",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        value: isDetailsConfirmed,
        activeColor: const Color(0xFF4A90E2),
        onChanged: (v) => setState(() => isDetailsConfirmed = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _btn() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDetailsConfirmed
            ? const Color(0xFF4A90E2)
            : Colors.grey.shade300,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      onPressed: isDetailsConfirmed ? _takeOrder : null,
      child: const Text(
        "Accept Ride",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
