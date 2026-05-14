import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//Chat page
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
    // 确保 client 已经初始化
    final chatClient = StreamChat.of(context).client;

    // 1. 如果当前登录的人不对，先断开（防串号）
    if (chatClient.state.currentUser != null &&
        chatClient.state.currentUser!.id != widget.currentUserId) {
      print("STEP 3: Disconnecting wrong user");
      await chatClient.disconnectUser();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 2. 连接用户
    if (chatClient.state.currentUser == null) {
      print("STEP 5: Getting token from backend");
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/get_token/${widget.currentUserId}"),
      );

      if (response.statusCode != 200) throw Exception("Token API failed");

      final token = jsonDecode(response.body)['token'];
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

    // 4. 创建并进入频道
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