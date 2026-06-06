//11
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'waiting_page.dart';
import 'food_tracking_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';


class FoodDeliveringPage extends StatefulWidget {
  final String studentID;
  final StreamChatClient client;
  const FoodDeliveringPage({
    super.key,
    required this.studentID,
    required this.client
  });
  

  @override
  State<FoodDeliveringPage> createState() => _FoodDeliveringPageState();
}

class _FoodDeliveringPageState extends State<FoodDeliveringPage> {
  final TextEditingController _dropOffController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isDorm = false;
  List<dynamic> _menuFromDb = [];
  String? _selectedStall;
  String? _selectedFoodName;
  bool _isUrgent = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  @override
  void dispose() {
    _dropOffController.dispose(); // 只有当页面彻底关掉时，才释放资源
    _detailsController.dispose();
    super.dispose();
  }

  // --- API 逻辑 ---
  Future<void> _fetchMenu() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/food/menu')); //API 11: Get Food Menu
      if (response.statusCode == 200) {
        print("Raw Response: ${response.body}");
        final decodedData = json.decode(response.body);
        print("Decoded type: ${decodedData.runtimeType}");
        print("Decoded Data: $decodedData");
        setState(() {
          _menuFromDb = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load menu");
      }
    } catch (e) {
      print("Error fetching menu: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getCurrentFoodItems() {
    if (_selectedStall == null || _menuFromDb.isEmpty) return [];
    try {
      var stall = _menuFromDb.firstWhere((s) => s['stall_name'] == _selectedStall);
      return stall['food_items'] ?? [];
    } catch (e) {
      return [];
    }
  }

  double get _foodPrice {
  double price = 0.0;

  if (_selectedFoodName != null) {
    final currentItems = _getCurrentFoodItems();

    Map<String, dynamic>? food;

    try {
      food = currentItems.firstWhere(
        (item) => item['name'] == _selectedFoodName,
      );
    } catch (e) {
      food = null;
    }

    if (food != null) {
      price = double.tryParse(food['price'].toString()) ?? 0.0;
    }
  }

  return price;
}

double get _runnerProfit {
  return _isUrgent ? 6.0 : 5.0;
}

double get _totalToCollect {
  return _foodPrice + _runnerProfit;
}



  Future<void> _handleOrderNow() async {
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
        Uri.parse('http://10.0.2.2:5000/api/food/create'), //API 12: Create Food Order 
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "requester_id": widget.studentID,
          "type": "Food",
          "stall_name": _selectedStall,
          "food_name": _selectedFoodName!,
          "is_urgent": _isUrgent,
          "item_price": _foodPrice,
          "runner_profit": _runnerProfit,
          "total_to_collect": _totalToCollect,
          "dropoff_point": _dropOffController.text.trim(),
          "deliver_to_dorm": _isDorm, 
          "food_details": _detailsController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? serverOrderId = data['order_id']?.toString();

        if (serverOrderId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingPage(
                orderId: serverOrderId,
                studentID: widget.studentID,
                totalPrice: _totalToCollect,
                client: widget.client,
                targetPage: FoodTrackingPage(
                  client: widget.client,
                  orderId: serverOrderId,
                  studentID: widget.studentID,
                  totalPrice: _totalToCollect
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      // --- Top Header ---
      appBar: AppBar(
        title: const Text(
          'Food Delivering', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black87
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // --- Background ---
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
                const Text("Which stall would you like to order from?", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // --- Stall Dropdown ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStall,
                      hint: const Text("Select a stall"),
                      icon: const Icon(Icons.storefront, color: Colors.blueGrey),
                      isExpanded: true,
                      items: _menuFromDb.map<DropdownMenuItem<String>>((stall) {
                        return DropdownMenuItem<String>(
                          value: stall['stall_name'].toString(),
                          child: Text(stall['stall_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStall = newValue;
                          _selectedFoodName = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text("Which food you like?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // --- Food Dropdown ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: _selectedStall == null ? Colors.grey[200] : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [if (_selectedStall != null) BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFoodName,
                      hint: Text(_selectedStall == null ? "Please select a stall first" : "Select your food"),
                      icon: const Icon(Icons.fastfood_outlined, color: Colors.blueGrey),
                      isExpanded: true,
                      items: _selectedStall == null
                          ? []
                          : _getCurrentFoodItems().map<DropdownMenuItem<String>>((food) {
                              return DropdownMenuItem<String>(
                                value: food['name'].toString(),
                                child: Text(
                                  "${food['name']} (RM ${double.parse(food['price'].toString()).toStringAsFixed(2)})",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                                ),
                              );
                            }).toList(),
                      onChanged: _selectedStall == null
                          ? null
                          : (String? newValue) {
                              setState(() {
                                _selectedFoodName = newValue;
                              });
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const SizedBox(height: 25),
                const Text("Drop Off Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), blurRadius: 10, spreadRadius: 2)],
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
                      hintText: "e.g. No spicy, less ice...",
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5)
                      )
                    ],
                  ),
                  child: Row( 
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Total to Pay", 
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                            const Text(
                              "(runner fee RM5 added)", 
                              style: TextStyle(color: Colors.white70, fontSize: 12)
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 10), 
                      Text(
                        "RM ${_totalToCollect.toStringAsFixed(2)}", 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 24,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
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
                      Icon(Icons.info_outline, color: Color.fromARGB(255, 152, 177, 175)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Note: Please pay money to runner when the food arrived your dorm.", style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // --- Order Button ---
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: _selectedFoodName == null ? null : _handleOrderNow,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text("Order Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: _selectedFoodName == null ? 0 : 5,
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