//这个没有号码，因为是kaexin test task 的资料拉去后面（19，21）的code
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_groceryorder.dart';
import 'runner_deliverytake.dart'; // 确保你已经创建了这个文件

void main() {
  runApp(
    const MaterialApp(
      home: TaskMarketPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class TaskMarketPage extends StatefulWidget {
  const TaskMarketPage({super.key});

  @override
  State<TaskMarketPage> createState() => _TaskMarketPageState();
}

class _TaskMarketPageState extends State<TaskMarketPage> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  // --- 1. 计算时间差 (保留原逻辑) ---
  String getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return "0";
    try {
      DateTime orderTime = DateTime.parse(createdAt.toString());
      DateTime now = DateTime.now();
      Duration difference = now.difference(orderTime);

      if (difference.inMinutes < 1) {
        return "1";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}";
      } else {
        return "${difference.inHours}h";
      }
    } catch (e) {
      return "5";
    }
  }

  // --- 2. 获取数据 (保留原逻辑) ---
  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    final String url = 'http://10.0.2.2:5000/api/runner/market';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          _tasks = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  String _parseOrderId(dynamic idData) {
    // 后端 Backend.py 已经将 _id 转为 String 了，直接返回即可
    return idData.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text(
          "Task Market",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTasks,
              child: _tasks.isEmpty
                  ? const Center(child: Text("No tasks available"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final String orderId = _parseOrderId(task['_id']);
                        final String type = task['type'] ?? "Grocery";
                        final bool isUrgent = task['is_urgent'] ?? false;
                        final String minutesAgo = getTimeAgo(
                          task['created_at'],
                        );

                        return GestureDetector(
                          onTap: () {
                            // --- 核心跳转分流逻辑 ---
                            Widget targetPage;
                            String taskType = type.toLowerCase();

                            if (taskType.contains("grocery")) {
                              targetPage = RunnerGroceryOrder(orderId: orderId);
                            } else {
                              // 这里跳转到你的 Item Delivery 页面
                              // 注意：RunnerDeliveryTake 内部必须定义了 final String orderId
                              targetPage = RunnerDeliveryTake(orderId: orderId);
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => targetPage,
                              ),
                            ).then((_) => _fetchTasks());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black87),
                            ),
                            child: Row(
                              children: [
                                _buildIcon(type),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            type,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isUrgent)
                                            const Text(
                                              " ● urgent",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "RM ${task['delivery_fee'] ?? '3.00'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      minutesAgo,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "minutes ago",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  // --- 3. 构建图标 (保留原逻辑) ---
  Widget _buildIcon(String type) {
    bool isGrocery = type.toLowerCase().contains("grocery");
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isGrocery ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isGrocery ? Icons.shopping_cart : Icons.inventory_2,
        color: isGrocery ? Colors.orange : Colors.blue,
      ),
    );
  }
}
