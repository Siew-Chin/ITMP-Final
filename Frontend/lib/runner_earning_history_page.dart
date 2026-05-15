import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RunnerEarningHistoryPage extends StatefulWidget {
  final String runnerId;

  const RunnerEarningHistoryPage({
    super.key,
    required this.runnerId,
  });

  @override
  State<RunnerEarningHistoryPage> createState() => _RunnerEarningHistoryPageState();
}

class _RunnerEarningHistoryPageState extends State<RunnerEarningHistoryPage> {
  bool isLoading = true;
  double todayEarning = 0;
  double totalEarning = 0;
  List<dynamic> tasks = [];

  @override
  void initState() {
    super.initState();
    loadEarningHistory();
  }

  Future<void> loadEarningHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/runner/earning_history?runner_id=${widget.runnerId}'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          todayEarning = (data["today_earning"] ?? 0).toDouble();
          totalEarning = (data["total_earning"] ?? 0).toDouble();
          tasks = data["tasks"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Load earning history error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _summaryCard(String title, double amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6C8EF5)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Color(0xFF2F3A5A))),
            const SizedBox(height: 4),
            Text(
              "RM ${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3A5A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskTile(dynamic task) {
    final earning = (task["earning"] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF3FF),
            child: Icon(Icons.receipt_long, color: Color(0xFF6C8EF5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task["task_type"] ?? "Task",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F3A5A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task["date"] ?? "",
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          Text(
            "RM ${earning.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F3A5A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        // --- 添加返回按钮 ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context), // 返回上一页
        ),
        // ------------------
        title: const Text("Earning History"),
        backgroundColor: const Color(0xFFEAF3FF),
        foregroundColor: const Color(0xFF2F3A5A),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadEarningHistory,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                children: [
                  Row(
                    children: [
                      _summaryCard("Today's", todayEarning, Icons.today),
                      const SizedBox(width: 12),
                      _summaryCard("Total", totalEarning, Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Completed Tasks",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F3A5A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (tasks.isEmpty)
                    const Center(child: Text("No earning history yet"))
                  else
                    ...tasks.map(_taskTile),
                ],
              ),
            ),
    );
  }
}