//8
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 记得确认 pubspec.yaml 已经加了 http
import 'dart:convert';
import 'user_GroceryConfirm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery Purchasing UI',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F8FF), // 浅蓝色背景
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const GroceryPurchasingScreen(),
    );
  }
}

class GroceryPurchasingScreen extends StatefulWidget {
  const GroceryPurchasingScreen({super.key});

  @override
  State<GroceryPurchasingScreen> createState() =>
      _GroceryPurchasingScreenState();
}

class _GroceryPurchasingScreenState extends State<GroceryPurchasingScreen> {
  // 商店列表
  final List<String> _shops = [
    'Kipmall Kota Warisan',
    '99 Speedmart',
    'KK Supermart',
    '7-Eleven',
    '3E XMUM',
  ];

  String? _selectedShop;
  bool _isUrgent = false;
  bool _isLoading = false; // 用于显示加载状态
  final TextEditingController _listController = TextEditingController();

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  // --- 新增：对接后端 API 的函数 ---
  Future<void> _submitOrder() async {
    // 如果是 Android 模拟器用 10.0.2.2，真机用电脑局域网 IP
    const String apiUrl = 'http://10.0.2.2:5000/api/grocery/create';

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": "TEST1234", // 你的学号
          "shop_name": _selectedShop,
          "shopping_list": _listController.text,
          "urgent": _isUrgent,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Order Success: ${data['order_id']}");

        // 下单成功，跳转到确认/进度页面
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserGroceryConfirm()),
        );
      } else {
        _showErrorSnackBar("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Connection Failed: Please check your backend!");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Grocery Purchasing',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 选择商店
            _buildSectionTitle("1. Select a shop"),
            const SizedBox(height: 10),
            _buildCustomCard(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    "Select shop...",
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: _selectedShop,
                  icon: const Icon(Icons.store_outlined, color: Colors.grey),
                  items: _shops.map((String shop) {
                    return DropdownMenuItem<String>(
                      value: shop,
                      child: Text(shop),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedShop = value),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 2. 填写清单
            _buildSectionTitle("2. Please insert your shop list"),
            const SizedBox(height: 10),
            _buildCustomCard(
              child: TextField(
                controller: _listController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "1. Eggs\n2. Milk\n3. Bread...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 3. Urgent 选项
            GestureDetector(
              onTap: () => setState(() => _isUrgent = !_isUrgent),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isUrgent
                          ? const Icon(Icons.check, size: 16, color: Colors.red)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'Urgent (+30% surcharge)',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 4. Order 按钮
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_selectedShop == null) {
                          _showErrorSnackBar("Please select a shop first!");
                          return;
                        }
                        if (_listController.text.isEmpty) {
                          _showErrorSnackBar("Shopping list cannot be empty!");
                          return;
                        }
                        _submitOrder(); // 执行后端提交
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 25),

            // 5. 底部提示
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF00796B), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Note: Please pay the money to the runner when the grocery arrived your dorm!',
                      style: TextStyle(
                        color: Color(0xFF00796B),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
