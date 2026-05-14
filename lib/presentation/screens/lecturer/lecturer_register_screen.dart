import 'package:edubridge/presentation/blocs/auth_bloc.dart';
import 'package:edubridge/presentation/widgets/auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LecturerRegisterScreen extends StatefulWidget {
  const LecturerRegisterScreen({Key? key}) : super(key: key);

  @override
  State<LecturerRegisterScreen> createState() => _LecturerRegisterScreenState();
}

class _LecturerRegisterScreenState extends State<LecturerRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final horizontalPadding = isSmall ? 18.0 : 32.0;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is AuthSuccess) {
            final normalizedRole = state.user.role.toLowerCase();
            if (normalizedRole == 'lecturer' ||
                normalizedRole == 'teacher' ||
                normalizedRole == 'instructor') {
              Navigator.pushReplacementNamed(context, '/lecturer-dashboard');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Registration succeeded, but account is not lecturer.',
                  ),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    AuthForm(
                      isLogin: false,
                      onSubmit:
                          (
                            email,
                            password,
                            username,
                            firstName,
                            lastName,
                            role,
                          ) {
                            context.read<AuthBloc>().add(
                              RegisterEvent(
                                email,
                                password,
                                'INSTRUCTOR',
                                username,
                                firstName,
                                lastName,
                              ),
                            );
                          },
                    ),
                    if (state is AuthLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
