import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ActiveDeliveryPage extends StatelessWidget {
  final Map order;

  const ActiveDeliveryPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Re-calculate the final total so the runner knows exactly what to ask for
    double foodPrice =
        double.tryParse(order['price']?.toString() ?? '0') ?? 0.0;
    double finalTotal = foodPrice + 5.00;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Match theme
      appBar: AppBar(
        title: const Text('Active Delivery'),
        backgroundColor: const Color(0xFF87CEEB), // Match theme
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 60,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Important Notes",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1.5),

                    // Note 1 from your sketch
                    const Text(
                      "1. Please remember to get the receipt from the food stall.",
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 15),

                    // Note 2 from your sketch
                    const Text(
                      "2. After dropping the food, remember to collect money from the customer.",
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),

                    const SizedBox(height: 25),

                    // Helper Box: Reminds them how much to collect!
                    Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Amount to Collect:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "RM ${finalTotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(), // Pushes the button to the bottom of the screen
            // The "Dropped" Button from your sketch
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green[500], // Green means finished/success!
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  // 1. The URL pointing to your new Python route
                  final url = Uri.parse(
                    'http://10.0.2.2:5000/api/orders/${order['order_id']}/complete',
                  );

                  try {
                    // 2. Send the update request to the database
                    final response = await http.put(url);

                    if (response.statusCode == 200) {
                      // 3. If successful, pop all the way back to the main menu
                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    } else {
                      // Show an error if the database didn't update
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update database!'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print("Error updating order: $e");
                  }
                },

                child: const Text(
                  "MARK AS DROPPED",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
