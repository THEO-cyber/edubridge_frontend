import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/category_store.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/course_remote_data_source.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/repositories/course_mapper.dart';
import '../../domain/entities/course_entity.dart';
import '../blocs/enrollment_bloc_provider.dart';
import 'course_detail_screen.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _courseDs = CourseRemoteDataSource();

  int _unreadNotifCount = 0;
  List<String> _categories = [];
  // Distinguishes "still loading" from "there are genuinely none", so the
  // section can be hidden instead of spinning forever.
  bool _categoriesLoaded = false;
  String? _selectedCategory;
  List<CourseEntity> _categoryResults = [];
  bool _categoryLoading = false;

  // No hard-coded category list on purpose: categories are owned by the
  // super-admin, and inventing names here would send learners to categories
  // that do not exist. CategoryStore falls back to the last real response.

  @override
  void initState() {
    super.initState();
    _loadNotifCount();
    _loadCategories();
  }

  Future<void> _loadNotifCount() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return;
      final r = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.notifications),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final list = data is List
            ? data
            : (data['notifications'] ?? data['data'] ?? []);
        final unread =
            (list as List).where((n) => n['read'] == false || n['isRead'] == false).length;
        if (mounted) setState(() => _unreadNotifCount = unread);
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    // The super-admin's list, or the last one we saw if we are offline.
    final cats = await CategoryStore.load();
    if (mounted && cats.isNotEmpty) {
      setState(() {
        _categories = cats.map((c) => c.name).toList();
        _categoriesLoaded = true;
      });
      return;
    }

    // Never fetched before and no connection: derive from whatever courses we
    // can reach, so the section still reflects the real catalogue.
    try {
      final courses = await _courseDs.fetchCourses();
      final derived = courses
          .map((c) => safeStr(c['category']))
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (mounted && derived.isNotEmpty) {
        setState(() {
          _categories = derived;
          _categoriesLoaded = true;
        });
        return;
      }
    } catch (_) {}

    // Nothing real to show — leave it empty and let the UI hide the section.
    if (mounted) {
      setState(() {
        _categories = [];
        _categoriesLoaded = true;
      });
    }
  }

  Future<void> _selectCategory(String category) async {
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = null;
        _categoryResults = [];
      });
      return;
    }
    setState(() {
      _selectedCategory = category;
      _categoryLoading = true;
      _categoryResults = [];
    });
    try {
      final raw = await _courseDs.fetchCoursesByCategory(category);
      if (mounted) {
        setState(() {
          _categoryResults = raw.map(courseFromMap).toList();
          _categoryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kNavy, _kBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Welcome to eduBridge',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/notifications');
                      setState(() => _unreadNotifCount = 0);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_rounded,
                              color: Colors.white, size: 24),
                        ),
                        if (_unreadNotifCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              child: Text(
                                _unreadNotifCount > 99
                                    ? '99+'
                                    : '$_unreadNotifCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Learn anything, anytime, anywhere.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/search'),
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for courses, topics, or instructors',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Body ───────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Popular Categories — hidden entirely when the super-admin
                  // has none, rather than spinning forever or inventing names.
                  if (!_categoriesLoaded || _categories.isNotEmpty) ...[
                  _sectionTitle('Popular Categories'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: _categories.isEmpty
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _kNavy),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, i) {
                              final cat = _categories[i];
                              final selected = _selectedCategory == cat;
                              return GestureDetector(
                                onTap: () => _selectCategory(cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? _kNavy : Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: selected
                                          ? _kNavy
                                          : Colors.blueGrey.shade200,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: _kNavy.withValues(
                                                  alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.blueGrey[700],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  ],

                  // ── Category results ──────────────────────────────────────
                  if (_selectedCategory != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$_selectedCategory Courses',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedCategory = null;
                              _categoryResults = [];
                            }),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_categoryLoading)
                      const SizedBox(
                        height: 120,
                        child: Center(
                            child: CircularProgressIndicator(color: _kNavy)),
                      )
                    else if (_categoryResults.isEmpty)
                      const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text('No courses in this category.',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categoryResults.length,
                          itemBuilder: (context, i) => _CourseCard(
                            course: _categoryResults[i],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // ── Featured Courses ───────────────────────────────────────
                  _sectionTitle('Featured Courses'),
                  const SizedBox(height: 12),
                  const _FeaturedCoursesSection(),
                  const SizedBox(height: 24),

                  // ── Top Courses ────────────────────────────────────────────
                  _sectionTitle('Top Courses'),
                  const SizedBox(height: 12),
                  const _TopCoursesSection(),
                  const SizedBox(height: 24),

                  // ── Quick Actions ──────────────────────────────────────────
                  _sectionTitle('Quick Actions'),
                  const SizedBox(height: 12),
                  _QuickActions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}

// ── Featured Courses ─────────────────────────────────────────────────────────

class _FeaturedCoursesSection extends StatefulWidget {
  const _FeaturedCoursesSection();

  @override
  State<_FeaturedCoursesSection> createState() =>
      _FeaturedCoursesSectionState();
}

class _FeaturedCoursesSectionState extends State<_FeaturedCoursesSection> {
  final _ds = CourseRemoteDataSource();
  List<CourseEntity> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _ds.fetchCourses();
      final all = raw.map(courseFromMap).toList();
      if (mounted) {
        setState(() {
          _courses = all.length > 6 ? all.skip(6).take(6).toList() : all.take(6).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: _kNavy)));
    }
    if (_courses.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _courses.length,
        itemBuilder: (_, i) => _CourseCard(course: _courses[i]),
      ),
    );
  }
}

// ── Top Courses ─────────────────────────────────────────────────────────────

class _TopCoursesSection extends StatefulWidget {
  const _TopCoursesSection();

  @override
  State<_TopCoursesSection> createState() => _TopCoursesSectionState();
}

class _TopCoursesSectionState extends State<_TopCoursesSection> {
  final _ds = CourseRemoteDataSource();
  List<CourseEntity> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _ds.fetchTopRatedCourses();
      if (mounted) {
        setState(() {
          _courses = raw.map(courseFromMap).take(6).toList();
          _loading = false;
        });
      }
    } catch (_) {
      // Fallback to all courses
      try {
        final raw = await _ds.fetchCourses();
        if (mounted) {
          setState(() {
            _courses = raw.map(courseFromMap).take(6).toList();
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: _kNavy)));
    }
    if (_courses.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _courses.length,
        itemBuilder: (_, i) => _CourseCard(course: _courses[i]),
      ),
    );
  }
}

// ── Course Card (shared) ─────────────────────────────────────────────────────

class _CourseCard extends StatefulWidget {
  final CourseEntity course;
  const _CourseCard({required this.course});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  final _wishlistDs = WishlistRemoteDataSource();
  bool _inWishlist = false;
  bool _wishlistLoading = false;

  Future<void> _toggleWishlist() async {
    if (_wishlistLoading) return;
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login to save courses to wishlist')),
        );
      }
      return;
    }
    setState(() => _wishlistLoading = true);
    try {
      if (_inWishlist) {
        await _wishlistDs.removeFromWishlist(widget.course.id, token);
        if (mounted) {
          setState(() => _inWishlist = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        }
      } else {
        await _wishlistDs.addToWishlist(widget.course.id, token);
        if (mounted) {
          setState(() => _inWishlist = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to wishlist'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final alreadyInWishlist = e is ApiException && e.code == 409;
        if (alreadyInWishlist) setState(() => _inWishlist = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              alreadyInWishlist
                  ? 'This course is already in your wishlist'
                  : e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor:
                alreadyInWishlist ? Colors.orange[700] : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return GestureDetector(
      onTap: () {
        if (course.id.isNotEmpty) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EnrollmentBlocProvider(
              child: CourseDetailScreen(
                courseId: course.id,
                title: course.title,
                description: course.description,
                imageUrl: course.imageUrl,
                price: course.price,
              ),
            ),
          ));
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(right: 14),
        elevation: 3,
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 100,
                      width: 200,
                      child: course.imageUrl != null
                          ? Image.network(course.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleWishlist,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: _wishlistLoading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _kNavy),
                              )
                            : Icon(
                                _inWishlist
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 17,
                                color: _inWishlist ? Colors.red : Colors.grey,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.instructorName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'By ${course.instructorName}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          course.isFree
                              ? 'Free'
                              : 'FCFA ${course.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: course.isFree ? Colors.green : _kBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8EAF6),
      child:
          const Center(child: Icon(Icons.menu_book, color: _kNavy, size: 36)),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _actionCard(
            context,
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            title: 'My Certificates',
            subtitle: 'View course completions and earned certificates.',
            buttonLabel: 'Open',
            buttonColor: Colors.amber[700]!,
            onTap: () => Navigator.of(context).pushNamed('/certificates'),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context,
            icon: Icons.videocam,
            iconColor: Colors.red,
            title: 'Live Sessions',
            subtitle:
                'Check upcoming sessions and join live classes from one place.',
            onTap: () => Navigator.of(context).pushNamed('/live-sessions'),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context,
            icon: Icons.notifications_active,
            iconColor: Colors.blue,
            title: 'Notifications',
            subtitle:
                'Review reminders, updates, and recent activity in one feed.',
            onTap: () => Navigator.of(context).pushNamed('/notifications'),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context,
            icon: Icons.support_agent,
            iconColor: Colors.green,
            title: 'Support Chat',
            subtitle:
                'Open the student support room to ask questions and get help.',
            onTap: () => Navigator.of(context).pushNamed('/chat'),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? buttonLabel,
    Color? buttonColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              if (buttonLabel != null)
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(buttonLabel,
                      style: const TextStyle(fontSize: 13)),
                )
              else
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
