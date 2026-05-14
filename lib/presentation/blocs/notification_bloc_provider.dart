import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_bloc.dart';

class NotificationBlocProvider extends StatelessWidget {
  final Widget child;

  const NotificationBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) => NotificationBloc(), child: child);
  }
}
