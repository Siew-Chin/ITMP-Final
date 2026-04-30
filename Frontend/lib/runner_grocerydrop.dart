//20
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- 1. 成功页面 ---
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              "Order Completed!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. 主页面 ---
class RunnerGroceryDrop extends StatefulWidget {
  final String orderId;
  const RunnerGroceryDrop({super.key, required this.orderId});

  @override
  State<RunnerGroceryDrop> createState() => _RunnerGroceryDropState();
}

class _RunnerGroceryDropState extends State<RunnerGroceryDrop> {
  int activeStep = 1;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _hasAmount = false;
  final TextEditingController _amountController = TextEditingController();

  final Color _bgColor = const Color(0xFFF3F7FF);

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _amountController.addListener(() {
      if (mounted) {
        setState(() {
          _hasAmount = _amountController.text.trim().isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // --- 获取当前状态 ---
  Future<void> _fetchStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/order/tracking?id=${widget.orderId}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            activeStep = data['status_code'] ?? 1;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 更新状态核心逻辑 (已修复：只有成功才更新 UI) ---
  Future<void> _updateStatus(int nextStep) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:5000/api/order/update_status'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "id": widget.orderId,
              "status_code": nextStep,
              "amount": _amountController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        // 只有后端返回 200 成功，前端才更新状态
        setState(() => activeStep = nextStep);

        if (nextStep == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OrderSuccessPage()),
          );
        }
      } else {
        // 后端返回错误（如 400, 500），弹出提示，UI 不变
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to update. Please try again."),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Update error: $e");
      // 网络超时或断网，UI 不变
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection error. Status not updated."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delivery Tracking",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildNoteSection(),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 第一步
                  _buildStepRow(
                    code: 1,
                    title: "Arriving at the Grocery Shop",
                    icon: Icons.storefront_outlined,
                    onTap: () => _updateStatus(2),
                  ),
                  _buildLine(activeStep > 1),

                  // 第二步
                  _buildStepRow(
                    code: 2,
                    title: "Item pick-upped",
                    icon: Icons.local_shipping_outlined,
                    onTap: () => _updateStatus(3),
                  ),

                  // 金额输入区
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 55,
                      right: 20,
                      top: 10,
                      bottom: 10,
                    ),
                    child: _buildAmountInput(activeStep >= 2),
                  ),

                  _buildLine(activeStep > 2),

                  // 第三步 (Dropped)：只有金额不为空 (_hasAmount) 且 activeStep 为 3 时才可点击
                  _buildDropStepRow(isEnabled: activeStep == 3 && _hasAmount),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF3949AB)),
      ),
    );
  }

  // --- UI 构建组件 ---

  Widget _buildStepRow({
    required int code,
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    bool isDone = activeStep > code;
    bool isCurrent = activeStep == code;
    return InkWell(
      onTap: isCurrent && !_isUpdating ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: (isDone || isCurrent)
                  ? const Color(0xFF3949AB)
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: (isDone || isCurrent) ? Colors.black87 : Colors.grey,
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isDone)
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDropStepRow({required bool isEnabled}) {
    bool isDone = activeStep > 3;
    return InkWell(
      onTap: isEnabled && !_isUpdating ? () => _updateStatus(4) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.where_to_vote_outlined,
              color: isEnabled || isDone ? Colors.green : Colors.grey.shade400,
            ),
            const SizedBox(width: 15),
            Text(
              "Dropped",
              style: TextStyle(
                color: isEnabled || isDone ? Colors.black87 : Colors.grey,
                fontSize: 16,
                fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isDone)
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF00796B), size: 20),
              SizedBox(width: 8),
              Text(
                "Note:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "• Please remember to get the receipt.",
            style: TextStyle(fontSize: 13, color: Color(0xFF004D40)),
          ),
          Text(
            "• Ensure the total amount is correct.",
            style: TextStyle(fontSize: 13, color: Color(0xFF004D40)),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(bool enabled) {
    return TextField(
      controller: _amountController,
      enabled: enabled && activeStep < 4,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixText: "RM ",
        hintText: "Enter receipt amount",
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildLine(bool highlighted) {
    return Container(
      margin: const EdgeInsets.only(left: 23),
      height: 30,
      width: 2,
      color: highlighted ? Colors.blue : Colors.grey.shade200,
    );
  }
}
