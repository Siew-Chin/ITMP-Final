import 'package:flutter/material.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'service_page.dart';

final String url =  "http://google.com";

void main(){
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context){
    return const MaterialApp(
      home: UserRatingPage(studentID:"test123"),
    );
  }
}

//Rating page 
class UserRatingPage extends StatefulWidget{
  final String studentID;
  const UserRatingPage ({super.key, required this.studentID});

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
      title: Text(
        "Rate Your Experience",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize:22,
          fontWeight: FontWeight.bold,
        ),
      ),
      message: Text(
        'Tap a star to rate your experience',
        textAlign: TextAlign.center,
      ),
      submitButtonText:"Submit",
      onSubmitted: (response) async{
        print("⭐Rating: ${response.rating}");
        print("🗨️Comment: ${response.comment}");

        if(response.rating >= 4){
          final uri = Uri.parse(url);
          if(await canLaunchUrl(uri)){
            await launchUrl(uri);
          }
        }
        if (!mounted)return;

        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePage(
              studentID: widget.studentID,
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