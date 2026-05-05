import 'package:edubridge/constants/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class ChatRemoteDataSource {
  IO.Socket? _socket;

  void connect(String token) {
    _socket = IO.io(
      ApiConstants.baseUrl.replaceFirst('/api/v1', ''),
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'extraHeaders': {'Authorization': 'Bearer $token'},
      },
    );
    _socket?.connect();
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_chat_room', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_chat_room', {'roomId': roomId});
  }

  void sendMessage(String roomId, String message) {
    _socket?.emit('send_message', {'roomId': roomId, 'message': message});
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
