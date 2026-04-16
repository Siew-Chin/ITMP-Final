import 'package:flutter/material.dart';
import 'active_delivery_page.dart';

class OrderDetailPage extends StatelessWidget {
  final Map order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Safe calculation for the RM 5.00 delivery fee
    double foodPrice =
        double.tryParse(order['price']?.toString() ?? '0') ?? 0.0;
    double finalTotal = foodPrice + 5.00;

    // Get the order type (Food or Parcel) for the title
    String typeTitle = (order['type'] ?? 'Order').toString().toUpperCase();

    return Scaffold(
      // 1. Matches previous page background
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('$typeTitle Details'),
        // 2. Matches previous page AppBar color
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        foregroundColor:
            Colors.black87, // Makes the back arrow dark and readable
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 3. Main Card (Matches previous page Card style exactly)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header inside the card
                    Text(
                      typeTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1.5),

                    // User Details from your sketch
                    _buildDetailRow(
                      "Name",
                      order['requester_name'] ?? "Pending Name",
                    ),
                    _buildDetailRow("ID", order['requester'] ?? "Pending ID"),
                    _buildDetailRow("Dorm", order['dorm'] ?? "Pending Dorm"),
                    _buildDetailRow(
                      "Contact",
                      order['contact'] ?? "Pending Contact",
                    ),

                    const SizedBox(height: 20),

                    // Food Stall Section
                    const Text(
                      "Food Stall:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        order['stall_name'] ?? "Not specified",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Money to be received calculation
                    const Text(
                      "Money to be received:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Food price (RM ${foodPrice.toStringAsFixed(2)}) + RM 5.00 fee",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "RM ${finalTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 4. Action Button (Matches previous page Take button style)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveDeliveryPage(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // Matches the Take button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "CONFIRM PICKUP",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to keep the rows neat and aligned
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(
            ":  ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
