import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String instructorId;
  final String instructorName;
  final String token;

  const ChatScreen({
    Key? key,
    required this.instructorId,
    required this.instructorName,
    required this.token,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [
    {
      'text': 'Hi, I have a question about Lesson 2',
      'isSent': true,
      'time': '10:30 AM',
    },
    {
      'text': 'Sure! What would you like to know?',
      'isSent': false,
      'time': '10:31 AM',
    },
    {
      'text': 'How do I implement state management in Flutter?',
      'isSent': true,
      'time': '10:32 AM',
    },
    {
      'text':
          'There are several ways: BLoC, Provider, Riverpod, GetX, etc. BLoC is the most popular...',
      'isSent': false,
      'time': '10:33 AM',
    },
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.instructorName),
            Text(
              'Online',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isSent = message['isSent'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSent ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message['text'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSent ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message['time'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSent ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: 'chat_screen_send_button',
            mini: true,
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (messageController.text.isEmpty) return;

    setState(() {
      messages.add({
        'text': messageController.text,
        'isSent': true,
        'time': _getCurrentTime(),
      });
      messageController.clear();
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}
