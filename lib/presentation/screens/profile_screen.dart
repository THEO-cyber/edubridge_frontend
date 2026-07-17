import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/cache/app_cache.dart';
import '../../core/secure_storage.dart';
import '../../services/notification_service.dart';
import '../blocs/profile_bloc.dart';
import '../blocs/wishlist_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import 'course_detail_screen.dart';
import 'downloads_screen.dart';
import '../blocs/enrollment_bloc.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

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
    if (mounted) {
      setState(() {
        _token = token;
        _tokenCheckComplete = true;
      });
      if (token != null && !_profileLoaded) {
        _profileLoaded = true;
        if (mounted) {
          context.read<ProfileBloc>().add(LoadProfileEvent(token));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: EnrollmentBlocProvider(
        child: !_tokenCheckComplete
            ? const Center(child: CircularProgressIndicator(color: _kNavy))
            : (_token == null || _token!.isEmpty)
                ? _buildNotLoggedIn(context)
                : _buildProfileContent(context),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Branded hero ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kNavy, _kBlue],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45), width: 2),
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to EduBridge',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track your progress, earn certificates, '
                  'and continue right where you left off.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Primary + secondary CTAs ──────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/user-login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Log In',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/user-register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kNavy,
                      side: const BorderSide(color: _kNavy, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Create Account',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'WHY JOIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 18),
                _benefit(Icons.play_circle_outline, 'Learn anywhere',
                    'Stream courses on any device, anytime'),
                _benefit(Icons.trending_up_rounded, 'Track your progress',
                    'Pick up lessons right where you left off'),
                _benefit(Icons.workspace_premium_outlined, 'Earn certificates',
                    'Showcase the courses you complete'),
                _benefit(Icons.favorite_border_rounded, 'Save favourites',
                    'Build a wishlist of courses to take'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _kBlue, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload so header + info tiles reflect the new values
          if (_token != null) {
            context.read<ProfileBloc>().add(LoadProfileEvent(_token!));
          }
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is ProfileLoaded && !_enrollmentsLoaded) {
          _enrollmentsLoaded = true;
          context.read<EnrollmentBloc>().add(FetchEnrollmentsEvent(_token!));
        }
      },
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _kNavy));
        }

        if (state is ProfileError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 72, color: _kNavy),
                  const SizedBox(height: 18),
                  const Text(
                    'Login to your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed('/user-login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Login',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;
          final name = _buildDisplayName(profile);
          final email = profile['email']?.toString() ??
              profile['username']?.toString() ??
              'user@email.com';
          final role = profile['role']?.toString() ??
              profile['roles']?.toString() ??
              'Student / Lecturer';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Profile',
                    onPressed: () =>
                        _showEditProfileSheet(context, profile, _token!),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kNavy, _kBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person,
                                  size: 48, color: _kNavy),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Account card
                    _SectionCard(
                      children: [
                        _InfoTile(
                          icon: Icons.person_outline,
                          title: 'Full Name',
                          subtitle: name,
                        ),
                        _InfoTile(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          subtitle: email,
                        ),
                        _InfoTile(
                          icon: Icons.verified_user_outlined,
                          title: 'Role',
                          subtitle: role,
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick Links
                    const Text(
                      'QUICK LINKS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SectionCard(
                      children: [
                        _NavTile(
                          icon: Icons.security_outlined,
                          label: '2FA Setup',
                          onTap: () =>
                              Navigator.pushNamed(context, '/2fa-setup'),
                        ),
                        _NavTile(
                          icon: Icons.email_outlined,
                          label: 'Email Preferences',
                          onTap: () => Navigator.pushNamed(
                              context, '/email-preferences'),
                        ),
                        _NavTile(
                          icon: Icons.note_alt_outlined,
                          label: 'My Notes',
                          onTap: () =>
                              Navigator.pushNamed(context, '/my-notes'),
                        ),
                        _NavTile(
                          icon: Icons.download_for_offline_outlined,
                          label: 'Downloads',
                          onTap: () =>
                              Navigator.push(context, DownloadsScreen.route()),
                        ),
                        _NavTile(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Enrolled Courses
                    const Text(
                      'ENROLLED COURSES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    BlocConsumer<EnrollmentBloc, EnrollmentState>(
                      listener: (context, state) {
                        if (state is EnrollmentFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to load enrollments: ${state.message}'),
                            ),
                          );
                        }
                      },
                      builder: (context, enrollState) {
                        if (!_enrollmentsLoaded ||
                            enrollState is EnrollmentLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: _kNavy),
                            ),
                          );
                        }
                        if (enrollState is EnrollmentsLoaded) {
                          final enrollments = enrollState.enrollments;
                          if (enrollments.isEmpty) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text('No enrolled courses yet.',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: enrollments.map((enrollment) {
                              final courseTitle =
                                  enrollment['courseTitle'] ??
                                      'Unknown Course';
                              final progress =
                                  (enrollment['progress'] ?? 0) as num;
                              final courseId = (enrollment['courseId'] ??
                                      enrollment['course']?['id'] ??
                                      '')
                                  .toString();
                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  onTap: courseId.isNotEmpty
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CourseDetailScreen(
                                                courseId: courseId,
                                                title: courseTitle,
                                                description: '',
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          courseTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  LinearProgressIndicator(
                                                value:
                                                    progress / 100,
                                                backgroundColor:
                                                    Colors.grey
                                                        .shade200,
                                                color: _kBlue,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(4),
                                                minHeight: 6,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${progress.toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _kBlue,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    const SizedBox(height: 24),
                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final profileBloc = context.read<ProfileBloc>();
                          final navigator = Navigator.of(context);
                          try {
                            context
                                .read<WishlistBloc>()
                                .add(ClearWishlistEvent());
                          } catch (_) {}
                          await NotificationService.unregisterToken();
                          await SecureStorage.deleteAllTokens();
                          await SecureStorage.clearRole();
                          AppCache.clear();
                          if (!mounted) return;
                          profileBloc.add(ResetProfileEvent());
                          setState(() {
                            _token = null;
                            _profileLoaded = false;
                            _enrollmentsLoaded = false;
                          });
                          navigator.pushReplacementNamed('/user-login');
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        }

        // Fallback / ProfileUpdateSuccess
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 18),
                const Text(
                  'Unable to display profile at the moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_token != null) {
                      context
                          .read<ProfileBloc>()
                          .add(LoadProfileEvent(_token!));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    Map<String, dynamic> profile,
    String token,
  ) async {
    final nameCtrl = TextEditingController(text: _buildDisplayName(profile));
    final emailCtrl =
        TextEditingController(text: profile['email']?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Edit Profile',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final nameTrimmed = nameCtrl.text.trim();
                  final emailTrimmed = emailCtrl.text.trim();
                  if (nameTrimmed.isEmpty || emailTrimmed.isEmpty) return;
                  final parts = nameTrimmed.split(' ');
                  Navigator.pop(sheetCtx);
                  context.read<ProfileBloc>().add(UpdateProfileEvent(
                    {
                      'name': nameTrimmed,
                      'firstName': parts.first,
                      'lastName':
                          parts.length > 1 ? parts.sublist(1).join(' ') : '',
                      'email': emailTrimmed,
                    },
                    token,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  String _buildDisplayName(Map<String, dynamic> profile) {
    final name = profile['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final firstName = profile['firstName']?.toString().trim();
    final lastName = profile['lastName']?.toString().trim();
    if (firstName != null && firstName.isNotEmpty) {
      return lastName != null && lastName.isNotEmpty
          ? '$firstName $lastName'
          : firstName;
    }
    if (lastName != null && lastName.isNotEmpty) return lastName;

    final username = profile['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;

    return 'User Name';
  }
}

// --- Reusable widgets ---

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: _kNavy),
          title: Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 56),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: _kNavy, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 52),
      ],
    );
  }
}
