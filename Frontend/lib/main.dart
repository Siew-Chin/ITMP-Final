import 'package:flutter/material.dart';
import 'runner_payment_confirm_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RunnerPaymentConfirmPage(studentID:"test123", amount:3.00, customerName: "ABC", customerContact: "123", customerStudentID: "ABC",),
    );
  }
}