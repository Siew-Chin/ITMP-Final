import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
<<<<<<< HEAD
import 'order_detail_page.dart';
=======
import 'runner_parcelconfirm.dart'; // 确保你的 ParcelPage 在这个文件里
>>>>>>> origin/feature-skx

class RunnerMainMenu extends StatefulWidget {
  final String studentID;
  const RunnerMainMenu({super.key, required this.studentID});

  @override
  State<RunnerMainMenu> createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  // 获取待接订单列表 (API 9)
  Future<List<dynamic>> fetchAvailableOrders() async {
<<<<<<< HEAD
    final url = Uri.parse('http://10.0.2.2:5000/api/orders/pending');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders');
=======
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/orders/pending'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Server connection failed: $e');
>>>>>>> origin/feature-skx
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
<<<<<<< HEAD
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
=======
        title: Text('Runner: ${widget.studentID}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<dynamic>>(
          future: fetchAvailableOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text('Connect to Flask to see orders'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No available orders right now.'),
              );
            }

            final allOrders = snapshot.data!;

            return ListView.builder(
              itemCount: allOrders.length,
              itemBuilder: (context, index) {
                final order = allOrders[index];
                final String type = order['type'] ?? 'parcel';

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: Icon(
                      type == 'food' ? Icons.fastfood : Icons.inventory_2,
                      color: type == 'food' ? Colors.orange : Colors.blue,
                    ),
                    title: Text(
                      '${type.toUpperCase()} - RM ${order['price'] ?? '0.0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Dorm: ${order['dorm'] ?? "N/A"}\nDetails: ${order['details'] ?? "No details"}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        try {
                          final response = await http.post(
                            Uri.parse('http://10.0.2.2:5000/api/runner/take'),
                            headers: {"Content-Type": "application/json"},
                            body: json.encode({
                              "order_id": order['order_id'],
                              "runner_id": widget.studentID,
                            }),
                          );

                          if (response.statusCode == 200) {
                            if (!context.mounted) return;

                            // ✨ 核心逻辑：区分跳转
                            if (type == 'parcel') {
                              // 是包裹，跳转到你的 ParcelPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ParcelPage(orderId: order['order_id']),
                                ),
                              );
                            } else {
                              // 是食物，暂时不跳转，只弹个提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Food order accepted! (Food Page not ready yet)',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              // 刷新一下列表，把接了的单刷掉
                              setState(() {});
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to take order'),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Network Error')),
                          );
                        }
                      },
                      child: const Text('Take'),
                    ),
                  ),
                );
              },
            );
          },
        ),
>>>>>>> origin/feature-skx
      ),
    );
  }
}
