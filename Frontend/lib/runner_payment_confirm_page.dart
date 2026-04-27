import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'service_page.dart';

class RunnerPaymentConfirmPage extends StatefulWidget {
  final String studentID;
  final double amount;
  final String customerName;
  final String customerStudentID;
  final String customerContact;

  const RunnerPaymentConfirmPage({
    super.key, 
    required this.studentID,
    required this.amount,
    required this.customerName,
    required this.customerStudentID,
    required this.customerContact,
    });

  @override
  State<RunnerPaymentConfirmPage> createState() => _RunnerPaymentConfirmPage();
}

class _RunnerPaymentConfirmPage extends State<RunnerPaymentConfirmPage> {
  double swipeValue = 0.0;
  
  void confirmMoneyCollected(){
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Money collected confirmed!")),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ServicePage(studentID: widget.studentID),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Background 
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
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
            const SizedBox(height: 30),
            //Payment card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow:[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(
                    "RM ${widget.amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3A5A),
                    ),
                  ),
                  const SizedBox(height:24),

                  _infoRow(Icons.person_outline,"Customer", widget.customerName),
                  const SizedBox(height:14),
                  _infoRow(Icons.badge_outlined,"Student ID", widget.customerStudentID),
                  const SizedBox(height:14),
                  _infoRow(Icons.phone_outlined,"Contact", widget.customerContact),
                ],
              ),
            ),
            const Spacer(),

            const Center(
              child: Text(
                "Swipe to confirm money collected", 
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF23A5A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height:10),

            //Swipe bar
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(35),
                boxShadow:[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 50,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius:24,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: const Color(0xFF6C8FEF5),
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: const Color(0xFF6C8EF5),
                ),
                child: Slider(
                  value: swipeValue,
                  min: 0,
                  max: 1,
                  onChanged: (value){
                    setState((){
                      swipeValue = value;
                    });
                    if(value > 0.95){
                      confirmMoneyCollected();
                    }
                  }
                )
              )
            )
          ]
        )
      )
    )
  );
}
}

Widget _infoRow(IconData icon, String title, String value){
  return Row(
    children: [
      Icon(icon, color: const Color(0xFF6C8EF5), size: 24),
      const SizedBox(width: 12),
      Text(
        "$title: ",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.blueGrey, 
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F3a5A), 
          ),
        ),
      )
    ],
  );
}