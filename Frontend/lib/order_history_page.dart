import 'package:flutter/material.dart';
import 'package:my_new_app/service_page.dart';
import 'chat_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final String studentID;
  const OrderHistoryPage({super.key, required this.studentID});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> { 
  bool isSwitch = false; // For user/runner mode switch

  // User view with order details and status
  Widget _buildUserView() {
    return Column(
      children: [
        const Text(
          "User Order History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Order #12345", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text("Status: Delivered", style: TextStyle(fontSize: 12, color: Colors.green)),
              SizedBox(height: 4),
              Text("Items: Burger, Fries", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  //Runner view with different order details and status
  Widget _buildRunnerView() {
    return Column(
      children:[
        const Text(
          "Runner Order History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Order #54321", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text("Status: Completed", style: TextStyle(fontSize: 12, color: Colors.green)),
              SizedBox(height: 4),
              Text("Items Delivered: Pizza, Soda", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ]
    );
  }

  //Earning card widget
  Widget_earnCard(String title, String amount, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children:[
          Icon(icon, size: 28, color: Color(0xFF6C8EF5)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.w500, 
              color: Colors.blueGrey),
          ),
        const SizedBox(height: 4),
        Text(amount, 
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600, 
            color: Colors.green)),
        ],
      ),
    );
  }

  //_empty order card order
  Widget_emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
          ),
      child: Column(
        children:[
          Icon(icon, size: 32, color: Color(0xFF6C8EF5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF6C8EF5)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
        ]
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Chat button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(40),
              ),
            ),
            builder: (context) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: ChatPage(studentID: widget.studentID),
              );
            },
          );
        },
      ),
      //Background
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF3FF),
              Color(0xFFD6E8FF),
              Color(0xFFBFD9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top bar with icon and title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ServicePage(studentID: widget.studentID)),
                              );
                            },
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF6C8EF5),
                            size: 28,
                          ),
                        ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Orders",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F3A5A),
                              ),
                            ),
                          ),
                          Row(
                              children: [
                                Text(
                                    isSwitch ? "Runner Mode" : "User Mode",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2F3A5A),
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                              Switch(
                                value: isSwitch,
                                onChanged: (value) {
                                  setState(() {
                                    isSwitch = value;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                          ? "Switched to Runner Mode"
                                          : "Switched to User Mode",
                                      ),
                                    ),
                                  );
                                },
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF6C8EF5),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      isSwitch ? _buildRunnerView() : _buildUserView(),
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}