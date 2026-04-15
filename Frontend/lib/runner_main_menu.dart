import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_parcelconfirm.dart'; // 确保导入了你的页面

class RunnerMainMenu extends StatefulWidget {
  final String studentID;
  const RunnerMainMenu({super.key, required this.studentID});

  @override
  _RunnerMainMenuState createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  // 获取待接订单列表 (对应 API 9)
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
        title: Text('Runner: ${widget.studentID}'),
        backgroundColor: Colors.blueAccent,
      ),
      // 添加下拉刷新功能，方便跑腿员刷出新单子
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

            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    // --- 优化 UI 显示字段 ---
                    title: Text(
                      '${(order['type'] ?? 'PARCEL').toString().toUpperCase()} - RM ${order['money_to_receive'] ?? '0.0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Dorm: ${order['dorm'] ?? "N/A"}\nDetails: ${order['details'] ?? "No details"}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        try {
                          // 1. 调用 API 12: 确认接单
                          final response = await http.post(
                            Uri.parse('http://10.0.2.2:5000/api/runner/take'),
                            headers: {"Content-Type": "application/json"},
                            body: json.encode({
                              "order_id": order['order_id'],
                              "runner_id": widget.studentID,
                            }),
                          );

                          if (response.statusCode == 200) {
                            // 2. 接单成功跳转，此时你的 ParcelPage 会通过 order_id 运行 API 10
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ParcelPage(orderId: order['order_id']),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reload Failure')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reload Failure')),
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

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RunnerMainMenu(studentID: "TEST1234"),
    ),
  );
}
