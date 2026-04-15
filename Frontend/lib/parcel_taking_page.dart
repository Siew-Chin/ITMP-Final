import 'package:flutter/material.dart';

class ParcelTakingPage extends StatefulWidget {
  const ParcelTakingPage({super.key});

  @override
  State<ParcelTakingPage> createState() => _ParcelTakingPageState();
}

class _ParcelTakingPageState extends State<ParcelTakingPage> {
  int _quantity = 1;
  final TextEditingController _priceController = TextEditingController();

  // 增加数量
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // 减少数量
  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 继承你截图里的浅蓝背景色
      backgroundColor: Colors.blue[50], 
      appBar: AppBar(
        title: const Text(
          'Parcel Order',
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
            // 1. 公告栏 (Announcement Place)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Announcement: Please ensure your parcel size is acceptable for a single runner.",
                      style: TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. 包裹数量选择 (Quantity)
            const Text(
              "How many parcels?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.blue,
                        onPressed: _decrementQuantity,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.blue,
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 3. 价格选择/输入 (Price)
            const Text(
              "Offer a Price (RM)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.payments_outlined, color: Colors.blueGrey),
                  hintText: "e.g. 5.00",
                  prefixText: "RM ",
                  prefixStyle: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),

            // 4. 下单按钮 (Launch Order)
            ElevatedButton(
              onPressed: () {
                // 这里暂时只做打印测试，之后再接你的 Flask 后端
                print("Order Launched! Qty: $_quantity, Price: RM ${_priceController.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // 深蓝色，类似你截图里的按钮底色
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: const Text(
                "Launch Order",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}