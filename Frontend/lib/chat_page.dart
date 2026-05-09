import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//Chat page
class ChatPage extends StatefulWidget {
  final String studentID;
  final String? runnerID;

  const ChatPage({
    super.key, 
    required this.studentID,
    this.runnerID,
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
    client = StreamChatClient('659pk8bnxecv', logLevel: Level.INFO);
    setupChat();
  }


  Future<void> setupChat() async {
    if (widget.runnerID == null) {
      setState(() {
        errorMessage = "runnerID is null";
        isLoading = false;
      });
      return;
    }
  try {
    // 1. 检查是否已经连了别的人，有则断开
    if (client.state.currentUser != null && client.state.currentUser!.id != widget.studentID) {
      await client.disconnectUser();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 2. 获取 Token 并登录当前用户 (ABC)
    if (client.state.currentUser == null) {
      final response = await http.get(Uri.parse("http://10.0.2.2:5000/get_token/${widget.studentID}"));
      if (response.statusCode != 200) {
          throw Exception("Token API failed");
        }
        
      final token = jsonDecode(response.body)['token'];
      
      if (token == null) {
          throw Exception("Token is null");
      }

      await client.connectUser(
        User(id: widget.studentID, name: 'User ${widget.studentID}'),
        token,
      );
    }

    // 3. 更新对方信息 (注意：这里最好也加上 null 检查)

    if (widget.runnerID != null) {
      await client.updateUsers([
        User(id: widget.runnerID!, name: 'Runner ${widget.runnerID}'),
      ]);
    }

    // 4. 创建并观察频道
    final ids = [widget.studentID, widget.runnerID!]..sort();
    final channelId = "chat_${ids[0]}_${ids[1]}";
    final localChannel = client.channel(
      'messaging',
      id: channelId,
      extraData: {
        'members': [widget.studentID, widget.runnerID!],
      },
    );

    await localChannel.watch();

    // 5. 更新 UI 状态
    if (mounted) {
        setState(() {
          channel = localChannel;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Chat Setup Error: $e");
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
    //Loading 
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    //Error UI
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

  //Normal Chat UI
  return StreamChat(
  client: client,
  child: StreamChannel(
    channel: channel!,
    child: const Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: const StreamChannelHeader(),
      body: Column(
        children: [
          const Expanded(
            child: StreamMessageListView(),
          ),
          const StreamMessageInput(),
        ],
      ),
    ),
  ),
  );
  }   
}