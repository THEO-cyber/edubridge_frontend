import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/chat_usecases.dart';

abstract class ChatEvent {}

class LoadChatRoomsEvent extends ChatEvent {
  final String token;
  LoadChatRoomsEvent(this.token);
}

class LoadMessagesEvent extends ChatEvent {
  final String roomId;
  final String token;
  LoadMessagesEvent(this.roomId, this.token);
}

class SendMessageEvent extends ChatEvent {
  final String roomId;
  final String message;
  final String token;
  SendMessageEvent(this.roomId, this.message, this.token);
}

class CreateChatRoomEvent extends ChatEvent {
  final String title;
  final String token;
  CreateChatRoomEvent(this.title, this.token);
}

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomsLoaded extends ChatState {
  final List<Map<String, dynamic>> rooms;
  ChatRoomsLoaded(this.rooms);
}

class MessagesLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;
  MessagesLoaded(this.messages);
}

class MessageSent extends ChatState {}

class ChatRoomCreated extends ChatState {
  final Map<String, dynamic> room;
  ChatRoomCreated(this.room);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FetchChatRoomsUseCase fetchChatRoomsUseCase;
  final FetchMessagesUseCase fetchMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final CreateChatRoomUseCase createChatRoomUseCase;

  ChatBloc({
    required this.fetchChatRoomsUseCase,
    required this.fetchMessagesUseCase,
    required this.sendMessageUseCase,
    required this.createChatRoomUseCase,
  }) : super(ChatInitial()) {
    on<LoadChatRoomsEvent>((event, emit) async {
      emit(ChatLoading());
      try {
        final rooms = await fetchChatRoomsUseCase(event.token);
        emit(ChatRoomsLoaded(rooms));
      } catch (e) {
        emit(ChatError('Failed to load chat rooms: $e'));
      }
    });

    on<LoadMessagesEvent>((event, emit) async {
      emit(ChatLoading());
      try {
        final messages = await fetchMessagesUseCase(event.roomId, event.token);
        emit(MessagesLoaded(messages));
      } catch (e) {
        emit(ChatError('Failed to load messages: $e'));
      }
    });

    on<SendMessageEvent>((event, emit) async {
      try {
        await sendMessageUseCase(event.roomId, event.message, event.token);
        emit(MessageSent());
        // Reload messages
        add(LoadMessagesEvent(event.roomId, event.token));
      } catch (e) {
        emit(ChatError('Failed to send message: $e'));
      }
    });

    on<CreateChatRoomEvent>((event, emit) async {
      emit(ChatLoading());
      try {
        final room = await createChatRoomUseCase(event.title, event.token);
        emit(ChatRoomCreated(room));
        // Reload rooms
        add(LoadChatRoomsEvent(event.token));
      } catch (e) {
        emit(ChatError('Failed to create chat room: $e'));
      }
    });
  }
}
