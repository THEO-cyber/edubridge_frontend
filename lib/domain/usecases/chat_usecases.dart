import '../repositories/chat_repository.dart';

class FetchChatRoomsUseCase {
  final ChatRepository repository;
  FetchChatRoomsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String token) {
    return repository.fetchChatRooms(token);
  }
}

class FetchMessagesUseCase {
  final ChatRepository repository;
  FetchMessagesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String roomId, String token) {
    return repository.fetchMessages(roomId, token);
  }
}

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<void> call(String roomId, String message, String token) {
    return repository.sendMessage(roomId, message, token);
  }
}

class CreateChatRoomUseCase {
  final ChatRepository repository;
  CreateChatRoomUseCase(this.repository);

  Future<Map<String, dynamic>> call(String title, String token) {
    return repository.createChatRoom(title, token);
  }
}
