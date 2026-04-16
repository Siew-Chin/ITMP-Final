import 'package:flutter/material.dart';

// Parcel or Food Delivery page
class ParcelOrFood extends StatefulWidget {
  final String studentID; // Receive the passed student ID
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
                "Welcome, ${widget.studentID}", // Show the student ID on the page
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const Text(
                "Services", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Parcel Delivery 
              _serviceCard(
                "Parcel Delivery", 
                "assets/parcel_image.png", 
                const ParcelPage()
              ),

              const SizedBox(height: 20),

              // Food Delivery 
              _serviceCard(
                "Food Delivery", 
                "assets/fooddelivery_image.png", 
                const FoodDelivery()
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable card widget for services
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

// 暂时的占位页面
class ParcelPage extends StatelessWidget {
  const ParcelPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Parcel Page")));
}

class FoodDelivery extends StatelessWidget {
  const FoodDelivery({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Food Delivery Page")));
}