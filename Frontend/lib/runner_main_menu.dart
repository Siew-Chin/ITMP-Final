import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_detail_page.dart';

class RunnerMainMenu extends StatefulWidget {
  final String studentID;
  const RunnerMainMenu({super.key, required this.studentID});

  @override
  State<RunnerMainMenu> createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  Future<List<dynamic>> fetchAvailableOrders() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/orders/pending');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
<<<<<<< HEAD
        title: const Text('Runner Orders'),
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
=======
        title: const Text('To Your Dorm'),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        leading: const Icon(Icons.menu),
>>>>>>> origin/feature-tcr
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchAvailableOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Connect to Flask to see orders'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No available orders right now.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              // Forced type-casting to help the Flutter Analyzer
              final Map<String, dynamic> order =
                  orders[index] as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    '${(order['type'] ?? 'Order').toString().toUpperCase()} - RM ${order['price'] ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Details: ${order['details'] ?? 'No details'}'),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(order: order),
                        ),
                      );
                    },
                    child: const Text('Take'),
                  ), // Closes ElevatedButton
                ), // Closes ListTile
              ); // Closes Card
            },
          );
        },
      ),
    );
  }
}
