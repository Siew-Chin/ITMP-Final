//3
import 'package:flutter/material.dart';

import 'profile_page.dart';
import 'order_history_page.dart';
import 'runner_main_menu.dart';

import 'parcel_taking_page.dart';
import 'food_delivering_page.dart' as food;
import 'pickup_dropoff_page.dart';
import 'user_GroceryPurchasing.dart'; 
import 'item_delivery_page.dart';

import 'parcel_tracking_page.dart';
import 'food_tracking_page.dart';
import 'pickup_dropoff_tracking_page.dart';
import 'user_GroceryConfirm.dart';
import 'tracking_delivery_page.dart';

import 'waiting_page.dart';

import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


//Service Page (after login/register)
class ServicePage extends StatefulWidget {
  final String studentID;
  final StreamChatClient client;
  const ServicePage({super.key, required this.studentID, required this.client});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

//Service Page State
class _ServicePageState extends State<ServicePage> {
  int _currentTabIndex = 0;
  String? _imageUrl; // 用于存储头像 URL
  String _userName = ""; // 用于存储用户名
  String _statusText(int statusCode) {
  switch (statusCode) {
    case 0:
      return "Waiting";
    case 1:
      return "Order Taken";
    case 2:
      return "In Progress";
    case 3:
      return "Delivering";
    case 4:
      return "Completed";
    default:
      return "Unknown";
  }
}

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // 页面加载时获取用户信息
    _userName = widget.studentID; // 默认先显示 ID
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/user/get_info/${widget.studentID}'),//API 23: Get user new info 
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _imageUrl = data['image_url'];
            _userName = data['name'] ?? widget.studentID;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch User Info Error: $e");
    }
  }

  Future<List<dynamic>> _fetchCurrentOrders() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/user/current_orders?requester_id=${widget.studentID}'),//API 26: User Current Orders
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    }

    return [];
  }

  Future<bool> _checkRunnerAccess() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/runner/rating_status?runner_id=${widget.studentID}'),//API 25: Runner Rating Status
    );

    if (response.statusCode != 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    final int completedTaskCount = data['completed_task_count'] ?? 0;
    final double? averageRating = data['average_rating'] == null
        ? null
        : double.tryParse(data['average_rating'].toString());

    final bool shouldWarn = data['should_warn'] == true;
    final bool shouldBlock = data['should_block'] == true;

    if (!mounted) return false;

    if (shouldBlock) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Runner Access Blocked"),
          content: Text(
            "Your rating is too low.\n\n"
            "Completed tasks: $completedTaskCount\n"
            "Average rating: ${averageRating?.toStringAsFixed(1) ?? 'N/A'}\n\n"
            "You cannot access the runner page now.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      setState(() => _currentTabIndex = 0);
      return false;
    }

    if (shouldWarn) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Rating Warning"),
          content: Text(
            "Please be careful with your service quality.\n\n"
            "Completed tasks: $completedTaskCount\n"
            "Average rating: ${averageRating?.toStringAsFixed(1) ?? 'N/A'}\n\n"
            "If your rating is still below 3.0 after 10 completed tasks, runner access will be blocked.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("I Understand"),
            ),
          ],
        ),
      );
    }

    return true;
  } catch (e) {
    debugPrint("Runner rating check error: $e");
    return true;
  }
}

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeContent(); // 首页的服务格子
      case 1:
        return OrderHistoryPage(studentID: widget.studentID, client: widget.client);
      case 2:
        return RunnerMainMenu(runnerId: widget.studentID, client: widget.client);
      case 3:
        return ProfilePage(studentID: widget.studentID, client: widget.client, onProfileUpdated: _fetchUserInfo,);
      default:
        return _buildHomeContent();
    }
  }

  void _openCurrentOrder(dynamic order) {
    final type = (order['type'] ?? '').toString().toLowerCase();
    final orderId = order['order_id'].toString();
    final statusCode = int.tryParse(order['status_code'].toString()) ?? 0;
    final totalPrice = double.tryParse(order['total_to_collect'].toString()) ?? 0.0;

    Widget trackingPage;

    if (type == 'parcel') {
      trackingPage = ParcelTrackingPage(
        orderId: orderId,
        totalPrice: totalPrice,
        studentID: widget.studentID,
        client: widget.client,
      );
    } else if (type == 'food') {
      trackingPage = FoodTrackingPage(
        orderId: orderId,
        totalPrice: totalPrice,
        studentID: widget.studentID,
        client: widget.client,
      );
    } else if (type == 'grocery') {
      trackingPage = UserGroceryConfirm(
        orderId: orderId,
        studentID: widget.studentID,
        client: widget.client,
      );
    } else if (type == 'item') {
      trackingPage = TrackingDeliveryPage(
        orderId: orderId,
        totalPrice: totalPrice,
        studentID: widget.studentID,
        client: widget.client,
      );
    } else {
      trackingPage = PickupDropoffTrackingPage(
        orderId: orderId,
        totalPrice: totalPrice,
        studentID: widget.studentID,
        client: widget.client,
      );
    }

  final Widget page = statusCode == 0
      ? WaitingPage(
          orderId: orderId,
          studentID: widget.studentID,
          totalPrice: totalPrice,
          client: widget.client,
          targetPage: trackingPage,
        )
      : trackingPage;

  Navigator.pop(context);

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

  Future<void> _showCurrentOrdersDialog() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return FutureBuilder<List<dynamic>>(
        future: _fetchCurrentOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Text("Current Orders"),
            content: SizedBox(
              width: double.maxFinite,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : orders.isEmpty
                      ? const Text("No current orders.")
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final statusCode = int.tryParse(order['status_code'].toString()) ?? 0;
                            final orderTime = order['created_at'] ?? 'N/A';

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openCurrentOrder(order),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Order Type: ${order['type'] ?? 'Order'}",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          orderTime,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text("Status: ${_statusText(statusCode)}"),
                                    Text("Runner: ${order['runner_name'] ?? 'Waiting for runner'}"),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 35),
        child: Transform.scale(
          scale: 0.86,
          child: FloatingActionButton.extended(
            heroTag: "currentOrdersButton",
            onPressed: _showCurrentOrdersDialog,
            backgroundColor: Colors.white.withOpacity(0.95),
            foregroundColor: const Color(0xFF6C8EF5),
            elevation: 6,
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text(
              "Current Orders",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FF), Color(0xFFBFD9FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // --- 统一固定的 Top Bar ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Hey $_userName 👋",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F3A5A),
                        ),
                      ),
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          )
                        ],
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? NetworkImage(_imageUrl!)
                              : const AssetImage("assets/user_image.png") as ImageProvider,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // --- 动态变化的子页面内容 ---
              Expanded(
                child: _buildBody(), 
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _buildHomeContent(){
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            "What do you need today?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F3A5A),
            ),
          ),
          const SizedBox(height: 20),

          // Service cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.7,
            children: [
              _serviceCard(
                title: "Parcel Delivery",
                imagePath: "assets/parcel_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParcelTakingPage(studentID: widget.studentID, client: widget.client))),
              ),
              _serviceCard(
                title: "Food Delivery",
                imagePath: "assets/fooddelivery_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => food.FoodDeliveringPage(studentID: widget.studentID, client: widget.client))),
              ),
              _serviceCard(
                title: "Ride",
                imagePath: "assets/pickupndropoff_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PickupDropoffPage(studentID: widget.studentID, client: widget.client))),
              ),
              _serviceCard(
                title: "Grocery",
                imagePath: "assets/grocery_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroceryPurchasingScreen(studentID: widget.studentID, client: widget.client))),
              ),
              _serviceCard(
                title: "Item Delivery",
                imagePath: "assets/grocery_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDeliveryPage(studentID: widget.studentID, client: widget.client))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required String title, //Title
    required String imagePath, //Image path
    required VoidCallback onTap, //Tap action
  }) {
    return GestureDetector(
      onTap: onTap, // Tap action
      child: Container( // Card container
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        //Service card content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            // Title and button
            Expanded(
            child:Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3A5A),
                    ),
                  ),
                  const Spacer(), // Push the button to the bottom

                  // Select button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8FB3FF),
                          Color(0xFF5C84F7),
                        ],
                      ),
                    ),
                    child: const Text(
                      "Select",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool selected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () async {
        await _fetchUserInfo();

        if (index == 2) {
          final canEnterRunnerPage = await _checkRunnerAccess();

          if (!canEnterRunnerPage) {
            return;
          }
        }

        if (mounted) {
          setState(() => _currentTabIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: selected ? const Color(0xFF6C8EF5) : const Color(0xFF9AA7BD)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? const Color(0xFF6C8EF5) : const Color(0xFF9AA7BD),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom navigation bar
  Widget _bottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, "Home", 0),
          _navItem(Icons.inventory_2_outlined, "Orders", 1),
          _navItem(Icons.payments_outlined, "Runner", 2),
          _navItem(Icons.person_outline_rounded, "Profile", 3),
        ],
      ),
    );
  }
  
}