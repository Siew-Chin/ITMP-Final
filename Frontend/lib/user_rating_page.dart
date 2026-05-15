//24
import 'package:flutter/material.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'service_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

final String url =  "http://google.com";

class UserRatingPage extends StatefulWidget{
  final String studentID;
  final String orderId;
  final StreamChatClient client;
  const UserRatingPage ({super.key, required this.studentID, required this.orderId, required this.client});

  @override
  State<UserRatingPage> createState() => _UserRatingPageState();
}

class _UserRatingPageState extends State<UserRatingPage>{
  late final RatingDialog _dialog;

  @override
  void initState(){
    super.initState();

    _dialog = RatingDialog(
      initialRating: 3.0,
      title: const  Text(
        "Rate Your Experience",
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize:22,
          fontWeight: FontWeight.bold,
        ),
      ),
      message: const Text(
        'Tap a star to rate your experience',
        textAlign: TextAlign.center,
      ),
      submitButtonText:"Submit",
      onSubmitted: (response) async{
        print("⭐Rating: ${response.rating}");
        print("🗨️Comment: ${response.comment}");

        try {
        final res = await http.post(
          Uri.parse("http://10.0.2.2:5000/api/order/feedback"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "order_id": widget.orderId, 
            "rating": response.rating,
            "comment": response.comment,
          }),
        );

        print("Feedback API: ${res.body}");
      } catch (e) {
        print("Feedback error: $e");
      }

        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePage(
              studentID: widget.studentID,
              client: widget.client,
            ),
            )
        );
               }
    );
    WidgetsBinding.instance.addPostFrameCallback((_){
      showDialog(
        context: context,
        builder: (context) => _dialog
      );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async => false,
      child: Scaffold(
      //Background 
      body: Container(
        width: double.infinity,
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
          child: Center(
            child: ElevatedButton(
              onPressed:(){
                showDialog(
                  context: context,
                  builder: (context) => _dialog,
                );
              },
              child: const Text("Rate Us"), 
            )
          )
        )
      )
    );
  }
}