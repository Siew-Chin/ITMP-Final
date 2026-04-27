import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

//Chat page
class ChatPage extends StatefulWidget {
  final String studentID;
  const ChatPage({super.key, required this.studentID});

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
    setupChat();
  }

  Future<void> setupChat() async {
    try {
      client = StreamChatClient(
        'b67pax5b2wdq',
        logLevel: Level.INFO,
      );
      print("👤 Connecting user: ${widget.studentID}");
      //Connect user
      await client.connectUser(
        User(id: '${widget.studentID}'),
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidHV0b3JpYWwtZmx1dHRlciJ9.S-MJpoSwDiqyXpUURgO5wVqJ4vKlIVFLSEyrFYCOE1c',
      );
      final newChannel = client.channel(
        'messaging',
        id: 'order_channel_tutorial',
      );

      await newChannel.watch();

      //Update UI
      if (!mounted) return;
      setState(() {
        channel = newChannel;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    //Cut down connection when leave the page 
    client.disconnectUser();
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
    child: Scaffold(
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