import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/profile_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import '../blocs/enrollment_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _token;
  bool _profileLoaded = false;
  bool _enrollmentsLoaded = false;
  bool _tokenCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = await SecureStorage.getToken();
    print(
      '[DEBUG PROFILE SCREEN] Token retrieved: ${token != null ? 'YES' : 'NO'}',
    );
    if (mounted) {
      setState(() {
        _token = token;
        _tokenCheckComplete = true;
      });
      if (token != null && !_profileLoaded) {
        _profileLoaded = true;
        print('[DEBUG PROFILE SCREEN] Loading profile with token');
        if (mounted) {
          context.read<ProfileBloc>().add(LoadProfileEvent(token));
        }
      } else if (token == null) {
        print('[DEBUG PROFILE SCREEN] No token found, user not logged in');
      }
    }
  }

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
      body: EnrollmentBlocProvider(
        child: !_tokenCheckComplete
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              )
            : (_token == null || _token!.isEmpty)
            ? _buildNotLoggedIn(context, isSmall, horizontalPadding)
            : _buildProfileContent(context, isSmall, horizontalPadding),
      ),
    );
  }

  Widget _buildNotLoggedIn(
    BuildContext context,
    bool isSmall,
    double horizontalPadding,
  ) {
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    bool isSmall,
    double horizontalPadding,
  ) {
    // Logged in: show profile
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is ProfileLoaded && !_enrollmentsLoaded) {
          _enrollmentsLoaded = true;
          print(
            '[DEBUG PROFILE SCREEN] Loading enrollments after profile loaded',
          );
          context.read<EnrollmentBloc>().add(FetchEnrollmentsEvent(_token!));
        }
      },
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileLoaded) {
          final profile = state.profile;
          final name = _buildDisplayName(profile);
          final email =
              profile['email']?.toString() ??
              profile['username']?.toString() ??
              'user@email.com';
          final role =
              profile['role']?.toString() ??
              profile['roles']?.toString() ??
              'Student / Lecturer';
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          print('[DEBUG PROFILE SCREEN] Logout button tapped');
                          await SecureStorage.deleteAllTokens();
                          print('[DEBUG PROFILE SCREEN] Tokens deleted');
                          // Reset profile bloc state
                          if (mounted) {
                            context.read<ProfileBloc>().add(
                              ResetProfileEvent(),
                            );
                          }
                          if (mounted) {
                            setState(() {
                              _token = null;
                              _profileLoaded = false;
                              _enrollmentsLoaded = false;
                            });
                            print(
                              '[DEBUG PROFILE SCREEN] State reset, navigating to login',
                            );
                            // Navigate to login screen
                            if (mounted) {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/user-login');
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Enrolled Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                        fontSize: isSmall ? 16 : 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocConsumer<EnrollmentBloc, EnrollmentState>(
                      listener: (context, state) {
                        if (state is EnrollmentFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to load enrollments: ${state.message}',
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (!_enrollmentsLoaded || state is EnrollmentLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is EnrollmentsLoaded) {
                          final enrollments = state.enrollments;
                          if (enrollments.isEmpty) {
                            return const Text('No enrolled courses yet.');
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: enrollments.length,
                            itemBuilder: (context, index) {
                              final enrollment = enrollments[index];
                              final courseTitle =
                                  enrollment['courseTitle'] ?? 'Unknown Course';
                              final progress = enrollment['progress'] ?? 0;
                              return Card(
                                child: ListTile(
                                  title: Text(courseTitle),
                                  subtitle: Text('Progress: $progress%'),
                                  onTap: () {
                                    // Navigate to course detail if needed
                                  },
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is ProfileError) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: isSmall ? 64 : 80,
                      color: Colors.blueGrey[400],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Login to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 18,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/user-login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[800],
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
            ),
          );
        }
        if (state is ProfileUpdateSuccess) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: isSmall ? 64 : 80,
                    color: Colors.blueGrey[400],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Unable to display profile at the moment. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ProfileBloc>().add(
                          LoadProfileEvent(_token!),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Retry',
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
          ),
        );
      },
    );
  }

  String _buildDisplayName(Map<String, dynamic> profile) {
    final name = profile['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final firstName = profile['firstName']?.toString().trim();
    final lastName = profile['lastName']?.toString().trim();
    if (firstName != null &&
        firstName.isNotEmpty &&
        lastName != null &&
        lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (firstName != null && firstName.isNotEmpty) {
      return firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      return lastName;
    }

    final username = profile['username']?.toString().trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }

    return 'User Name';
  }
}
