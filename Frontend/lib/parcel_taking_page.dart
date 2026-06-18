//7
import 'package:flutter/material.dart';
import 'dart:convert';
import 'waiting_page.dart';
import 'parcel_tracking_page.dart'; 
import 'package:http/http.dart' as http;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ParcelTakingPage extends StatefulWidget {
  final String studentID;
  final StreamChatClient client;
  const ParcelTakingPage({
    super.key,required this.studentID, 
    required this.client
    });

  @override
  State<ParcelTakingPage> createState() => _ParcelTakingPageState();
}

class _ParcelTakingPageState extends State<ParcelTakingPage> {
  int parcel_qty = 1;
  final TextEditingController _dropOffController = TextEditingController();
  final TextEditingController _parcelDetailsController = TextEditingController();
  bool _isDorm = false;
  bool _isUrgent = false;

  @override
  void dispose() {
    _dropOffController.dispose();
    _parcelDetailsController.dispose();
    super.dispose();
  }

  // --- Price Calculation ---
  double get _totalPrice {
    double basePrice = 0.0;
    if (parcel_qty <= 5) {
      basePrice = parcel_qty * 2.0;
    } else {
      basePrice = (5 * 2.0) + ((parcel_qty - 5) * 1.5);
    }
    return _isUrgent ? basePrice + 1.0 : basePrice;
  }

  // --- Quantity control ---
  void _incrementQuantity() {
    setState(() {
      if (parcel_qty < 10) parcel_qty++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (parcel_qty > 1) parcel_qty--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      //Top Header
      appBar: AppBar(
        title: const Text(
          'Parcel Taking', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
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
                const Text(
                  "How many parcel you want to take ?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                //Quantity selector container
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
                            '$parcel_qty',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 5),
                          const Text("pcs", style: TextStyle(color: Colors.blueGrey, fontSize: 16)), 
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
                // --- Drop Off Section ---
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
                    // Drop-off location input field
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
                      //Checkbox: deliver to dorm
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
                //Details Box
                const Text(
                  "Parcel Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _parcelDetailsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 70),
                        child: Icon(Icons.description_outlined, color: Colors.blueGrey),
                      ),
                      hintText: "e.g. 2 Shopee parcels, 1 fragile box",
                      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                // --- Urgent Checkbox ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      "Urgent (+RM 1.00 surcharge)",
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
                // --- Total Price Card ---
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
                        "Total to Pay",
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
               // --- Info Note ---
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
                // --- Order Button ---
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
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
                        print("DEBUG: Sending request to server...");
                        final response = await http.post(
                          Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/parcel/create'),//API 3: create parcel order
                          headers: {
                            'Content-Type': 'application/json',
                            'ngrok-skip-browser-warning': 'true', 
                          },
                          body: json.encode({
                            "requester_id": widget.studentID,
                            "type": "Parcel",
                            "parcel_qty": parcel_qty,
                            "dropoff_point": _dropOffController.text.trim(),
                            "deliver_to_dorm": _isDorm,        
                            "is_urgent": _isUrgent,
                            "item_price": 0.0,
                            "runner_profit": _totalPrice, 
                            "total_to_collect": _totalPrice,
                            "parcel_details": _parcelDetailsController.text.trim(),
                          }),
                        ).timeout(const Duration(seconds: 10));

                        if (!mounted) return;
                        Navigator.pop(context); 

                        print("SERVER RESPONSE: ${response.body}");

                        if (response.statusCode == 201|| response.statusCode == 200) {
                          final data = json.decode(response.body);
                          final String? serverOrderId = data['order_id']?.toString();
                          if (serverOrderId != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaitingPage(
                                  orderId: serverOrderId,
                                  studentID: widget.studentID,
                                  totalPrice: _totalPrice,
                                  client: widget.client,
                                  targetPage: ParcelTrackingPage(
                                    client: widget.client,
                                    orderId: serverOrderId,
                                    studentID: widget.studentID,
                                    totalPrice: _totalPrice,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            print("ERROR: order_id is missing in JSON response");
                          }
                        } else {
                          print("SERVER ERROR STATUS: ${response.statusCode}");
                        }
                      } catch (e) {
                        if (mounted) Navigator.pop(context);
                        print("CATCH ERROR: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Connection failed: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text("Order Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
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