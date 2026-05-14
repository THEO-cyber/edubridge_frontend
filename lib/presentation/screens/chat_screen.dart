import 'package:flutter/material.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../core/secure_storage.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRemoteDataSource _chat = ChatRemoteDataSource();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    SecureStorage.getToken().then((token) {
      print('[DEBUG CHAT] Token retrieved: ${token != null ? 'YES' : 'NO'}');
      if (token != null) {
        print('[DEBUG CHAT] Setting token and connecting...');
        setState(() => _token = token);
        _chat.connect(token);
        _chat.joinRoom(widget.roomId);
        print('[DEBUG CHAT] Joined room: ${widget.roomId}');
        _chat.onMessage((data) {
          print('[DEBUG CHAT] Message received: $data');
          setState(() {
            _messages.add(data);
          });
        });
      } else {
        print('[DEBUG CHAT] ERROR: No token available');
      }
    });
  }

  @override
  void dispose() {
    _chat.leaveRoom(widget.roomId);
    _chat.disconnect();
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty || _token == null) {
      print(
        '[DEBUG CHAT] Cannot send: empty=${_controller.text.trim().isEmpty}, token=${_token == null}',
      );
      return;
    }
    final message = _controller.text.trim();
    print('[DEBUG CHAT] Sending message: $message to room: ${widget.roomId}');
    _chat.sendMessage(widget.roomId, message, _token!);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg['message'] ?? ''),
                  subtitle: Text(msg['sender'] ?? ''),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
