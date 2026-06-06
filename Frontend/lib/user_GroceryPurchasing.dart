//19
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'user_GroceryConfirm.dart';
import 'waiting_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class GroceryPurchasingScreen extends StatefulWidget {
  final String studentID; // 接收学号
  final StreamChatClient client;
  const GroceryPurchasingScreen({super.key, required this.studentID, required this.client});

  @override
  State<GroceryPurchasingScreen> createState() =>
      _GroceryPurchasingScreenState();
}

class _GroceryPurchasingScreenState extends State<GroceryPurchasingScreen> {
  final TextEditingController _dropOffController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _listController = TextEditingController();
  bool _isDorm = false;
  List<dynamic> _dynamicShops = []; 
  String? _selectedShop;
  bool _isUrgent = false;
  bool _isLoading = true;

  double get _itemPrice => 0.0;

  @override
  void initState() {
    super.initState();
    _fetchShops(); 
  }

  @override
  void dispose() {
    _dropOffController.dispose(); 
    _detailsController.dispose();
    _listController.dispose();
    super.dispose();
  }

  // --- API 逻辑 ---
  Future<void> _fetchShops() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/grocery/shops'));//API 14: Get Shop List 
      if (response.statusCode == 200) {
        print("Raw Response: ${response.body}");
        final decodedData = json.decode(response.body);
        print("Decoded type: ${decodedData.runtimeType}");
        print("Decoded Data: $decodedData");
        setState(() {
          _dynamicShops = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load shops");
      }
    } catch (e) {
      print("Error fetching shops: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

double get _runnerProfit {
  return _isUrgent ? 6.0 : 5.0;
}

double get _totalToCollect {
  return _itemPrice + _runnerProfit;
}



  Future<void> _handleOrderNow() async {
    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a shop")));
      return;
    }
    if (_listController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your shopping list")));
      return;
    }
    
    if (!_isDorm && _dropOffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a Drop Off Point or select Deliver to Dorm",
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/grocery/create'),//API 15: Creat Grocery Order
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "requester_id": widget.studentID,
          "type": "Grocery",
          "shop_name": _selectedShop,
          "shopping_list": _listController.text.trim(),
          "item_price": _itemPrice,
          "runner_profit": _runnerProfit,
          "total_to_collect": _totalToCollect,
          "dropoff_point": _dropOffController.text.trim(),
          "deliver_to_dorm": _isDorm,
          "shopping_details": _detailsController.text,
          "is_urgent": _isUrgent,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? serverOrderId = data['order_id']?.toString();

        if (!mounted) return;

        if (serverOrderId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingPage(
                client: widget.client,
                orderId: serverOrderId,
                studentID: widget.studentID,
                totalPrice: _totalToCollect,
                targetPage: UserGroceryConfirm(
                  client: widget.client,
                  orderId: serverOrderId,
                  studentID: widget.studentID,
                ),
              ),
            ),
          );
        }
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order failed: $e")));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildCustomCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: child,
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      extendBodyBehindAppBar: true,
      // --- Top Header ---
      appBar: AppBar(
        title: const Text('Grocery Purchasing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // --- Background ----
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight, 
            colors:[
            Color(0xFFEAF3FF),
            Color(0xFFD6E8FF),
            Color(0xFFBFD9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("Which shop would you like?"),
                const SizedBox(height: 10),
                _buildCustomCard(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedShop,
                      hint: const Text("Select a shop"),
                      icon: const Icon(Icons.storefront, color: Colors.blueGrey),
                      isExpanded: true,
                      items: _dynamicShops.map<DropdownMenuItem<String>>((shop) {
                        String shopName = shop['name']?.toString() ?? "Unknown Shop";

                        return DropdownMenuItem<String>(
                          value: shopName,
                          child: Text(
                            shopName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedShop = newValue);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionTitle("Please insert your shop list"),
                const SizedBox(height: 10),
                _buildCustomCard(
                  child: TextField(
                    controller: _listController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "1. Eggs\n2. Milk\n3. Bread...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionTitle("Drop Off Point"),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
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
                              _dropOffController.clear();
                            } 
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text("Any details? (Optional)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: TextField(
                    controller: _detailsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "e.g. I want XXX brand of milk, please check the price with me before purchase.",
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                // --- Urgent Checkbox ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent.withValues(alpha:0.3)),
                  ),
                  child: CheckboxListTile(
                    title: const Text("Urgent (+RM 1.00 fee)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                // --- Total Price Card ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Colors.blue]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha:0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Runner fee RM5",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "(Grocery fee not added)",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12, // 减小副标题字体
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // --- Info Note ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.teal.withValues(alpha:0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Note: Grocery cost will be added by runner. Please pay the total amount upon delivery.", style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // --- Order Button ---
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: (_selectedShop == null || _listController.text.isEmpty) ? null : _handleOrderNow,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text("Order Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}