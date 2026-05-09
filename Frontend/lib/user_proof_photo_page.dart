//23
import 'package:flutter/material.dart';
import 'user_rating_page.dart';

class UserProofPhotoPage extends StatelessWidget {
  final String studentID;
  final String orderId;
  final String imageUrl;

  const UserProofPhotoPage({
    super.key, 
    required this.studentID, 
    required this.orderId,
    required this.imageUrl
  });

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),

      appBar: AppBar(
        title: const Text ("Delivery Proof Photo"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl, 
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                },
                // 如果图片加载失败的显示
                errorBuilder: (context, error, stackTrace) => 
                  const SizedBox(height: 300, child: Center(child: Icon(Icons.broken_image, size: 50))),
              ),
            ),
            const SizedBox(height:30),

            const Text(
              "Please confirm your delivery",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height:30),

            //Confirm button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C8EF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: (){
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => UserRatingPage(
                      studentID: studentID,
                      orderId: orderId,
                    )
                  )
                );
              },
              child: const Text ("Confirm Delivery", style: const TextStyle(fontSize:16),
            )
          ),
        ]
      )
    )
    );
  }
}
