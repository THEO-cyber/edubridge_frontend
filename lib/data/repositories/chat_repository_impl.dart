import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> fetchChatRooms(String token) async {
    return await remoteDataSource.fetchChatRooms(token);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String roomId, String token) async {
    return await remoteDataSource.fetchMessages(roomId, token);
  }

  @override
  Future<void> sendMessage(String roomId, String message, String token) async {
    await remoteDataSource.sendMessage(roomId, message, token);
  }

  @override
  Future<Map<String, dynamic>> createChatRoom(String title, String token) async {
    return await remoteDataSource.createChatRoom(
      {'title': title},
      token,
    );
  }
}