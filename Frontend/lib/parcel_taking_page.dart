import 'package:flutter/material.dart';
import 'parcel_tracking_page.dart';

class ParcelTakingPage extends StatefulWidget {
  const ParcelTakingPage({super.key});

  @override
  State<ParcelTakingPage> createState() => _ParcelTakingPageState();
}

class _ParcelTakingPageState extends State<ParcelTakingPage> {
  int _quantity = 1;
  final TextEditingController _dropOffController = TextEditingController();
  bool _isDorm = false;
  bool _isUrgent = false;

  // --- 核心计算逻辑 ---
  double get _totalPrice {
    double basePrice = 0.0;
    if (_quantity <= 5) {
      // 1-5个: RM 2.00 / each
      basePrice = _quantity * 2.0;
    } else {
      // 5个以上: 前5个RM10，剩下的 RM 1.50 / each
      basePrice = (5 * 2.0) + ((_quantity - 5) * 1.5);
    }
    // 如果勾选 Urgent，总价增加 30%
    return _isUrgent ? basePrice * 1.3 : basePrice;
  }

  void _incrementQuantity() {
    setState(() {
      if (_quantity < 10) _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Parcel Taking', // 标题
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
            // 1. 数量选择区域
            const Text(
              "How many parcel you want to take ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                        onPressed: _decrementQuantity,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      const Text("pcs", style: TextStyle(color: Colors.blueGrey, fontSize: 16)), // 结尾写着pcs
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. Drop Off Point 输入框 & Dorm 勾选项
            const Text(
              "Drop Off Point",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _dropOffController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.location_on_outlined, color: Colors.blueGrey),
                      hintText: "e.g. Block A, Room 101",
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text("Deliver to Dorm", style: TextStyle(fontWeight: FontWeight.w500)),
                    value: _isDorm,
                    activeColor: Colors.blue,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDorm = value ?? false;
                        if (_isDorm) {
                          _dropOffController.text = "My Dorm"; // 自动填入
                        } else {
                          _dropOffController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 3. Urgent 勾选项
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50], // 用浅红色突出 Urgent
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
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

            // 4. 总价显示
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Colors.blue]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
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

            // 5. Notes 公告栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Note: The runner will reach your dorm to take your id card. Please pay the money to the runner when the parcel arrived your dorm!",
                      style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 6. 右下角 Order Now 按钮
            // 找到按钮这一段，修改 onPressed 里的内容
Align(
  alignment: Alignment.bottomRight,
  child: ElevatedButton.icon(
    onPressed: () {
      // 1. 这里是跳转逻辑
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParcelTrackingPage(
            totalPrice: _totalPrice, // 把算好的总价传给下一页显示
          ),
        ),
      );
      
      // 2. 以后你在这里接 API 3 (/api/parcel/create)
      print("Order Successfully Created!");
    },
    icon: const Icon(Icons.send_rounded),
    label: const Text(
      "Order Now",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,  
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 5,
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