import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatRemoteDataSource {
  io.Socket? _socket;

  void connect(String token) {
    final wsUrl = ApiConstants.baseUrl.replaceFirst('/api/v1', '');
    _socket = io.io(wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });
    _socket?.connect();
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_chat_room', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_chat_room', {'roomId': roomId});
  }

  Future<void> sendMessage(String roomId, String message, String token) async {
    final url = ApiConstants.baseUrl + ApiConstants.chatMessages(roomId);
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception('Failed to send chat message');
  }

  Future<List<Map<String, dynamic>>> fetchChatRooms(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.chatRooms),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rooms = data is List ? data : (data['rooms'] ?? []);
      return List<Map<String, dynamic>>.from(rooms);
    }
    throw Exception('Failed to fetch chat rooms');
  }

  Future<Map<String, dynamic>> createChatRoom(
    Map<String, dynamic> roomData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.createChatRoom),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(roomData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create chat room');
  }

  Future<List<Map<String, dynamic>>> fetchMessages(
    String roomId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.chatMessages(roomId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data is List ? data : (data['messages'] ?? []);
      return List<Map<String, dynamic>>.from(messages);
    }
    throw Exception('Failed to fetch chat messages');
  }

  Future<Map<String, dynamic>> sendMessageRest(
    String roomId,
    Map<String, dynamic> messageData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.chatMessages(roomId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(messageData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to send chat message');
  }

  void onMessage(void Function(dynamic) handler) {
    _socket?.on('message', handler);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }
}
