//21
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_deliverydrop.dart'; // 确保文件名引用正确

class RunnerDeliveryTake extends StatefulWidget {
  final String orderId;

  const RunnerDeliveryTake({super.key, required this.orderId});

  @override
  State<RunnerDeliveryTake> createState() => _RunnerDeliveryTakeState();
}

class _RunnerDeliveryTakeState extends State<RunnerDeliveryTake> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    final String url =
        'http://10.0.2.2:5000/api/order/detail/${widget.orderId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _orderData = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTakeOrder() async {
    const String url = 'http://10.0.2.2:5000/api/order/update_status';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "order_id": widget.orderId,
          "status_code": 1, // 接单后状态变为 1
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Status updated successfully to 1');
        if (!mounted) return;

        // 跳转并传递 orderId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RunnerDeliveryDrop(orderId: widget.orderId),
          ),
        );
      } else {
        debugPrint('Failed to update status');
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F7FF),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Item Delivery Service',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Customer Information'),
                  _buildInfoCard([
                    _buildDataRow('Name', _orderData?['requester_id'] ?? 'N/A'),
                    _buildDataRow('Order ID', widget.orderId),
                    _buildDataRow(
                      'Dorm',
                      _orderData?['dropoff_point'] ?? 'N/A',
                    ),
                    _buildDataRow(
                      'Contact',
                      _orderData?['requester_contact'] ?? 'N/A',
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Delivery Details'),
                  _buildInfoCard([
                    _buildDataRow(
                      'Quantity',
                      '${_orderData?['parcel_qty'] ?? 0} Items',
                    ),
                    _buildDataRow(
                      'Pick-up Point',
                      _orderData?['pickup_point'] ?? 'N/A',
                    ),
                    _buildDataRow(
                      'Drop-off Point',
                      _orderData?['dropoff_point'] ?? 'N/A',
                    ),
                    const Divider(height: 30, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Money to be received:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'RM ${_orderData?['delivery_fee'] ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 40),
                  _buildGradientButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleTakeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          'Take',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
  );

  Widget _buildInfoCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _buildDataRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
