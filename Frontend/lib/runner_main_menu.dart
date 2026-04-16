import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_parcelconfirm.dart'; // 确保你的 ParcelPage 在这个文件里

class RunnerMainMenu extends StatefulWidget {
  final String studentID;
  const RunnerMainMenu({super.key, required this.studentID});

  @override
  _RunnerMainMenuState createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  // 获取待接订单列表 (API 9)
  Future<List<dynamic>> fetchAvailableOrders() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
    );
  }
}
