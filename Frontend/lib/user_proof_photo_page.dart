import 'dart:io';
import 'package:flutter/material.dart';
import 'user_rating_page.dart';

class UserProofPhotoPage extends StatelessWidget {
  final String studentID;
  final File imageFile;

  const UserProofPhotoPage({super.key, required this.studentID, required this.imageFile});

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
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height:30),

            const Text(
              "Please confirm your delivery",
              style: TextStyle(fontSize: 16),
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
                    )
                  )
                );
              },
              child: const Text ("Confirm Delivery", style: TextStyle(fontSize:16),
            )
          ),
        ]
      )
    )
    );
  }
}
