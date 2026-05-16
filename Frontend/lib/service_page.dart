import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'profile_page.dart';
import 'order_history_page.dart';
import 'parcel_taking_page.dart';
import 'food_delivering_page.dart' as food;
import 'pickup_dropoff_page.dart';
import 'user_GroceryPurchasing.dart'; 
import 'item_delivery_page.dart';
import 'runner_main_menu.dart';

final baseUrl = kIsWeb
    ? 'http://127.0.0.1:5000'   // Chrome
    : 'http://10.0.2.2:5000';   // Emulator

//Service Page (after login/register)
class ServicePage extends StatefulWidget {
  final String studentID;
  const ServicePage({super.key, required this.studentID});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

//Service Page State
class _ServicePageState extends State<ServicePage> {
  int _currentTabIndex = 0;

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeContent(); // 首页的服务格子
      case 1:
        return OrderHistoryPage(studentID: widget.studentID);
      case 2:
        return RunnerMainMenu(runnerId: widget.studentID);
      case 3:
        return ProfilePage(studentID: widget.studentID);
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent(){
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Hey ${widget.studentID} 👋",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F3A5A),
                  ),
                ),
                
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF6C8EF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParcelTakingPage(studentID: widget.studentID))),
              ),
              _serviceCard(
                title: "Food Delivery",
                imagePath: "assets/fooddelivery_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => food.FoodDeliveringPage(studentID: widget.studentID))),
              ),
              _serviceCard(
                title: "Campus Ride Service",
                imagePath: "assets/pickupndropoff_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDeliveringPage(studentID: widget.studentID))),
              ),
              _serviceCard(
                title: "Grocery",
                imagePath: "assets/grocery_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroceryPurchasingScreen(studentID: widget.studentID))),
              ),
              _serviceCard(
                title: "Item Delivery",
                imagePath: "assets/grocery_image.png",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDeliveryPage(studentID: widget.studentID))),
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
      onTap: () {
        if (index == _currentTabIndex) return;

        setState((){
          _currentTabIndex = index;
        });
        if (index == 0) {
          return; // Already on Home, do nothing
        } else if (index == 1) {
          // Navigate to Orders page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryPage(studentID: widget.studentID),
            ),
          );
        } else if (index == 2) {
          // Navigate to Runner page
        } else if (index == 3) { 
          // Navigate to Profile page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(studentID: widget.studentID),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected
                ? const Color(0xFF6C8EF5)  //Selected color
                : const Color(0xFF9AA7BD), //Unselected color
          ),
          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? const Color(0xFF6C8EF5)
                  : const Color(0xFF9AA7BD),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom navigation bar
  Widget _bottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      //4 selectable items
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 让 Body 延伸到底部栏后面，防止白底
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [Color(0xFFEAF3FF), Color(0xFFBFD9FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _buildBody(), // 这里动态切换内容！
        ),
      ),
      bottomNavigationBar: _bottomBar(), // 底部栏永远固定在这里
    );
  }
  
}