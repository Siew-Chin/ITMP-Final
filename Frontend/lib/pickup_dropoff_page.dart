//15
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'waiting_page.dart';
import 'pickup_dropoff_tracking_page.dart'; 
import 'package:stream_chat_flutter/stream_chat_flutter.dart'; 

class PickupDropoffPage extends StatefulWidget {
  final String studentID;
  final StreamChatClient client;
  const PickupDropoffPage({
    super.key, required this.studentID
    , required this.client
    });
  

  @override
  State<PickupDropoffPage> createState() => _PickupDropoffPageState();
}

class _PickupDropoffPageState extends State<PickupDropoffPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropOffController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isPickupDorm = false;
  bool _isDropOffDorm = false;
  bool _isUrgent = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropOffController.dispose(); 
    _detailsController.dispose();
    super.dispose();
  }


  double get _runnerProfit {
    return _isUrgent ? 6.0 : 5.0;
  }

  double get _totalToCollect {
    return _runnerProfit;
  }

  Future<void> _handleOrderNow() async {
    if (!_isPickupDorm && _pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a Pick Up Point or select Pickup from Dorm",
          ),
        ),
      );
      return;
    }

    if (!_isDropOffDorm && _dropOffController.text.trim().isEmpty) {
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
        Uri.parse('https://animation-phoenix-crevice.ngrok-free.dev/api/ride/create'),//API 13: Create Pickup & Drop-off Order
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', 
        },
        body: json.encode({
          "requester_id": widget.studentID,
          "type": "Ride",
          "is_urgent": _isUrgent,
          "item_price": 0,
          "runner_profit": _runnerProfit,
          "total_to_collect": _totalToCollect,

          "pickup_point": _pickupController.text,
          "dropoff_point": _dropOffController.text,

          "_isPickupDorm": _isPickupDorm,
          "_isDropOffDorm": _isDropOffDorm,

          "ride_details": _detailsController.text,
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
                targetPage: PickupDropoffTrackingPage(
                  client: widget.client,
                  orderId: serverOrderId,
                  studentID: widget.studentID,
                  totalPrice: _totalToCollect,
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      //Top Header
      appBar: AppBar(
        title: const Text('Ride', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
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
                // --- Pickup Section ---
                _buildSectionTitle("Pickup Point"),
                _buildLocationCard(
                  controller: _pickupController,
                  hint: "e.g. Library Entrance",
                  icon: Icons.location_on_outlined,
                  checkLabel: "Pick up from Dorm",
                  isCheck: _isPickupDorm,
                  onCheckChanged: (val) {
                    setState(() {
                      _isPickupDorm = val ?? false;
                      if (_isPickupDorm) {
                        _pickupController.clear();
                        _isDropOffDorm = false;
                      }
                    });
                  },
                ),

                const SizedBox(height: 25),

                // --- Dropoff Section ---
                _buildSectionTitle("Drop Off Point"),
                _buildLocationCard(
                  controller: _dropOffController,
                  hint: "e.g. Faculty of Engineering",
                  icon: Icons.flag_outlined,
                  checkLabel: "Drop off at Dorm",
                  isCheck: _isDropOffDorm,
                  onCheckChanged: (val) {
                    setState(() {
                      _isDropOffDorm = val ?? false;
                      if (_isDropOffDorm) {
                        _dropOffController.clear();
                        _isPickupDorm = false;
                      }
                    });
                  },
                ),

                const SizedBox(height: 25),

                _buildSectionTitle("Any details? (Optional)"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: _cardDecoration(),
                  child: TextField(
                    controller: _detailsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "e.g. I'm wearing a red shirt.",
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
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: CheckboxListTile(
                    title: const Text("Urgent (+RM 1.00 fee)", 
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    value: _isUrgent,
                    activeColor: Colors.red,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() => _isUrgent = val ?? false),
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
                      const Text("Total to Pay", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      Text("RM ${_totalToCollect.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // --- Info Note ---
                _buildNote(),

                const SizedBox(height: 30),
                // --- Order Button ---
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: _handleOrderNow,
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
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
    );
  }

  Widget _buildLocationCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String checkLabel,
    required bool isCheck,
    required Function(bool?) onCheckChanged,
  }) 
  {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: controller,
            enabled: !isCheck,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.blueGrey),
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            title: Text(checkLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: isCheck,
            activeColor: Colors.blue,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: onCheckChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
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
            child: Text("Note: Please pay money to runner when the ride arrives.", 
              style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}