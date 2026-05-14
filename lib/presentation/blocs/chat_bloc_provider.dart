import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_bloc.dart';

class ChatBlocProvider extends StatelessWidget {
  final Widget child;
  const ChatBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final chatRemoteDataSource = ChatRemoteDataSource();
    return BlocProvider(
      create: (_) => ChatBloc(
        fetchChatRoomsUseCase: FetchChatRoomsUseCase(
          ChatRepositoryImpl(chatRemoteDataSource),
        ),
        fetchMessagesUseCase: FetchMessagesUseCase(
          ChatRepositoryImpl(chatRemoteDataSource),
        ),
        sendMessageUseCase: SendMessageUseCase(
          ChatRepositoryImpl(chatRemoteDataSource),
        ),
        createChatRoomUseCase: CreateChatRoomUseCase(
          ChatRepositoryImpl(chatRemoteDataSource),
        ),
      ),
      child: child,
    );
  }
}
