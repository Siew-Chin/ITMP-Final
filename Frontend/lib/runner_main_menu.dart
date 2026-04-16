import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RunnerMainMenu extends StatefulWidget {
  final String studentID; // 接收传来的 ID
  const RunnerMainMenu({super.key, required this.studentID});

  @override
  _RunnerMainMenuState createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  Future<List<dynamic>> fetchAvailableOrders() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/orders/pending'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Your Dorm'),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        leading: const Icon(Icons.menu),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchAvailableOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Connect to Flask to see orders'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No available orders right now.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    '${order['order_type'].toString().toUpperCase()} - RM ${order['cost']}',
                  ),
                  subtitle: Text('Details: ${order['details']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // 这里以后可以写：接单 API，带上 widget.studentID
                      print('Runner ${widget.studentID} took order ${order['id']}');
                    },
                    child: const Text('Take'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}