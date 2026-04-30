import 'package:flutter/material.dart';
import 'food_tracking_page.dart';

class FoodDeliveringPage extends StatefulWidget {
  const FoodDeliveringPage({super.key});

  @override
  State<FoodDeliveringPage> createState() => _FoodDeliveringPageState();
}

class _FoodDeliveringPageState extends State<FoodDeliveringPage> {
  final List<String> _stalls = ['Subway', 'Stall A', 'Stall B'];
  final Map<String, List<Map<String, dynamic>>> _menus = {
    'Subway': [{'name': 'Chicken Sub', 'price': 12.00}, {'name': 'Beef Sub', 'price': 15.00}],
    'Stall A': [{'name': 'Chicken Rice', 'price': 8.50}, {'name': 'Nasi Lemak', 'price': 6.00}],
    'Stall B': [{'name': 'Fried Noodles', 'price': 7.00}, {'name': 'Tom Yum Soup', 'price': 9.50}],
  };

  String? _selectedStall;
  Map<String, dynamic>? _selectedFood;
  bool _isUrgent = false;

  double get _totalPrice {
    double basePrice = 0.0;
    if (_selectedFood != null) basePrice = _selectedFood!['price']; 
    return _isUrgent ? basePrice * 1.3 : basePrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], 
      appBar: AppBar(
        title: const Text('Food Delivering', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Which stall would you like to order from?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStall,
                  hint: const Text("Select a stall"),
                  icon: const Icon(Icons.storefront, color: Colors.blueGrey),
                  isExpanded: true,
                  items: _stalls.map((String stall) {
                    return DropdownMenuItem<String>(value: stall, child: Text(stall, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStall = newValue;
                      _selectedFood = null; 
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text("Which food you like?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: _selectedStall == null ? Colors.grey[200] : Colors.white, 
                borderRadius: BorderRadius.circular(15),
                boxShadow: [if (_selectedStall != null) BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedFood,
                  hint: Text(_selectedStall == null ? "Please select a stall first" : "Select your food"),
                  icon: const Icon(Icons.fastfood_outlined, color: Colors.blueGrey),
                  isExpanded: true,
                  items: _selectedStall == null
                      ? []
                      : _menus[_selectedStall]!.map((food) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: food,
                            child: Text("${food['name']} (RM ${food['price'].toStringAsFixed(2)})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                  onChanged: _selectedStall == null
                      ? null 
                      : (Map<String, dynamic>? newValue) {
                          setState(() { _selectedFood = newValue; });
                        },
                ),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50], 
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: CheckboxListTile(
                title: const Text("Urgent (+30% surcharge)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                value: _isUrgent,
                activeColor: Colors.red,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() { _isUrgent = value ?? false; });
                },
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Colors.blue]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Price", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                  Text("RM ${_totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    child: Text("Note: Please pay money to runner when the food arrived your dorm.", style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: _selectedFood == null ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodTrackingPage(totalPrice: _totalPrice),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text("Order Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.grey[300], 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: _selectedFood == null ? 0 : 5,
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