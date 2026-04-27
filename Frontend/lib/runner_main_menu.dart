import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_detail_page.dart';
import 'login_page.dart'; // 💡 记得导入你的登录页

class RunnerMainMenu extends StatefulWidget {
  final String studentID;
  const RunnerMainMenu({super.key, required this.studentID});

  @override
  State<RunnerMainMenu> createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  // 获取待接单列表
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
      return [];
    }
  }

  // ✨ 注销逻辑
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // 💡 关键修改：这里要用 Login() 而不是 LoginPage()
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Login()), 
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Runner: ${widget.studentID}'),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        foregroundColor: Colors.black87,
        // ✨ 在右上角添加注销按钮
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<dynamic>>(
          future: fetchAvailableOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOrders = snapshot.data ?? [];

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (allOrders.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No order yet 😴'),
                          Text("Relax or check back later!"),

                          SizedBox(height:20),

                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // 刷新页面
                            },
                            child: const Text("Refresh"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey,
                              textStyle: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = allOrders[index];
                        final String type = (order['type'] ?? 'parcel').toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            leading: CircleAvatar(
                              backgroundColor: type == 'food' ? Colors.orange[100] : Colors.blue[100],
                              child: Icon(
                                type == 'food' ? Icons.fastfood : Icons.inventory_2,
                                color: type == 'food' ? Colors.orange : Colors.blue,
                              ),
                            ),
                            title: Text(
                              '${type.toUpperCase()} - RM ${
                                type == 'parcel'
                                  ? (int.tryParse(order['parcel_qty']?.toString() ?? '1') ?? 1) < 5
                                    ? (int.tryParse(order['parcel_qty']?.toString() ?? '1') ?? 1) * 2.0
                                    : (int.tryParse(order['parcel_qty']?.toString() ?? '1') ?? 1) * 1.0
                                  : (double.tryParse(order['price']?.toString() ?? '0') ?? 0.0) + 5.0
                              }',
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            subtitle: Text('Dorm: ${order['dorm'] ?? "N/A"}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OrderDetailPage(order: order)),
                                );
                              },
                              child: const Text('Take', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                      },
                      childCount: allOrders.length,
                    ),
                  ),
                
                // ✨ 底部的提示小字
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "Swipe down to refresh orders",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}