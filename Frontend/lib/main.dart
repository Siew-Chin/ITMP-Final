import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = StreamChatClient(
    '659pk8bnxecv',
  logLevel: Level.INFO,
  connectTimeout: const Duration(seconds: 30), 
  receiveTimeout: const Duration(seconds: 30),
 );

  print("✅ DEBUG: Client created, launching App...");

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final StreamChatClient client;

  const MyApp({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return StreamChat(
          client: client,
          child: child!,
        );
      },

      home: OnboardingPage(client: client),
    );
  }
}