import 'package:flutter/material.dart';
import 'package:my_new_app/service_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderHistoryPage extends StatefulWidget {
  final String studentID;
  const OrderHistoryPage({super.key, required this.studentID});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> { 
  bool isSwitch = false; // For user/runner mode switch
  List<dynamic> allOrders = []; // 存放从数据库拿到的所有订单
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // 在 _OrderHistoryPageState 类中修改 _fetchOrders 方法：

Future<void> _fetchOrders() async {
  if (!mounted) return;
  setState(() => isLoading = true);
  try {
    // 注意这里的路径：/api/orders/history/
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/orders/history/${widget.studentID}'),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        allOrders = json.decode(response.body);
        isLoading = false;
      });
    } else {
      print("Server error: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("Network Error: $e");
    if (!mounted) return;
    
    setState(() => isLoading = false);
  }
}
Widget _buildOrderCard(dynamic order) {

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Type
        Text(
          order['type'] ?? "Unknown",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // User / Runner name
        Text(
          isSwitch
              ? "User: ${order['user_name']}"
              : "Runner: ${order['runner_name']}",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 10),

        // Rating
        Row(
          children: [

            const Text(
              "Rating: ",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            ...List.generate(
              5,
              (index) => Icon(
                index < (order['rating'] ?? 0)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Comment
        if ((order['comment'] ?? '').toString().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "\"${order['comment']}\"",
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 10),

        // Date
        Text(
          (order['created_at'] ?? "").toString().length >= 10
              ? order['created_at'].toString().substring(0, 10)
              : "N/A",
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}
  // User view with order details and status
  Widget _buildUserView() {
    final userOrders = allOrders.where((o) => o['requester_id'] == widget.studentID).toList();

    if (userOrders.isEmpty) return _emptyCard(icon: Icons.history, title: "No Orders", subtitle: "You haven't ordered anything yet.");

    return Column(
      children: userOrders.map((order) => _buildOrderCard(order)).toList(),
    );
  }

  //Runner view with different order details and status
  Widget _buildRunnerView() {
    // 过滤出 runner_id 是我的订单
    final runnerOrders = allOrders.where((o) => o['runner_id'] == widget.studentID).toList();

    if (runnerOrders.isEmpty) return _emptyCard(icon: Icons.delivery_dining, title: "No Tasks", subtitle: "You haven't delivered anything yet.");

    return Column(
      children: runnerOrders.map((order) => _buildOrderCard(order)).toList(),
    );
  }

  //Earning card widget
  Widget_earnCard(String title, String amount, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children:[
          Icon(icon, size: 28, color: const Color(0xFF6C8EF5)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.w500, 
              color: Colors.blueGrey),
          ),
        const SizedBox(height: 4),
        Text(amount, 
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600, 
            color: Colors.green)),
        ],
      ),
    );
  }

  //_empty order card order
  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(22),
          ),
      child: Column(
        children:[
          Icon(icon, size: 32, color: const Color(0xFF6C8EF5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF6C8EF5)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
        ]
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Background
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF3FF),
              Color(0xFFD6E8FF),
              Color(0xFFBFD9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator()) // 加载中显示转圈
            : RefreshIndicator( // 添加下拉刷新功能
                onRefresh: _fetchOrders,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ServicePage(studentID: widget.studentID)),
                              );
                            },
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xFF6C8EF5),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Orders",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F3A5A),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                  isSwitch ? "Runner Mode" : "User Mode",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2F3A5A),
                                    fontStyle: FontStyle.italic,
                                  ),
                              ),
                              Switch(
                                value: isSwitch,
                                onChanged: (value) {
                                  setState(() {
                                    isSwitch = value;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                          ? "Switched to Runner Mode"
                                          : "Switched to User Mode",
                                      ),
                                    ),
                                  );
                                },
                                activeThumbColor: Colors.white,
                                activeTrackColor: const Color(0xFF6C8EF5),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      isSwitch ? _buildRunnerView() : _buildUserView(),
                    ]
                  ),
                ),
              ),
          
        ),
      ),
    );
  }
}