import '../../core/error_handling.dart';

abstract class ChatRepository {
  Future<List<Map<String, dynamic>>> fetchChatRooms(String token);
  Future<List<Map<String, dynamic>>> fetchMessages(String roomId, String token);
  Future<void> sendMessage(String roomId, String message, String token);
  Future<Map<String, dynamic>> createChatRoom(String title, String token);
}
