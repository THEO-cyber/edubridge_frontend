import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/live_session_bloc.dart';

class LiveSessionListScreen extends StatelessWidget {
  const LiveSessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Sessions')),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data!;
          return BlocBuilder<LiveSessionBloc, LiveSessionState>(
            builder: (context, state) {
              if (state is LiveSessionInitial) {
                context.read<LiveSessionBloc>().add(
                  FetchAvailableLiveSessionsEvent(token),
                );
                return const Center(child: CircularProgressIndicator());
              } else if (state is LiveSessionLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is LiveSessionLoaded) {
                return ListView.builder(
                  itemCount: state.sessions.length,
                  itemBuilder: (context, index) {
                    final session = state.sessions[index];
                    return ListTile(
                      title: Text(session.title),
                      subtitle: Text(
                        'Scheduled: ' + session.scheduledAt.toString(),
                      ),
                      trailing: const Icon(Icons.video_call),
                      onTap: () {
                        // TODO: Join live session
                      },
                    );
                  },
                );
              } else if (state is LiveSessionError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
