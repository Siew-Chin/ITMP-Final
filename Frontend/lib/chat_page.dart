//34
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final StreamChatClient client;
  final String currentUserId;
  final String otherUserId;

  const ChatPage({
    super.key, 
    required this.client,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  //Stream client
  late final StreamChatClient client;
  //Chat channel(User & Runner in same chat)
  Channel? channel;
  //Loading
  bool isLoading = true;
  //Error message
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print("!!! DEBUG: ChatPage Started !!!");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      client = StreamChat.of(context).client;
      setupChat();
    });
  }


  Future<void> setupChat() async {
    print("!!! DEBUG: Starting setupChat !!!");
    try {
      final chatClient = StreamChat.of(context).client;

      if (chatClient.state.currentUser != null && chatClient.state.currentUser!.id != widget.currentUserId) {
        print("STEP 3: Disconnecting wrong user");
        await chatClient.disconnectUser();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (chatClient.state.currentUser == null) {
        print(" Step 5: Getting token and sync data from backend");
        final response = await http.get(
          Uri.parse("https://animation-phoenix-crevice.ngrok-free.dev/api/get_token/${widget.currentUserId}"),//API 8: Generate Stream Chat Token
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true', 
          },
        );

        if (response.statusCode != 200) throw Exception("Token API failed");

        final data = jsonDecode(response.body);
        final token = data['token'];

        print("STEP 7: Connecting user without extra data");

        await chatClient.connectUser(
          User(id: widget.currentUserId),
          token,
        );
        
        print("STEP 8: Connected successfully");
      }

      final ids = [widget.currentUserId, widget.otherUserId]..sort();
      final safeIds = ids.map((e) => e.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')).toList();
      final channelId = "chat_${safeIds[0]}_${safeIds[1]}";

      print("STEP 10: Initializing channel: $channelId");

      final localChannel = chatClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'members': [widget.currentUserId, widget.otherUserId],
        },
      );

      print("STEP 11: Watching channel");
      await localChannel.watch();

      if (mounted) {
        setState(() {
          channel = localChannel;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ ERROR in setupChat: $e");
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "❌ Error:\n$errorMessage",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
    }

    return StreamChannel(
      channel: channel!,
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF3FF),

        appBar: AppBar(
          title: const StreamChannelHeader(),
        ),

        body: const Column(
          children: [
            Expanded(
              child: StreamMessageListView(),
            ),
            StreamMessageInput(),
          ],
        ),
      ),
    );
  }
}