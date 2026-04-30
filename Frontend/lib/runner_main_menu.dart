import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// Make sure these filenames match your project exactly
import 'drive_detail_page.dart';
import 'parcel_detail_page.dart';
import 'food_detail_page.dart';

//12
class RunnerMainMenu extends StatefulWidget {
  final String runnerId;
  const RunnerMainMenu({Key? key, required this.runnerId}) : super(key: key);

  @override
  _RunnerMainMenuState createState() => _RunnerMainMenuState();
}

class _RunnerMainMenuState extends State<RunnerMainMenu> {
  double totalEarnings = 0.0;
  List availableTasks = [];
  List currentTasks = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    // Refresh data every 10 seconds (API 17, 18, 19)
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _fetchDashboardData(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // API 19: Earnings
      final earnRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/runner/earnings?runner_id=${widget.runnerId}',
        ),
      );
      // API 17: Market
      final marketRes = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/runner/market'),
      );
      // API 18: Current active tasks
      final currentRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/runner/tasks?runner_id=${widget.runnerId}',
        ),
      );

      if (mounted) {
        setState(() {
          totalEarnings = jsonDecode(earnRes.body)['Total earning'].toDouble();
          availableTasks = jsonDecode(marketRes.body);
          currentTasks = jsonDecode(currentRes.body);
        });
      }
    } catch (e) {
      debugPrint("Dashboard error: $e");
    }
  }

  // 1. 修复注销函数缺失问题
  void _handleLogout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // 修复：studentID 改为 runnerId (根据你的类定义)
        title: Text('Runner: ${widget.runnerId}'),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      // 使用 Caryn 的 CustomScrollView 作为主结构，这样可以滚动且支持下拉刷新
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 2. 将你的收益卡片放入 Sliver 中
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEarningsCard(),
                    const SizedBox(height: 20),
                    _buildSectionHeader("Current Active Tasks", currentTasks.length),
                  ],
                ),
              ),
            ),

            // 3. 渲染你手头正在做的任务 (Active Tasks)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTaskCard(currentTasks[index], isActive: true),
                ),
                childCount: currentTasks.length,
              ),
            ),

            // 4. 任务大厅标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: _buildSectionHeader("Market Available", availableTasks.length),
              ),
            ),

            // 5. 渲染大厅里的任务
            availableTasks.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("No order yet 😴")),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = availableTasks[index];
                        // 这里使用了 Caryn 的卡片逻辑或你原本的 _buildTaskCard
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildTaskCard(order),
                        );
                      },
                      childCount: availableTasks.length,
                    ),
                  ),

            // 底部提示
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    "Swipe down to refresh orders",
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total earning:",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            "RM ${totalEarnings.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map task, {bool isActive = false}) {
    // 1. Determine Icon based on type
    IconData iconData;
    String type = task['type'] ?? 'Item';

    if (type == 'Drive') {
      iconData = Icons.directions_car_rounded;
    } else if (type == 'Food') {
      iconData = Icons.fastfood_rounded;
    } else {
      iconData = Icons.inventory_2_rounded; // Default for Item/Parcel
    }

    return GestureDetector(
      onTap: () {
        Widget destination;

        // Change 'Driving' to 'Drive' to match your MongoDB screenshot
        if (type == 'Drive') {
          destination = DriveDetailPage(order: task, runnerId: widget.runnerId);
        } else if (type == 'Food') {
          destination = FoodDetailPage(order: task, runnerId: widget.runnerId);
        } else {
          destination = ParcelDetailPage(
            order: task,
            runnerId: widget.runnerId,
          );
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(iconData, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    task['pickup_point'] ?? "Location hidden",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "RM ${task['total_price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),
                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "ACTIVE",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
