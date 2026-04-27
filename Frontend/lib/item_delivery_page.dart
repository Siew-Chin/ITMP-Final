import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tracking_delivery_page.dart';

class ItemDeliveryPage extends StatefulWidget {
  final String studentId;
  const ItemDeliveryPage({Key? key, required this.studentId}) : super(key: key);

  @override
  _ItemDeliveryPageState createState() => _ItemDeliveryPageState();
}

class _ItemDeliveryPageState extends State<ItemDeliveryPage> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool isUrgent = false;

  // --- VALIDATION & API CALL ---
  Future<void> _createOrder() async {
    // 1. Check for empty fields
    if (_qtyController.text.isEmpty ||
        _itemDescController.text.isEmpty ||
        _pickupController.text.isEmpty ||
        _dropoffController.text.isEmpty) {
      _showErrorDialog("Please fill up all information before ordering!");
      return;
    }

    final url = Uri.parse('http://10.0.2.2:5000/api/item/create'); // API 16

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": widget.studentId,
          "parcel_qty": _qtyController.text,
          "item_description": _itemDescController.text,
          "pickup_point": _pickupController.text,
          "dropoff_point": _dropoffController.text,
          "notes": _notesController.text,
          "urgent": isUrgent,
          "total_price": 5.0,
        }),
      );

      if (response.statusCode == 201) {
        final orderId = jsonDecode(response.body)['order_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingDeliveryPage(orderId: orderId),
          ),
        );
      } else {
        _showErrorDialog("Failed to create order. Please try again.");
      }
    } catch (e) {
      _showErrorDialog("Connection Error: Make sure your backend is running.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invalid Order"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
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
          "Item Delivery",
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel("Quantity & Item Name"),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildField(_qtyController, Icons.numbers, "Qty"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: _buildField(
                        _itemDescController,
                        Icons.inventory_2,
                        "Item Description",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInputLabel("Pick-up Point"),
                _buildField(
                  _pickupController,
                  Icons.location_on,
                  "Enter location",
                ),
                const SizedBox(height: 20),
                _buildInputLabel("Drop-off Point"),
                _buildField(_dropoffController, Icons.flag, "Enter location"),
                const SizedBox(height: 20),
                _buildInputLabel("Notes"),
                _buildField(
                  _notesController,
                  Icons.edit_note,
                  "Any extra info?",
                  maxLines: 2,
                ),
                const SizedBox(height: 30),
                _buildPriceCard(),
                const SizedBox(height: 40),
                _buildOrderButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildInputLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.black54,
      ),
    ),
  );

  Widget _buildField(
    TextEditingController ctrl,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white),
    ),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        hintText: hint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(15),
      ),
    ),
  );

  Widget _buildPriceCard() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Checkbox(
          value: isUrgent,
          onChanged: (v) => setState(() => isUrgent = v!),
          activeColor: Colors.blueAccent,
        ),
        const Text("Urgent Delivery"),
        const Spacer(),
        const Text(
          "RM 5.00",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blueAccent,
          ),
        ),
      ],
    ),
  );

  Widget _buildOrderButton() => InkWell(
    onTap: _createOrder,
    child: Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "Order Now",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
