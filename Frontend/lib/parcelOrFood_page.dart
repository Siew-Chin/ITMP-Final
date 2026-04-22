import 'package:flutter/material.dart';
import 'parcel_taking_page.dart'; 
import 'food_delivering_page.dart'; // ✅ 导入刚刚写好的外卖页面

// Parcel or Food Delivery page
class ParcelOrFood extends StatefulWidget {
  final String studentID; // 接收传来的 ID
  const ParcelOrFood({super.key, required this.studentID});

  @override
  State<ParcelOrFood> createState() => ParcelOrFoodState();
}

class ParcelOrFoodState extends State<ParcelOrFood> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Your Dorm'),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        leading: const Icon(Icons.menu),
      ),
      backgroundColor: Colors.blue[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Welcome, ${widget.studentID}", // 显示当前用户ID
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const Text(
                "Services", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Parcel Delivery 卡片
              _serviceCard(
                "Parcel Delivery", 
                "assets/parcel_image.png", 
                const ParcelTakingPage() 
              ),

              const SizedBox(height: 20),

              // ✅ Food Delivery 卡片 (现在连到真正的外卖页面了！)
              _serviceCard(
                "Food Delivery", 
                "assets/fooddelivery_image.png", 
                const FoodDeliveringPage() 
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 封装一个通用的卡片组件，减少重复代码
  Widget _serviceCard(String title, String imagePath, Widget destination) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 24, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}