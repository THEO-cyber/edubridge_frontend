import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/profile_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final horizontalPadding = isSmall ? 18.0 : 32.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data;
          if (token == null || token.isEmpty) {
            // Not logged in
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: isSmall ? 60 : 80,
                      color: Colors.blueGrey[300],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'You are not logged in.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/user-login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // Logged in: show profile
          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileUpdateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
              } else if (state is ProfileError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is ProfileInitial) {
                context.read<ProfileBloc>().add(LoadProfileEvent(token));
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProfileLoaded) {
                final profile = state.profile;
                final name = profile['name'] ?? 'User Name';
                final email = profile['email'] ?? 'user@email.com';
                final role = profile['role'] ?? 'Student / Lecturer';
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: isSmall ? 44 : 60,
                            backgroundColor: Colors.blueGrey[100],
                            child: Icon(
                              Icons.person,
                              size: isSmall ? 44 : 60,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 22 : 28,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.blueGrey[400],
                              fontSize: isSmall ? 13 : 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[800],
                                      fontSize: isSmall ? 16 : 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: Icon(
                                      Icons.person_outline,
                                      color: Colors.blueGrey[700],
                                    ),
                                    title: const Text('Full Name'),
                                    subtitle: Text(name),
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.email_outlined,
                                      color: Colors.blueGrey[700],
                                    ),
                                    title: const Text('Email'),
                                    subtitle: Text(email),
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.verified_user,
                                      color: Colors.blueGrey[700],
                                    ),
                                    title: const Text('Role'),
                                    subtitle: Text(role),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text(
                                'Logout',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                await SecureStorage.deleteToken();
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (state is ProfileError) {
                return Center(child: Text(state.message));
              }
              context.read<ProfileBloc>().add(LoadProfileEvent(token));
              return const Center(child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }
}
