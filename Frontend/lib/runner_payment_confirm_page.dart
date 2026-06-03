//31
import 'package:flutter/material.dart';
import 'service_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class RunnerPaymentConfirmPage extends StatefulWidget {
  final String studentID;
  final double amount;
  final String customerName;
  final String customerStudentID;
  final String customerContact;
  final String orderId;
  final StreamChatClient client;
  const RunnerPaymentConfirmPage({
    super.key, 
    required this.studentID,
    required this.amount,
    required this.customerName,
    required this.customerStudentID,
    required this.customerContact,
    required this.orderId,
    required this.client,

    });

  @override
  State<RunnerPaymentConfirmPage> createState() => _RunnerPaymentConfirmPage();
}

class _RunnerPaymentConfirmPage extends State<RunnerPaymentConfirmPage> {
  double swipeValue = 0.0;
  bool isSubmitting = false;

  double? moneyToReceive;
  double? moneyEarned;
  String? liveCustomerName;
  String? liveCustomerContact;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestOrderSummary(); // 页面一打开，先查一下最新的账单
  }

  Future<void> _fetchLatestOrderSummary() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/order/summary?order_id=${widget.orderId}'),//API 10: Order Summary
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          moneyToReceive =
              double.tryParse(data['total_to_collect'].toString()) ?? 0.0;

          moneyEarned =
              double.tryParse(data['runner_profit'].toString()) ?? 0.0;

          liveCustomerName = data['user_name'];
          liveCustomerContact = data['user_contact'];

          isLoading = false;
        });
      }
    } catch (e) {
      print("Fetch order summary error: $e");
      setState(() => isLoading = false);
    }
  }
  
  Future<void> confirmMoneyCollected() async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/order/update_status'),//API 5: Update Status 
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "order_id": widget.orderId,
        "status_code": 4, 
        "runner_id": widget.studentID,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment confirmed & Earnings added!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ServicePage(studentID: widget.studentID, client: widget.client,),
        ),
      );
    } else {
      final errorMsg = jsonDecode(response.body)['message'] ?? "Server error";
      throw errorMsg;
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
    // 如果失败了，把滑动条重置，允许用户重试
    setState(() {
      isSubmitting = false;
      swipeValue = 0.0;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow:[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Money To Be Received",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "RM ${(moneyToReceive ?? 0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F3A5A),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF6C8EF5),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                "Money Earned: RM ${(moneyEarned ?? 0).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2F3A5A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height:24),

                  _infoRow(Icons.person_outline, "Customer", liveCustomerName ?? widget.customerName),
                    const SizedBox(height: 14),
                    _infoRow(Icons.phone_outlined, "Contact", liveCustomerContact ?? widget.customerContact),
                ],
              ),
            ),
            const Spacer(),

            const Center(
              child: Text(
                "Swipe to confirm money collected", 
                style: const TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF23A5A),
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
                color: Colors.white.withValues(alpha:0.95),
                borderRadius: BorderRadius.circular(35),
                boxShadow:[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                  activeTrackColor: const Color(0xFF6C8EF5),
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: const Color(0xFF6C8EF5),
                ),
                child: Slider(
                  value: swipeValue,
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    // 关键 1: 如果已经在提交中，彻底屏蔽所有滑动事件
                    if (isSubmitting) return;

                    setState(() {
                      swipeValue = value;
                    });

                    // 关键 2: 提高阈值到 0.95，并在确认触发后立即锁定状态
                    if (value > 0.95) {
                      setState(() {
                        isSubmitting = true; 
                        swipeValue = 1.0; // 视觉上吸附
                      });
                      
                      // 关键 3: 延迟一小下再发请求，给 UI 留出渲染吸附动画的时间
                      // 这样可以避免滑动条动画和网络请求抢夺主线程资源
                      Future.delayed(const Duration(milliseconds: 200), () {
                        confirmMoneyCollected();
                      });
                    }
                  },
                  // 关键 4: 增加 onChangeEnd，如果用户滑了一半松开，自动弹回
                  onChangeEnd: (value) {
                    if (value <= 0.95 && !isSubmitting) {
                      setState(() {
                        swipeValue = 0.0;
                      });
                    }
                  },
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