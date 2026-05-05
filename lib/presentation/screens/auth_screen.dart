import 'package:edubridge/presentation/widgets/role_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../widgets/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  void _submit(String email, String password, String username, String firstname, String lastname, String? role) {
    final bloc = context.read<AuthBloc>();
    if (isLogin) {
      bloc.add(LoginEvent(email, password));
    } else {
      bloc.add(RegisterEvent(email, password, username, firstname, lastname, role ?? 'student'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Register'),
        actions: [
          TextButton(
            onPressed: () => setState(() => isLogin = !isLogin),
            child: Text(
              isLogin ? 'Register' : 'Login',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is AuthSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RoleRouter(role: state.user.role),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AuthForm(isLogin: isLogin, onSubmit: _submit),
            ),
          );
        },
      ),
    );
  }
}
