//20
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_page.dart';
import 'runner_proof_photo_page.dart';

class RunnerGroceryDrop extends StatefulWidget {
  final dynamic order; // 统一使用 order 对象
  final String runnerId;
  
  const RunnerGroceryDrop({
    Key? key,
    required this.order,
    required this.runnerId,
  }) : super(key: key);

  @override
  State<RunnerGroceryDrop> createState() => _RunnerGroceryDropState();
}

class _RunnerGroceryDropState extends State<RunnerGroceryDrop> {
  int currentStatus = 1;
  bool isLoading = false;
  Map<String, dynamic>? liveOrder; // 存储实时数据
  bool isPageLoading = true;
  final TextEditingController _amountController = TextEditingController();
  final Color _bgColor = const Color(0xFFF3F7FF);

  @override
  void initState() {
    super.initState();
    currentStatus = int.tryParse(widget.order['status_code'].toString()) ?? 1;
    if (currentStatus == 0) currentStatus = 1;
    _amountController.text =
      widget.order['item_price']?.toString() ?? '';
    _refreshData();
  }

  Future<void> _refreshData() async {
  try {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/order/detail/${widget.order['order_id']}'),
    );
    if (res.statusCode == 200) {
      setState(() {
        liveOrder = jsonDecode(res.body);

        currentStatus =
            int.tryParse(liveOrder!['status_code'].toString()) ?? 1;

        _amountController.text =
            liveOrder?['item_price']?.toString() ??
            widget.order['item_price']?.toString() ??
            '';

        isPageLoading = false;
      });
    }
  } catch (e) {
    setState(() => isPageLoading = false);
  }
}

  // 计算价格逻辑

  Future<void> _updateStatus(int nextS) async {
    if (nextS == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RunnerProofPhotoPage(
            orderId: widget.order['order_id'].toString(),
            runnerId: widget.runnerId,
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      Map<String, dynamic> bodyData = {
          "order_id": widget.order['order_id'],
          "status_code": nextS, 
          "runner_id": widget.runnerId,
        };

      if (currentStatus == 2 && nextS == 3) {
        String receiptAmount = _amountController.text.trim();

        if (receiptAmount.isEmpty) {
          throw Exception("Please enter receipt amount");
        }

        bodyData["amount"] = receiptAmount;
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/order/update_status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        print(response.body);

        print("Update Success");

        await _refreshData();

        setState(() {
          isLoading = false;
          currentStatus = nextS;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Progress updated to Step $nextS")),
        );
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update progress: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     double itemPrice = double.tryParse(
      liveOrder?['item_price']?.toString() ??
      widget.order['item_price']?.toString() ??
      "0"
    ) ?? 0;

    double earning = double.tryParse(
      liveOrder?['runner_profit']?.toString() ??
      widget.order['runner_profit']?.toString() ??
      "0"
    ) ?? 0;

    double totalToCollect = double.tryParse(
      liveOrder?['total_to_collect']?.toString() ??
      widget.order['total_to_collect']?.toString() ??
      "0"
    ) ?? 0;

    if (isPageLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6C8EF5))),
      );
    }


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Grocery Progress",
          style: TextStyle(color: Color(0xFF2F3A5A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage(
                studentID: widget.order['requester_id']?.toString() ?? "", 
                runnerID: widget.runnerId,
              )),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2F3A5A)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FF), Color(0xFFD6E8FF), Color(0xFFBFD9FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( // 1. 添加滚动视图
            physics: const BouncingScrollPhysics(), // 添加回弹效果，体验更好
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryCard(itemPrice, earning, totalToCollect),
                const SizedBox(height: 25),
                const Text(
                  "Payment Reminder:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C8EF5),
                  ),
                ),
                const SizedBox(height: 10),
                _noteBox(
                  "1. Pay RM ${itemPrice.toStringAsFixed(2)} at the shop first.\n"
                  "2. Deliver to ${widget.order['dropoff_point']}.\n"
                  "3. Collect TOTAL RM ${totalToCollect.toStringAsFixed(2)} from the customer.",
                ),
                const SizedBox(height: 30),
                const Text(
                  "Update Progress",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3A5A)),
                ),
                const SizedBox(height: 15),
                _stepBtn("1. Arriving at the Grocery Shop", 1, 2, const Color(0xFF6C8EF5)),
                const SizedBox(height: 12),
                _stepBtn("2. Grocery Picked Up", 2, 3, const Color(0xFF6C8EF5)),
                if (currentStatus == 2)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _amountController,
                    enabled: currentStatus == 2,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: "RM ",
                      hintText: "Enter grocery receipt amount",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _stepBtn("3. Delivered & Proof", 3, 4, const Color(0xFF6C8EF5)),
                const SizedBox(height: 40),
                _escapeBtn(),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF6C8EF5))),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(double food, double earn, double total) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
      ],
    ),
    child: Column(
      children: [
        _rowSummary("Customer", liveOrder?['customer_name'] ?? "Unknown"),
        const SizedBox(height: 8),
        _rowSummary("Dorm", liveOrder?['dropoff_point'] ?? "N/A"),
        const SizedBox(height: 8),

        _rowSummary("Shop", liveOrder?['shop_name'] ?? widget.order['shop_name'] ?? "N/A"),
        const Divider(height: 20),
        
        _rowSummary( 
          "Collect",
          "RM ${double.tryParse(
              liveOrder?['total_to_collect'].toString() ?? '0'
            )?.toStringAsFixed(2) ?? '0.00'}",
            valueColor: Colors.green,
        ), 
        _rowSummary(
          "Profit",
          "RM ${double.tryParse(
              liveOrder?['runner_profit'].toString() ?? '0'
            )?.toStringAsFixed(2) ?? '0.00'}",
            valueColor: Colors.blue,
        ),
        const SizedBox(height: 12),
        const Divider(color: Colors.black12),
        const SizedBox(height: 8),
        
        // 3. 最终拿回来的总现金
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total to Collect", style: TextStyle(color: Color(0xFF2F3A5A), fontWeight: FontWeight.bold, fontSize: 16)),
                Text("(Cash from Customer)", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            Text(
              "RM ${total.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green),
            ),
          ],
        ),
      ],
    ),
  );

// 稍微修改一下 _rowSummary 支持高亮
Widget _rowSummary(String l, String v, {Color? valueColor, bool isHighlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
        Text(
          v,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600, 
            fontSize: 14, 
            color: valueColor ?? (isHighlight ? Colors.blueAccent : const Color(0xFF2F3A5A))
          ),
        ),
      ],
    ),
  );

  Widget _noteBox(String text) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF6C8EF5).withOpacity(0.2)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2F3A5A),
        fontWeight: FontWeight.w500,
        height: 1.6,
      ),
    ),
  );

  Widget _stepBtn(String l, int a, int t, Color c) {
    bool done = currentStatus > a;
    bool active = currentStatus == a;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: done
            ? Colors.grey.shade300
            : (active ? c : Colors.white.withOpacity(0.8)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: active ? 4 : 0,
      ),
      onPressed: active ? () => _updateStatus(t) : null,
      child: Text(
        done ? "$l (Completed)" : l,
        style: TextStyle(
          color: active ? Colors.white : (done ? Colors.grey : Colors.black45),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _escapeBtn() => TextButton.icon(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.dashboard_outlined, color: Colors.blueGrey),
    label: const Text(
      "Return to Marketplace",
      style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
    ),
  );
}