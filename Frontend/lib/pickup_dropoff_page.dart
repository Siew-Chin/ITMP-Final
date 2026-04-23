import 'package:flutter/material.dart';
import 'pickup_dropoff_tracking_page.dart'; // 导入我们刚刚写好的第6页

class PickupDropoffPage extends StatefulWidget {
  const PickupDropoffPage({super.key});

  @override
  State<PickupDropoffPage> createState() => _PickupDropoffPageState();
}

class _PickupDropoffPageState extends State<PickupDropoffPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController(); // 用户输入的价格
  
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    // 监听价格输入框的变化，实时刷新页面计算总价
    _basePriceController.addListener(() {
      setState(() {}); 
    });
    // 监听地点输入框，用来控制按钮的亮灭
    _pickupController.addListener(() { setState(() {}); });
    _dropoffController.addListener(() { setState(() {}); });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  // --- 核心计算逻辑 ---
  double get _basePrice {
    return double.tryParse(_basePriceController.text) ?? 0.0;
  }

  double get _totalPrice {
    // 如果勾选 Urgent，在用户输入的基础上 +30%
    return _isUrgent ? _basePrice * 1.3 : _basePrice;
  }

  // 表单是否填写完整（决定按钮是否可点击）
  bool get _isFormValid {
    return _pickupController.text.trim().isNotEmpty && 
           _dropoffController.text.trim().isNotEmpty && 
           _basePrice > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Pick-up & Drop-off',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Pick up point 输入框
            const Text("Pick up point :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: TextField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.my_location, color: Colors.blueGrey),
                  hintText: "Where are you now?",
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Drop off point 输入框
            const Text("Drop off point :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: TextField(
                controller: _dropoffController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
                  hintText: "Where to?",
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 3. 价格输入框 (Offer Fare)
            const Text("Offer your fare (RM) :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: TextField(
                controller: _basePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.payments_outlined, color: Colors.green),
                  hintText: "e.g. 10.00",
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 25),

            // 4. Urgent 勾选项
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50], 
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: CheckboxListTile(
                title: const Text(
                  "Urgent (+30% surcharge)",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                value: _isUrgent,
                activeColor: Colors.red,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() {
                    _isUrgent = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(height: 25),

            // 5. 总价显示卡片 (实时计算)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Colors.blue]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Price",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "RM ${_totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Notes 公告栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.teal.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Note: Please pay money to driver when arrived the drop off point.",
                      style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 7. Order Now 按钮
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                // 表单没填完时，按钮置灰不可点
                onPressed: _isFormValid ? () {
                  print("Ride Ordered! Pickup: ${_pickupController.text}, Dropoff: ${_dropoffController.text}, Total: RM ${_totalPrice.toStringAsFixed(2)}");
                  // 跳转到追踪页 (第6页)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PickupDropoffTrackingPage(
                        totalPrice: _totalPrice,
                      ),
                    ),
                  );
                } : null,
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  "Order Now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.grey[300], 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: _isFormValid ? 5 : 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}