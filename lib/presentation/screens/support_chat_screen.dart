import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Future<List<Map<String, dynamic>>> _chatFuture;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatFuture = _fetchChatMessages();
  }

  Future<List<Map<String, dynamic>>> _fetchChatMessages() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Not logged in');

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.chatRooms),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rooms = data is List ? data : (data['chatRooms'] ?? []);

        if (rooms.isEmpty) return [];

        // Fetch messages from first room or support room
        final roomId = rooms[0]['id'] ?? '';
        final msgResponse = await http.get(
          Uri.parse(
            ApiConstants.baseUrl +
                '${ApiConstants.chatRoomMessages}$roomId/messages',
          ),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (msgResponse.statusCode == 200) {
          final msgData = jsonDecode(msgResponse.body);
          final messages = msgData is List
              ? msgData
              : (msgData['messages'] ?? []);
          return List<Map<String, dynamic>>.from(messages);
        }
        return [];
      }
      throw Exception('Failed to load chat');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    setState(() {
      _isLoading = true;
      _messages.add({
        'text': messageText,
        'sender': 'user',
        'timestamp': DateTime.now().toString(),
      });
    });

    _scrollToBottom();

    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Not logged in');

      // Get or create support chat room
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.createChatRoom),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': 'Support Chat'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final roomData = jsonDecode(response.body);
        final roomId = roomData['id'] ?? '';

        // Send message to room
        final msgResponse = await http.post(
          Uri.parse(
            ApiConstants.baseUrl +
                '${ApiConstants.chatRoomMessages}$roomId/messages',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'message': messageText}),
        );

        if (msgResponse.statusCode != 200 && msgResponse.statusCode != 201) {
          throw Exception('Failed to send message');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chat'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chatFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          // Initialize messages if empty
          if (_messages.isEmpty && snapshot.data != null) {
            _messages = snapshot.data!;
          }

          return Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Colors.blueGrey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text('Start a conversation with support'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser =
                              msg['sender'] == 'user' || msg['sender'] == null;
                          final timestamp = msg['timestamp'] ?? '';

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.blue[600]
                                    : Colors.blueGrey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: isUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['text'] ?? msg['message'] ?? '',
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.blue[100]
                                          : Colors.blueGrey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onSubmitted: (value) {
                          if (!_isLoading) {
                            _sendMessage();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: 'support_chat_send_button',
                      mini: true,
                      backgroundColor: Colors.blue[600],
                      onPressed: _isLoading ? null : _sendMessage,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
