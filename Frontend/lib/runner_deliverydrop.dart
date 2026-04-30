//22
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RunnerDeliveryDrop extends StatefulWidget {
  final String orderId; // 必须接收 orderId

  const RunnerDeliveryDrop({super.key, required this.orderId});

  @override
  State<RunnerDeliveryDrop> createState() => _RunnerDeliveryDropState();
}

class _RunnerDeliveryDropState extends State<RunnerDeliveryDrop> {
  // 1: Picking - up item
  // 2: Item pick-upped
  // 3: Dropped
  // 4: Completed
  int activeStep = 1;
  bool isUpdating = false;

  // 调用 API 更新状态
  Future<void> _updateStatus(int nextStep) async {
    setState(() => isUpdating = true);
    const String url = 'http://10.0.2.2:5000/api/order/update_status';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"order_id": widget.orderId, "status_code": nextStep}),
      );

      if (response.statusCode == 200) {
        setState(() {
          activeStep = nextStep;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed, please try again.")),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
    } finally {
      setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF0F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Item Delivery Progress',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildNoteCard(),
                const SizedBox(height: 30),
                _buildStatusSection(),
              ],
            ),
          ),
          if (isUpdating) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: _buildGradientChatButton(),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Please remember to get the receipt from the store.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          SizedBox(height: 6),
          Text(
            '• Remember to collect money from customer.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          _buildClickableStep(
            index: 1,
            label: 'Picking - up item',
            icon: Icons.store_mall_directory_outlined,
          ),
          _buildVerticalConnector(isActive: activeStep > 1),
          _buildClickableStep(
            index: 2,
            label: 'Item pick-upped',
            icon: Icons.local_shipping_outlined,
          ),
          _buildVerticalConnector(isActive: activeStep > 2),
          _buildClickableStep(
            index: 3,
            label: 'Dropped',
            icon: Icons.where_to_vote_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStep({
    required int index,
    required String label,
    required IconData icon,
  }) {
    bool isCurrent = activeStep == index;
    bool isCompleted = activeStep > index;

    Color stepColor = isCurrent
        ? const Color(0xFF0D47A1)
        : (isCompleted ? Colors.green : Colors.grey.shade400);
    Color bgColor = isCurrent
        ? const Color(0xFFFF4081).withOpacity(0.08)
        : (isCompleted ? Colors.green.withOpacity(0.05) : Colors.transparent);

    return InkWell(
      onTap: (isCurrent && activeStep < 4)
          ? () => _updateStatus(activeStep + 1)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF0D47A1).withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCurrent ? stepColor.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: stepColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: stepColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? Colors.black : stepColor,
                ),
              ),
            ),
            if (isCurrent)
              const Icon(Icons.touch_app, color: Color(0xFF0D47A1), size: 20),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalConnector({required bool isActive}) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(left: 41),
      height: 20,
      width: 2.5,
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.5) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildGradientChatButton() => FloatingActionButton(
    onPressed: () {},
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
      ),
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.white,
        size: 28,
      ),
    ),
  );
}
