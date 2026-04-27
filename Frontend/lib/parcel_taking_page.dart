import 'package:flutter/material.dart';

class ParcelTakingPage extends StatefulWidget {
  const ParcelTakingPage({super.key});

  @override
  State<ParcelTakingPage> createState() => _ParcelTakingPageState();
}

class _ParcelTakingPageState extends State<ParcelTakingPage> {
  int _quantity = 1;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  void _calculatePrice() {
    double price = 0.0;
    if (_quantity <= 5) {
      price = _quantity * 1.0;
    } else {
      price = 5.0 + ((_quantity - 5) * 2.0);
    }
    _priceController.text = price.toStringAsFixed(2);
  }

  void _incrementQuantity() {
    setState(() {
      if (_quantity < 10) {
        _quantity++;
        _calculatePrice();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Maximum 10 parcels allowed per order!"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
        _calculatePrice();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), 
      appBar: AppBar(
        title: const Text(
          'Parcel Order',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Pricing Announcement (Yellow)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pricing: 1-5 parcels are RM 1/each. Parcels above 5 are RM 2/each. (Max 10)",
                      style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12), // 小间距

            // 2. NEW: ID & Payment Note (Teal)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.badge_outlined, color: Colors.teal), // 证件小图标
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Note: The runner will reach your dorm to take your ID card. Please pay when the parcel arrives at your dorm.",
                      style: TextStyle(color: Colors.teal, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Quantity Selection
            const Text(
              "How many parcels?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.blue,
                        onPressed: _decrementQuantity,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.blue,
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Auto-Calculated Price
            const Text(
              "Total Price (RM)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200], 
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _priceController,
                readOnly: true, 
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.payments_outlined, color: Colors.blueGrey),
                  prefixText: "RM ",
                  prefixStyle: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 40),

            // Launch Order Button
            ElevatedButton(
              onPressed: () {
                print("Order Launched! Qty: $_quantity, Total Price: RM ${_priceController.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: const Text(
                "Launch Order",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}