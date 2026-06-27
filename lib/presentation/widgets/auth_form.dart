import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final void Function(String email, String password, String username, String firstName, String lastName, String? role) onSubmit;
  const AuthForm({super.key, required this.isLogin, required this.onSubmit});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _role = 'student';
  String _fullName = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isLogin) ...[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) => value != null && value.trim().split(' ').length >= 2
                  ? null
                  : 'Enter your full name',
              onSaved: (value) => _fullName = value?.trim() ?? '',
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Enter a valid email',
            onSaved: (value) => _email = value ?? '',
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) => value != null && value.length >= 6
                ? null
                : 'Password too short',
            onSaved: (value) => _password = value ?? '',
          ),
          if (!widget.isLogin) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'student'),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState?.save();
                if (widget.isLogin) {
                  widget.onSubmit(_email, _password, '', '', '', null);
                } else {
                  final parts = _fullName.split(' ');
                  final firstName = parts.isNotEmpty ? parts.first : _fullName;
                  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                  final username = _fullName;
                  widget.onSubmit(
                    _email,
                    _password,
                    username,
                    firstName,
                    lastName,
                    _role,
                  );
                }
              }
            },
            child: Text(widget.isLogin ? 'Login' : 'Register'),
          ),
        ],
      ),
    );
  }
}
