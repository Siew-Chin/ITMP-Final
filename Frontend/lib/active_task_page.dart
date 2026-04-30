import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ActiveTaskPage extends StatelessWidget {
  final dynamic order;
  const ActiveTaskPage({Key? key, required this.order}) : super(key: key);

  Future<void> _completeTask(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:5000/api/runner/complete');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"order_id": order['order_id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task Completed Successfully!")),
        );
        // Returns to the Dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isParcel = order['type'].toString().toLowerCase() == 'parcel';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FF), Color(0xFFD6E8FF), Color(0xFFBFD9FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.delivery_dining,
                  size: 60,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  isParcel ? "Delivering Parcel" : "Task In Progress",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _locationStep("Pickup", order['pickup_location'], true),
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(thickness: 2),
                        ),
                      ),
                      _locationStep(
                        "Dropoff",
                        order['dropoff_location'],
                        false,
                      ),

                      const Divider(height: 40),

                      // PARCEL SPECIFIC WARNING
                      if (isParcel)
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "REMINDER: Return the Student ID Card to the requester upon delivery!",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _contactAction(Icons.message, "Chat", Colors.blue),
                          _contactAction(Icons.phone, "Call", Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    minimumSize: const Size(double.infinity, 65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => _completeTask(context),
                  child: const Text(
                    "Confirm Delivery",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationStep(String label, String? loc, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.location_on,
          color: completed ? Colors.green : Colors.blueAccent,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              loc ?? "N/A",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contactAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
