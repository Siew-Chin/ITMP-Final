import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'runner_parcelinstructions.dart';

class ParcelPage extends StatefulWidget {
  final String orderId;
  const ParcelPage({super.key, required this.orderId});

  @override
  State<ParcelPage> createState() => _ParcelPageState();
}

class _ParcelPageState extends State<ParcelPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController dormController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController moneyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/order/user_info?order_id=${widget.orderId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nameController.text = data['name'] ?? "";
          // 💡 这里的 'id' 对应后端 API 返回的 requester 学号
          idController.text = data['id'] ?? "";
          dormController.text = data['dorm'] ?? "";
          contactController.text = data['contact'] ?? "";
          qtyController.text = data['parcel_qty']?.toString() ?? "0";
          moneyController.text = data['money_to_receive']?.toString() ?? "0.0";
        });
      }
    } catch (e) {
      print("Error loading user info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        title: const Text('Parcel Confirm'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildInputField("Name :", nameController),
              _buildInputField("ID :", idController),
              _buildInputField("Dorm :", dormController),
              _buildInputField("Contact :", contactController),
              _buildInputField("Number of parcel :", qtyController),
              _buildInputField("Money to be received :", moneyController),
              const SizedBox(height: 30),

              // 💡 这里是替换后的 ElevatedButton
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstructionsPage(
                        orderId: widget.orderId, // 传递当前订单 ID
                        runnerId: "FIT2508089", // 这里的学号可根据实际登录情况动态获取
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(150, 60),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'take',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

// 💡 修复了底部的 main 函数，确保传入了 orderId 参数
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ParcelPage(orderId: "A_1014"),
    ),
  );
}
