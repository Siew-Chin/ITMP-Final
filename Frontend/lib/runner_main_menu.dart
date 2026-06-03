//5
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// Make sure these filenames match your project exactly
import 'drive_detail_page.dart';
import 'parcel_detail_page.dart';
import 'food_detail_page.dart';
import 'runner_groceryorder.dart';
import 'runner_deliverytake.dart';

import "active_drive_task_page.dart";
import "active_food_task_page.dart";
import "runner_grocerydrop.dart";
import "active_parcel_task_page.dart";
import "runner_deliverydrop.dart";
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'runner_earning_history_page.dart'; // 请确保文件名匹配

//12
class RunnerMainMenu extends StatefulWidget {
  final String runnerId;
  final StreamChatClient client;
  const RunnerMainMenu({Key? key, required this.runnerId, required this.client}) : super(key: key);

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
      // API 19: calculate Earnings
      final earnRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/runner/earnings?runner_id=${widget.runnerId}',
        ),
      );
      // API 17: Runner menu get orders
      final marketRes = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/runner/market?runner_id=${widget.runnerId}'),
      );
      // API 18: Runner's Active Tasks
      final currentRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/runner/tasks?runner_id=${widget.runnerId}',
        ),
      );

      if (mounted) {
        setState(() {
          final earnData = jsonDecode(earnRes.body);
          final marketData = jsonDecode(marketRes.body);
          final currentData = jsonDecode(currentRes.body);

          availableTasks = marketData is List ? marketData : [];
          currentTasks = currentData is List ? currentData : [];

          totalEarnings =
              double.tryParse(
                earnData['total_earning'].toString(),
              ) ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("Dashboard error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      )
    );
  }

  Widget _buildEarningsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RunnerEarningHistoryPage(runnerId: widget.runnerId),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 加上一个小提示图标或文字，让用户知道可以点击（可选）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total earning:",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
              ],
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
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF2F3A5A))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6C8EF5).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
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
    String type =
    (task['type'] ?? 'item')
    .toString()
    .toLowerCase();

    Color iconColor;

    if (type == 'ride') {
      iconData = Icons.local_taxi_rounded;
      iconColor = const Color(0xFFF9A825);

    } else if (type == 'food') {
      iconData = Icons.ramen_dining_rounded;
      iconColor = const Color(0xFFFF5252);

    } else if (type == 'grocery') {
      iconData = Icons.shopping_cart_rounded;
      iconColor = const Color(0xFF4CAF50);

    } else if (type == 'item') {
      iconData = Icons.inventory_2_rounded;
      iconColor = Colors.deepPurple;

    } else {
      iconData = Icons.local_shipping_rounded;
      iconColor = Colors.blueAccent;
    }

    String orderTime = task['created_at'] ?? '';

    return GestureDetector(
      onTap: () {

        Widget destination;

        String type =
            (task['type'] ?? 'item')
            .toString()
            .toLowerCase();

        int statusCode =
            int.tryParse(task['status_code'].toString()) ?? 0;

        // =========================
        // ACTIVE TASK
        // =========================

        if (statusCode >= 1) {

          // DRIVE
          if (type == 'ride') {

            destination = ActiveDriveTaskPage(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          // FOOD
          else if (type == 'food') {

            destination = ActiveFoodTaskPage(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          // GROCERY
          else if (type == 'grocery') {

            destination = RunnerGroceryDrop(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          //Item
          else if(type == 'item') {

            destination = RunnerDeliveryDrop(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );
          }

          //PARCEL
           else{

            destination = ActiveParcelTaskPage(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

        }

        // =========================
        // MARKET TASK
        // =========================

        else {

          if (type == 'ride') {

            destination = DriveDetailPage(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          else if (type == 'food') {

            destination = FoodDetailPage(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          else if (type == 'grocery') {

            destination = RunnerGroceryOrder(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          else if (type == 'item') {

            destination = RunnerDeliveryTake(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }

          else {

            destination = ParcelDetailPage(
              order: task,
              runnerId: widget.runnerId,
              client: widget.client,
            );

          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.75),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
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
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(iconData, color: iconColor, size: 28),
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
                    (task['pickup_point']?.toString().isNotEmpty ?? false)
                    ? task['pickup_point']
                    : "Location hidden",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (orderTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      orderTime,
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "+ RM ${double.tryParse(task['runner_profit'].toString())?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Collect RM ${double.tryParse(task['total_to_collect'].toString())?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                if (task['is_urgent'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 12,
                            color: Colors.red,
                          ),

                          SizedBox(width: 4),

                          Text(
                            "URGENT",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
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
            )
          ],
        ),
      ),
    );
  }
}
