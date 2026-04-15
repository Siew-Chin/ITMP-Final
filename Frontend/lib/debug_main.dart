import 'package:flutter/material.dart';
// 导入你写的页面文件
import 'runner_parcelconfirm.dart';

void main() {
  runApp(const MyDebugApp());
}

class MyDebugApp extends StatelessWidget {
  const MyDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 去掉右上角的 debug 标志
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ParcelPage(), // 这里直接放你的页面
    );
  }
}
