//13
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'active_parcel_task_page.dart';

class ParcelDetailPage extends StatefulWidget {
  final dynamic order;
  final String runnerId;
  const ParcelDetailPage({
    Key? key,
    required this.order,
    required this.runnerId,
  }) : super(key: key);

  @override
  State<ParcelDetailPage> createState() => _ParcelDetailPageState();
}

class _ParcelDetailPageState extends State<ParcelDetailPage> {
  bool isDetailsConfirmed = false;
  Map<String, dynamic>? detailedOrder;
  bool isLoading = true;

  double _parcelPrice(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/order/detail/${widget.order['order_id']}'),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        detailedOrder = jsonDecode(response.statusCode == 200 ? response.body : "{}");
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Fetch Error: $e");
    setState(() => isLoading = false);
  }
}

  Future<void> _takeOrder() async {
    // Line 23: Update the URL to API Route 5 from your documentation
    final url = Uri.parse('http://10.0.2.2:5000/api/order/update_status');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "status_code": 1,
          "runner_id": widget.runnerId,
        }),
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveParcelTaskPage(
              order: detailedOrder ?? widget.order,
              runnerId: widget.runnerId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    print("Sending order_id: ${widget.order['order_id']}");
    print("With runner_id: ${widget.runnerId}");
  }

  @override
  Widget build(BuildContext context) {

    double itemPrice = _parcelPrice(
      detailedOrder?['item_price'] ?? widget.order['item_price'],
    );

    double runnerProfit = _parcelPrice(
      detailedOrder?['runner_profit'] ?? widget.order['runner_profit'],
    );

    double totalToCollect = _parcelPrice(
      detailedOrder?['total_to_collect'] ?? widget.order['total_to_collect'],
    );

bool isUrgent =
    detailedOrder?['is_urgent'] ?? widget.order['is_urgent'] ?? false;
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Fix: Set Scaffold background to transparent so the Container gradient shows everywhere
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // Fix: Ensure container fills the whole screen
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
          bottom:false, // Fix: Allow gradient to bleed into the bottom navigation area
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Parcel Detail",
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
                        color: Colors.black.withValues(alpha:0.05),
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
                        "Customer",
                        (detailedOrder?['customer_name'] ?? widget.order['customer_name'] ?? "Loading...").toString()
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.phone,
                        "Contact",
                        (detailedOrder?['requester_contact'] ?? widget.order['requester_contact'] ?? "N/A").toString(),
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      _row(
                        Icons.local_shipping,
                        "Pickup",
                        (detailedOrder?['pickup_point'] ?? widget.order['pickup_point'] ?? "Main Parcel Hub").toString(),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.home,
                        "Dropoff",
                        (detailedOrder?['dropoff_point'] ?? widget.order['dropoff_point'] ?? "D1 Dorm").toString(),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        Icons.person,
                        "Quantity",
                        (detailedOrder?['parcel_qty'] ?? widget.order['parcel_qty'] ?? 0).toString(),
                      ),
                      const Divider(height: 30, color: Colors.black12),
                      // --- Pricing Section ---
                      if (itemPrice > 0)
                        _row(
                          Icons.shopping_bag,
                          "Item Price",
                          "RM ${itemPrice.toStringAsFixed(2)}",
                        ),

                      const SizedBox(height: 10),

                      _row(
                        Icons.attach_money,
                        "Your Profit",
                        "RM ${runnerProfit.toStringAsFixed(2)}",
                      ),

                      if (isUrgent)
                        const SizedBox(height: 10),

                      if (isUrgent)
                        _row(
                          Icons.bolt,
                          "Urgent Included",
                          "YES",
                        ),

                      const Divider(height: 30, color: Colors.black12),

                      _row(
                        Icons.payments,
                        "Total To Collect",
                        "RM ${totalToCollect.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 25),
                      _noteBox(totalToCollect),
                      const SizedBox(height: 20),
                      _checkboxArea(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _btn(),
                const SizedBox(height: 40), // Bottom padding for clean look
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteBox(double collectAmount) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.redAccent.withValues(alpha: 0.15),
      ),
    ),
    child: Text(
      "Notice: Please collect RM ${collectAmount.toStringAsFixed(2)} from the customer after delivery.",
      style: const TextStyle(
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
          "I have read the details",
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
        "Take Order",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
