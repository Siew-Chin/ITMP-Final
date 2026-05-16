import 'package:flutter/material.dart';
import 'runner_grocerydrop.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RunnerGroceryDrop(
        order: {
          "order_id": "ORDER123",
          "status_code": 1,
          "item_price": 10.0,
          "runner_profit": 2.0,
          "total_to_collect": 12.0,
          "dropoff_point": "123 Main St",
          "requester_id": "S12345678"
        },
        runnerId: "RUNNER123",
      ),
    );
  }
}
