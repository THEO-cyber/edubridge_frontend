import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/chat_bloc.dart';

/// Real-time instructor chat using ChatBloc (REST + socket.io backend).
class ChatScreen extends StatefulWidget {
  final String instructorId;
  final String instructorName;
  final String token;

  const ChatScreen({
    super.key,
    required this.instructorId,
    required this.instructorName,
    required this.token,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _roomId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadOrCreateRoom();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<String> get _token async => widget.token.isNotEmpty
      ? widget.token
      : (await SecureStorage.getToken() ?? '');

  Future<void> _loadOrCreateRoom() async {
    final tok = await _token;
    if (tok.isEmpty || !mounted) return;
    context.read<ChatBloc>().add(LoadChatRoomsEvent(tok));
  }

  void _openRoom(String roomId, String tok) {
    setState(() => _roomId = roomId);
    context.read<ChatBloc>().add(LoadMessagesEvent(roomId, tok));
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _roomId == null) return;
    final tok = await _token;
    if (tok.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    context.read<ChatBloc>().add(SendMessageEvent(_roomId!, text, tok));
    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _createRoom() async {
    final tok = await _token;
    if (tok.isEmpty || !mounted) return;
    context.read<ChatBloc>().add(
          CreateChatRoomEvent('Chat with ${widget.instructorName}', tok),
        );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
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
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text(
                widget.instructorName.isNotEmpty
                    ? widget.instructorName[0].toUpperCase()
                    : 'I',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.instructorName,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                  const Text('Instructor',
                      style:
                          TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) async {
          if (state is ChatRoomsLoaded) {
            final tok = await _token;
            if (state.rooms.isEmpty) {
              await _createRoom();
            } else {
              final roomId =
                  (state.rooms.first['id'] ?? '').toString();
              if (roomId.isNotEmpty) _openRoom(roomId, tok);
            }
          } else if (state is ChatRoomCreated) {
            final tok = await _token;
            final roomId = (state.room['id'] ?? '').toString();
            if (roomId.isNotEmpty) _openRoom(roomId, tok);
          } else if (state is MessagesLoaded) {
            _scrollToBottom();
          } else if (state is ChatError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is ChatLoading || state is ChatInitial) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1A237E)));
          }
          if (state is MessagesLoaded) {
            return _buildChatView(state.messages);
          }
          if (state is ChatError && _roomId == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _loadOrCreateRoom,
                      child: const Text('Retry')),
                ],
              ),
            );
          }
          return _buildChatView(const []);
        },
      ),
    );
  }

  Widget _buildChatView(List<Map<String, dynamic>> messages) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 56, color: Colors.blueGrey.shade300),
                      const SizedBox(height: 12),
                      const Text('No messages yet'),
                      const SizedBox(height: 4),
                      Text(
                        'Send a message to start the conversation',
                        style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) =>
                      _MessageBubble(msg: messages[i]),
                ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              heroTag: 'chat_enhanced_send_btn',
              mini: true,
              backgroundColor: const Color(0xFF1A237E),
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final senderRole =
        (msg['sender'] ?? msg['senderRole'] ?? 'user').toString();
    final isMine = senderRole == 'user' ||
        senderRole == 'student' ||
        msg['isMine'] == true ||
        msg['isCurrentUser'] == true;
    final text = (msg['text'] ?? msg['message'] ?? msg['content'] ?? '')
        .toString();
    final timestamp =
        _fmt((msg['timestamp'] ?? msg['createdAt'] ?? '').toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blueGrey.shade200,
              child: const Icon(Icons.person,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width * 0.68),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF1A237E)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(text,
                      style: TextStyle(
                          color: isMine ? Colors.white : Colors.black87,
                          fontSize: 14,
                          height: 1.3)),
                  if (timestamp.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(timestamp,
                        style: TextStyle(
                            fontSize: 10,
                            color: isMine
                                ? Colors.white60
                                : Colors.grey)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
