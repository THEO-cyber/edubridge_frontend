import 'dart:convert';
import 'package:edubridge/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../blocs/enrollment_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import '../blocs/payment_bloc_provider.dart';
import '../blocs/certificate_bloc_provider.dart';
import 'certificate_screen_enhanced.dart';
import 'course_player_screen.dart';
import 'payment_screen_enhanced.dart';

const _navy = Color(0xFF1A237E);
const _blue = Color(0xFF1565C0);
const _green = Color(0xFF2E7D32);
const _bg = Color(0xFFF8F9FA);

// ─────────────────────────────────────────────────────────────────────────────
class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String title;
  final String description;
  final String? imageUrl;
  final double price;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.price = 0,
  });

  @override
  Widget build(BuildContext context) {
    return EnrollmentBlocProvider(
      child: _CourseDetailBody(
        courseId: courseId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CourseDetailBody extends StatefulWidget {
  final String courseId;
  final String title;
  final String description;
  final String? imageUrl;
  final double price;

  const _CourseDetailBody({
    required this.courseId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });

  @override
  State<_CourseDetailBody> createState() => _CourseDetailBodyState();
}

class _CourseDetailBodyState extends State<_CourseDetailBody> {
  // auth
  String? _token;

  // wishlist
  final _wishlistDs = WishlistRemoteDataSource();
  bool _inWishlist = false;
  bool _wishlistLoading = false;

  // enroll / progress
  bool _isEnrolled = false;
  String? _enrollmentId;
  double _progressPct = 0;
  Set<String> _completedLessonIds = {};

  // full course detail from API
  Map<String, dynamic> _detail = {};
  bool _detailLoading = true;

  // lessons (each lesson carries _sectionId and _sectionTitle for grouping)
  List<Map<String, dynamic>> _lessons = [];
  bool _lessonsLoading = false;

  // which section accordions are open
  final Set<String> _expandedSections = {};

  // description expand
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _init();
    _checkWishlist();
  }

  // ── init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final token = await SecureStorage.getToken();
    if (mounted) setState(() => _token = token);
    await Future.wait([
      _fetchCourseDetail(token),
    ]);
  }

  Future<void> _fetchCourseDetail(String? token) async {
    try {
      final res = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.courseDetails(widget.courseId)}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final enrolled = data['isEnrolled'] == true;
        final eid = _extractEnrollmentId(data);
        // Parse sections list
        final rawSections = data['sections'];
        final List<Map<String, dynamic>> sections = [];
        if (rawSections is List) {
          for (final s in rawSections) {
            if (s is Map<String, dynamic>) {
              sections.add(s);
            } else if (s is Map) {
              sections.add(Map<String, dynamic>.from(s));
            }
          }
        }

        // Extract lessons that are already nested inside sections
        final lessons = _extractLessonsFromSections(data);

        setState(() {
          _detail = data;
          _detailLoading = false;
          _isEnrolled = enrolled;
          _enrollmentId = eid;
          _lessons = lessons;
          _lessonsLoading = true; // always load from dedicated sections endpoint
        });

        if (enrolled && token != null) {
          _fetchProgress(token);
          if (eid == null) {
            _fetchEnrollmentIdFromList(token);
          }
        }

        // Always fetch from the dedicated sections endpoint regardless of inline data.
        // The endpoint works with or without auth (non-enrolled users see free-preview lessons).
        _fetchSectionLessons(token, sections);
      } else {
        if (mounted) setState(() => _detailLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  String? _extractEnrollmentId(Map<String, dynamic> d) {
    final a = d['enrollmentId']?.toString();
    if (a != null && a.isNotEmpty) return a;
    final b = (d['enrollment'] as Map?)?['id']?.toString();
    if (b != null && b.isNotEmpty) return b;
    final c = (d['enrollmentData'] as Map?)?['id']?.toString();
    if (c != null && c.isNotEmpty) return c;
    return null;
  }

  /// Normalises a raw lesson map from the API.
  /// The sections endpoint returns videos as a nested array:
  ///   "videos": [{"id": "...", "status": "READY"}]
  /// This helper promotes those fields to top-level videoId / videoStatus so
  /// the rest of the UI can read them uniformly.
  static Map<String, dynamic> _normalizeLesson(Map<String, dynamic> l) {
    // Extract videoId / videoStatus from videos[]
    if (l['videoId'] == null) {
      final videos = l['videos'];
      if (videos is List && videos.isNotEmpty) {
        final v = videos[0];
        if (v is Map) {
          l['videoId'] = v['id']?.toString();
          l['videoStatus'] = v['status']?.toString();
          if (l['videoUrl'] == null && v['url'] != null) {
            l['videoUrl'] = v['url']?.toString();
          }
        }
      }
    }
    // Normalise duration: API may return videoDuration (seconds) instead of durationMinutes
    if (l['durationMinutes'] == null) {
      final raw = l['videoDuration'] ?? l['duration'];
      if (raw != null) {
        double? secs;
        if (raw is num) secs = raw.toDouble();
        if (raw is String) secs = double.tryParse(raw);
        if (secs != null && secs > 0) {
          l['durationMinutes'] = (secs / 60).round().clamp(1, 9999);
        }
      }
    }
    return l;
  }

  /// Flatten all lessons from sections array in the course detail response.
  /// Tags each lesson with _sectionId and _sectionTitle for grouping in the UI.
  List<Map<String, dynamic>> _extractLessonsFromSections(Map<String, dynamic> data) {
    final sections = data['sections'];
    if (sections is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (final section in sections) {
      if (section is! Map) continue;
      final sectionId = section['id']?.toString() ?? '';
      final sectionTitle = section['title']?.toString() ?? '';
      final lessons = section['lessons'];
      if (lessons is! List) continue;
      for (final lesson in lessons) {
        final l = lesson is Map<String, dynamic>
            ? Map<String, dynamic>.from(lesson)
            : (lesson is Map ? Map<String, dynamic>.from(lesson) : null);
        if (l == null) continue;
        l['_sectionId'] = sectionId;
        l['_sectionTitle'] = sectionTitle;
        result.add(_normalizeLesson(l));
      }
    }
    return result;
  }

  /// Fetches all sections + lessons via GET /lessons/sections/:courseId
  Future<void> _fetchSectionLessons(
      String? token, List<Map<String, dynamic>> ignored) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.lessonSections(widget.courseId)}';
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final res = await apiGet(Uri.parse(url), headers: headers);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final rawSections = body is List
            ? body
            : (body['sections'] ?? body['data'] ?? body['items'] ?? body);

        final allLessons = <Map<String, dynamic>>[];
        if (rawSections is List) {
          for (final section in rawSections) {
            if (section is! Map) continue;
            final sectionId = section['id']?.toString() ?? '';
            final sectionTitle = section['title']?.toString() ?? '';
            final lessons = section['lessons'];
            if (lessons is! List) continue;
            for (final l in lessons) {
              final lesson = Map<String, dynamic>.from(
                  l is Map<String, dynamic>
                      ? l
                      : (l is Map ? Map<String, dynamic>.from(l) : {}));
              lesson['_sectionId'] = sectionId;
              lesson['_sectionTitle'] = sectionTitle;
              allLessons.add(_normalizeLesson(lesson));
            }
          }
        }
        setState(() {
          _lessons = allLessons;
          _lessonsLoading = false;
        });
        _autoExpandFirstSection(allLessons);
      } else {
        if (mounted) setState(() => _lessonsLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _lessonsLoading = false);
    }
  }

  /// Auto-opens the first section in the accordion when lessons first load.
  void _autoExpandFirstSection(List<Map<String, dynamic>> lessons) {
    if (lessons.isEmpty) return;
    final firstSid = lessons.first['_sectionId']?.toString() ?? '';
    if (firstSid.isNotEmpty && !_expandedSections.contains(firstSid)) {
      setState(() => _expandedSections.add(firstSid));
    }
  }

  Future<void> _fetchEnrollmentIdFromList(String token) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.enroll}';
    try {
      final res = await apiGet(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['enrollments'] ?? data['data'] ?? []);
        for (final e in list) {
          if (e is! Map) continue;
          final cid = (e['courseId'] ?? (e['course'] as Map?)?['id'])?.toString();
          if (cid == widget.courseId) {
            final eid = e['id']?.toString();
            if (eid != null && eid.isNotEmpty && mounted) {
              setState(() => _enrollmentId = eid);
              return;
            }
          }
        }
      }
    } catch (_) {
      // Best-effort — ignore failures.
    }
  }

  // Lessons come from sections inside the course detail response —
  // _extractLessonsFromSections handles this; no separate endpoint needed.

  Future<void> _fetchProgress(String token) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.enrollmentProgress(widget.courseId)}';
    try {
      final res = await apiGet(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        // Backend wraps result inside "enrollment" key
        final data = (body['enrollment'] as Map<String, dynamic>?) ?? body;
        final pct = _toDouble(data['progressPercentage'] ?? body['progressPercentage'] ?? 0);
        final raw = (data['lessonProgress'] ?? body['lessonProgress'] ?? body['completedLessonIds'] ?? []) as List;
        final done = <String>{};
        for (final item in raw) {
          if (item is Map) {
            final isComplete = item['isCompleted'] == true
                || item['completed'] == true
                || item['status']?.toString() == 'COMPLETED'
                || (item['completedAt'] != null && item['completedAt'].toString().isNotEmpty);
            if (isComplete) {
              final lid = (item['lessonId'] ?? item['lesson_id'] ?? item['id'])?.toString() ?? '';
              if (lid.isNotEmpty) done.add(lid);
            }
          } else if (item is String) {
            done.add(item);
          }
        }
        final eid = data['id']?.toString() ?? body['enrollmentId']?.toString();
        setState(() {
          _progressPct = pct;
          _completedLessonIds = done;
          if (eid != null && eid.isNotEmpty && _enrollmentId == null) _enrollmentId = eid;
        });
      }
    } catch (_) {
      // Best-effort enrolment lookup — ignore failures.
    }
  }

  Future<void> _checkWishlist() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return;
      final inWl = await _wishlistDs.isInWishlist(widget.courseId, token);
      if (mounted) setState(() => _inWishlist = inWl);
    } catch (_) {}
  }

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
        await _wishlistDs.removeFromWishlist(widget.courseId, token);
        if (mounted) {
          setState(() => _inWishlist = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        }
      } else {
        await _wishlistDs.addToWishlist(widget.courseId, token);
        if (mounted) {
          setState(() => _inWishlist = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to wishlist'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final already = e is ApiException && e.code == 409;
        if (already) setState(() => _inWishlist = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(already
              ? 'Already in your wishlist'
              : e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: already ? Colors.orange[700] : Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  /// Opens the full course player starting at [startIndex].
  void _openPlayer({int? startIndex}) {
    final token = _token;
    if (token == null || _lessons.isEmpty) return;

    // Default to first incomplete lesson
    final idx = startIndex ??
        () {
          final i = _lessons.indexWhere(
              (l) => !_completedLessonIds.contains(l['id']?.toString() ?? ''));
          return i >= 0 ? i : 0;
        }();

    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => CoursePlayerScreen(
            courseId: widget.courseId,
            courseTitle: widget.title,
            courseImageUrl: widget.imageUrl,
            lessons: _lessons,
            startLessonIndex: idx,
            enrollmentId: _enrollmentId,
            token: token,
            completedLessonIds: Set<String>.from(_completedLessonIds),
          ),
        ))
        .then((_) {
      if (_token != null && _isEnrolled) _fetchProgress(_token!);
    });
  }

  // ── Safe type helpers ─────────────────────────────────────────────────────

  static double _toDouble(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  // ── Derived getters ───────────────────────────────────────────────────────

  double get _price => _toDouble(_detail['price'], widget.price);

  bool get _isPaid => _price > 0;

  String get _title =>
      (_detail['title'] ?? widget.title).toString();

  String get _description =>
      (_detail['description'] ?? widget.description).toString();

  String get _imageUrl =>
      (_detail['imageUrl'] ?? _detail['thumbnail'] ?? widget.imageUrl ?? '').toString();

  String get _instructorName {
    final direct = _detail['instructorName'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final ins = _detail['instructor'];
    if (ins is Map) {
      final name = (ins['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
      final full = '${ins['firstName'] ?? ''} ${ins['lastName'] ?? ''}'.trim();
      if (full.isNotEmpty) return full;
    }
    return 'Instructor';
  }

  // The API returns category as an object { id, name, slug }, so pull the name
  // out rather than stringifying the whole map onto the screen.
  String get _category {
    final c = _detail['category'];
    if (c is Map) {
      return (c['name'] ?? c['title'] ?? c['slug'] ?? 'General').toString();
    }
    final s = (c ?? '').toString().trim();
    return s.isEmpty ? 'General' : s;
  }

  String get _level =>
      (_detail['level'] ?? 'Beginner').toString();

  String? get _duration => (_detail['duration'] ?? _detail['durationHours'])?.toString();

  double get _rating => _toDouble(_detail['rating']);

  int get _reviewCount => _toInt(_detail['reviewCount']) ?? 0;

  int get _studentCount => _toInt(_detail['studentCount']) ?? 0;

  List<String> get _objectives {
    final raw = _detail['objectives'] ?? _detail['whatYouWillLearn'] ?? [];
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    return [];
  }

  List<String> get _requirements {
    final raw = _detail['requirements'] ?? _detail['prerequisites'] ?? [];
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    return [];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnrollmentBloc, EnrollmentState>(
      listener: (ctx, state) {
        if (state is EnrollmentSuccess) {
          setState(() => _isEnrolled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enrolled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          if (_token != null) _fetchCourseDetail(_token);
        } else if (state is EnrollmentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        bottomNavigationBar: _buildBottomBar(),
        body: RefreshIndicator(
          onRefresh: () => _fetchCourseDetail(_token),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeroAppBar(),
              SliverToBoxAdapter(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero app bar ──────────────────────────────────────────────────────────

  Widget _buildHeroAppBar() {
    final imgUrl = _imageUrl;
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
            child: _wishlistLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    _inWishlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _inWishlist ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
          ),
          onPressed: _toggleWishlist,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            imgUrl.isNotEmpty
                ? Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroBg())
                : _heroBg(),
            // Gradient overlay — dark at bottom where text lives
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 1.0],
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            // Bottom content
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _category,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _instructorName,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_rating > 0) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          _rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (_reviewCount > 0)
                          Text(
                            ' (${_fmtCount(_reviewCount)})',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: Icon(Icons.menu_book, size: 80, color: Colors.white24)),
      );

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    if (_detailLoading) return const SizedBox.shrink();

    if (_isEnrolled) {
      final pct = _progressPct.clamp(0.0, 100.0);
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${pct.toStringAsFixed(0)}% complete',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _navy, fontSize: 13)),
                Text('${_completedLessonIds.length}/${_lessons.length} lessons',
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: pct >= 100 ? Colors.green : _blue,
              ),
            ),
            const SizedBox(height: 12),
            if (pct >= 100)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CertificateBlocProvider(
                      child: CertificateScreenEnhanced(token: _token ?? ''),
                    ),
                  )),
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Get Your Certificate',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _lessons.isNotEmpty ? () => _openPlayer() : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _progressPct > 0 || _completedLessonIds.isNotEmpty
                        ? 'Continue Learning'
                        : 'Start Learning',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Not enrolled
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_isPaid) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FCFA ${_price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22, color: _navy),
                ),
                const Text('One-time payment',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
              builder: (ctx, state) {
                final loading = state is EnrollmentLoading;
                return ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final token = await SecureStorage.getToken();
                          if (!ctx.mounted) return;
                          if (token == null || token.isEmpty) {
                            Navigator.of(ctx).pushReplacement(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                            return;
                          }
                          if (_isPaid) {
                            Navigator.of(ctx).push(MaterialPageRoute(
                              builder: (_) => PaymentBlocProvider(
                                child: PaymentScreenEnhanced(
                                  courseId: widget.courseId,
                                  courseName: _title,
                                  price: _price,
                                ),
                              ),
                            ));
                          } else {
                            ctx.read<EnrollmentBloc>().add(EnrollEvent(widget.courseId, token));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaid ? _blue : _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isPaid ? 'Buy Now' : 'Enroll for Free',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_detailLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        _buildStatsRow(),

        // What you'll learn
        if (_objectives.isNotEmpty) _buildSection(
          icon: Icons.lightbulb_outline_rounded,
          title: 'What you\'ll learn',
          child: _buildObjectivesGrid(),
        ),

        // Course includes
        _buildSection(
          icon: Icons.featured_play_list_outlined,
          title: 'This course includes',
          child: _buildCourseIncludes(),
        ),

        // Description
        _buildSection(
          icon: Icons.info_outline_rounded,
          title: 'About this course',
          child: _buildDescription(),
        ),

        // Requirements
        if (_requirements.isNotEmpty) _buildSection(
          icon: Icons.checklist_rounded,
          title: 'Requirements',
          child: _buildBulletList(_requirements),
        ),

        // Course content
        _buildSection(
          icon: Icons.video_library_outlined,
          title: 'Course content',
          trailing: _lessonsLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _navy))
              : Text(
                  '${_lessons.length} ${_lessons.length == 1 ? 'lesson' : 'lessons'}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
          child: _buildLessonList(),
        ),

        // Reviews
        _buildSection(
          icon: Icons.star_half_rounded,
          title: 'Student reviews',
          trailing: _rating > 0
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_rating.toStringAsFixed(1)}  (${_fmtCount(_reviewCount)})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _navy, fontSize: 13),
                  ),
                ])
              : null,
          child: _ReviewsSection(
              courseId: widget.courseId, canSubmit: _isEnrolled),
        ),

        const SizedBox(height: 100), // breathing room above bottom bar
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final items = <_StatItem>[];

    items.add(_StatItem(Icons.signal_cellular_alt_rounded, _level));
    if (_duration != null) items.add(_StatItem(Icons.access_time_rounded, '$_duration hrs'));
    if (_studentCount > 0) {
      items.add(_StatItem(Icons.people_outline_rounded, '${_fmtCount(_studentCount)} students'));
    }
    items.add(const _StatItem(Icons.workspace_premium_outlined, 'Certificate'));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: items.map((item) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 16, color: _blue),
            const SizedBox(width: 6),
            Text(item.label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        )).toList(),
      ),
    );
  }

  // ── What you'll learn ─────────────────────────────────────────────────────

  Widget _buildObjectivesGrid() {
    return Column(
      children: List.generate((_objectives.length / 2).ceil(), (row) {
        final left = _objectives[row * 2];
        final rightIdx = row * 2 + 1;
        final right = rightIdx < _objectives.length ? _objectives[rightIdx] : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ObjectiveItem(text: left)),
            if (right != null) ...[
              const SizedBox(width: 8),
              Expanded(child: _ObjectiveItem(text: right)),
            ] else
              const Expanded(child: SizedBox.shrink()),
          ],
        );
      }),
    );
  }

  // ── Course includes ───────────────────────────────────────────────────────

  Widget _buildCourseIncludes() {
    return Column(
      children: [
        _includeRow(Icons.play_circle_outline_rounded,
            '${_lessons.length} on-demand video ${_lessons.length == 1 ? 'lesson' : 'lessons'}'),
        const SizedBox(height: 10),
        _includeRow(Icons.all_inclusive_rounded, 'Full lifetime access'),
        const SizedBox(height: 10),
        _includeRow(Icons.phone_android_rounded, 'Access on mobile'),
        const SizedBox(height: 10),
        _includeRow(Icons.workspace_premium_rounded, 'Certificate of completion'),
      ],
    );
  }

  Widget _includeRow(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 18, color: _green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      );

  // ── Description ───────────────────────────────────────────────────────────

  Widget _buildDescription() {
    final text = _description;
    final isLong = text.length > 280;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
              fontSize: 14, color: Colors.black87, height: 1.65),
          maxLines: _descExpanded || !isLong ? null : 5,
          overflow: _descExpanded || !isLong ? null : TextOverflow.ellipsis,
        ),
        if (isLong) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _descExpanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                      color: _blue, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Icon(
                  _descExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _blue, size: 18,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Bullet list (requirements) ────────────────────────────────────────────

  Widget _buildBulletList(List<String> items) => Column(
        children: items
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: CircleAvatar(
                            radius: 3.5, backgroundColor: Colors.blueGrey),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87, height: 1.5)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );

  // ── Lesson list ───────────────────────────────────────────────────────────

  Widget _buildLessonList() {
    if (_lessonsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: _navy, strokeWidth: 2),
        ),
      );
    }
    if (_lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined, size: 48, color: Colors.blueGrey),
              SizedBox(height: 12),
              Text('No lessons available yet',
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              SizedBox(height: 4),
              Text("The instructor hasn't uploaded content yet.",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Group lessons by section
    final sectionOrder = <String>[];
    final sectionTitles = <String, String>{};
    final lessonsBySection = <String, List<Map<String, dynamic>>>{};
    int globalIndex = 0;
    final lessonGlobalIndex = <String, int>{};

    for (final lesson in _lessons) {
      final sid = lesson['_sectionId']?.toString() ?? '';
      final stitle = lesson['_sectionTitle']?.toString() ?? '';
      if (!sectionOrder.contains(sid)) {
        sectionOrder.add(sid);
        sectionTitles[sid] = stitle;
      }
      lessonsBySection.putIfAbsent(sid, () => []).add(lesson);
      globalIndex++;
      lessonGlobalIndex[lesson['id']?.toString() ?? '$globalIndex'] = globalIndex;
    }

    // If no section metadata, fall back to a flat list
    final hasSections = sectionOrder.any((sid) => sid.isNotEmpty);
    if (!hasSections) {
      return _buildFlatLessonTiles(_lessons, startAt: 1);
    }

    // Accordion: one card per section
    return Column(
      children: sectionOrder.asMap().entries.map((entry) {
        final idx = entry.key;
        final sid = entry.value;
        final title = sectionTitles[sid] ?? 'Section ${idx + 1}';
        final lessons = lessonsBySection[sid] ?? [];
        final totalMins = lessons.fold<int>(
            0, (s, l) => s + (_toInt(l['durationMinutes']) ?? 0));
        final isExpanded = _expandedSections.contains(sid);

        // Count lessons before this section for global numbering
        final preceding = sectionOrder.take(idx).fold<int>(
            0, (s, id) => s + (lessonsBySection[id]?.length ?? 0));

        return Container(
          margin: EdgeInsets.only(bottom: idx < sectionOrder.length - 1 ? 8 : 0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // ── Section header ──────────────────────────────────────
              InkWell(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedSections.remove(sid);
                  } else {
                    _expandedSections.add(sid);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: const Color(0xFFEEF0FB),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${lessons.length} ${lessons.length == 1 ? "lesson" : "lessons"}'
                              '${totalMins > 0 ? " · $totalMins min" : ""}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: _navy,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Lesson tiles ────────────────────────────────────────
              if (isExpanded)
                _buildFlatLessonTiles(lessons, startAt: preceding + 1),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlatLessonTiles(
      List<Map<String, dynamic>> lessons, {required int startAt}) {
    return Column(
      children: lessons.asMap().entries.map((entry) {
        final i = entry.key;
        final lesson = entry.value;
        final lessonNum = startAt + i;
        final lessonId = lesson['id']?.toString() ?? '';
        final done = _completedLessonIds.contains(lessonId);
        final hasVideo = (lesson['videoId']?.toString() ?? '').isNotEmpty;
        final hasLegacyUrl =
            (lesson['videoUrl']?.toString() ?? '').trim().isNotEmpty;
        final status = lesson['videoStatus']?.toString() ?? '';
        final isReady = (hasVideo && (status == 'READY' || status == 'APPROVED')) || hasLegacyUrl;
        final canTap = _isEnrolled && (isReady || done);
        final duration = _toInt(lesson['durationMinutes']);
        final isLast = i == lessons.length - 1;

        // find global index of this lesson in _lessons for the player
        final globalIdx = _lessons.indexWhere(
            (l) => l['id']?.toString() == lessonId);

        return InkWell(
          onTap: canTap
              ? () => _openPlayer(startIndex: globalIdx >= 0 ? globalIdx : 0)
              : (_isEnrolled && (hasVideo || hasLegacyUrl))
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Video is still being processed — check back soon')),
                      )
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: done
                  ? Colors.green.shade50
                  : canTap
                      ? Colors.white
                      : const Color(0xFFFAFAFA),
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              children: [
                // Number / check circle
                SizedBox(
                  width: 36,
                  height: 36,
                  child: done
                      ? CircleAvatar(
                          backgroundColor: _green,
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                        )
                      : CircleAvatar(
                          backgroundColor: canTap
                              ? const Color(0xFFE8EAF6)
                              : Colors.grey.shade100,
                          child: Text(
                            '$lessonNum',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: canTap ? _navy : Colors.grey,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson['title']?.toString() ?? 'Lesson $lessonNum',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: canTap || done ? Colors.black87 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (duration != null && duration > 0) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.play_circle_outline,
                              size: 12, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('$duration min',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blueGrey)),
                        ]),
                      ],
                      if (_isEnrolled && hasVideo &&
                          (status == 'PROCESSING' || status == 'UPLOADED'))
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('Video processing…',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange)),
                        ),
                    ],
                  ),
                ),
                // Right icon
                if (!_isEnrolled)
                  const Icon(Icons.lock_outline_rounded,
                      color: Colors.grey, size: 20)
                else if (done)
                  const Icon(Icons.replay_rounded, color: _navy, size: 26)
                else if (isReady)
                  const Icon(Icons.play_circle_outline_rounded,
                      color: _navy, size: 28)
                else
                  const Icon(Icons.hourglass_empty_rounded,
                      color: Colors.orange, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: _navy),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final String label;
  const _StatItem(this.icon, this.label);
}

class _ObjectiveItem extends StatelessWidget {
  final String text;
  const _ObjectiveItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 16, color: _green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews section
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsSection extends StatefulWidget {
  final String courseId;
  final bool canSubmit;
  const _ReviewsSection({required this.courseId, required this.canSubmit});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  int _selectedRating = 0;
  final _ctrl = TextEditingController();
  bool _submitting = false;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await ReviewRemoteDataSource().fetchReviews(widget.courseId);
      if (mounted) setState(() { _reviews = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a star rating')),
      );
      return;
    }
    final token = await SecureStorage.getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ReviewRemoteDataSource()
          .postReview(widget.courseId, _ctrl.text.trim(), _selectedRating, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green),
      );
      setState(() { _selectedRating = 0; _ctrl.clear(); });
      _load();
    } catch (e) {
      if (!mounted) return;
      final already = e is ApiException && e.code == 409;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(already
            ? 'You already reviewed this course'
            : e.toString().replaceFirst('ApiException: ', '')),
        backgroundColor: already ? Colors.orange[700] : Colors.red,
      ));
      if (already) _load();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static int _parseRating(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double get _avg {
    if (_reviews.isEmpty) return 0;
    final s = _reviews.fold<int>(0, (a, r) => a + _parseRating(r['rating']));
    return s / _reviews.length;
  }

  String _name(Map<String, dynamic> r) {
    final u = r['user'] as Map?;
    if (u == null) return 'Student';
    final un = (u['username'] ?? '').toString().trim();
    if (un.isNotEmpty) return un;
    final f = (u['firstName'] ?? '').toString().trim();
    final l = (u['lastName'] ?? '').toString().trim();
    return '$f $l'.trim().isNotEmpty ? '$f $l'.trim() : 'Student';
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : 'S');
  }

  Color _avatarColor(String name) {
    const pal = [Color(0xFF1A237E), Color(0xFF00695C), Color(0xFF4527A0), Color(0xFF283593)];
    return name.isEmpty ? pal[0] : pal[name.codeUnitAt(0) % pal.length];
  }

  String _date(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[d.month - 1]} ${d.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating summary
        if (!_loading && _reviews.isNotEmpty) ...[
          _buildRatingSummary(),
          const SizedBox(height: 20),
        ],

        // Reviews list
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: _navy, strokeWidth: 2),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.rate_review_outlined, color: _navy, size: 36),
              SizedBox(height: 8),
              Text('No reviews yet — be the first!',
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
            ]),
          )
        else
          Column(children: _reviews.map((r) => _ReviewCard(
            name: _name(r),
            initials: _initials(_name(r)),
            avatarColor: _avatarColor(_name(r)),
            rating: _parseRating(r['rating']),
            comment: (r['content'] ?? r['comment'] ?? '').toString().trim(),
            date: _date(r['createdAt']?.toString()),
          )).toList()),

        // Submit form
        if (widget.canSubmit) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Leave a review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _navy)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _selectedRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber, size: 38,
                ),
              ),
            )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share what you thought about this course…',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF0F4FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSummary() {
    final avg = _avg;
    final count = _reviews.length;
    // Count per star
    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final s = _parseRating(r['rating']);
      if (dist.containsKey(s)) dist[s] = dist[s]! + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(avg.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold, color: _navy, height: 1)),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber, size: 16,
                )),
              ),
              const SizedBox(height: 4),
              Text('$count ${count == 1 ? 'review' : 'reviews'}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final n = dist[star] ?? 0;
                final pct = count > 0 ? n / count : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text('$star', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 24,
                      child: Text('$n',
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                          textAlign: TextAlign.right),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String initials;
  final Color avatarColor;
  final int rating;
  final String comment;
  final String date;

  const _ReviewCard({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (date.isNotEmpty)
                      Text(date,
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber, size: 14,
                  )),
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(comment,
                      style: const TextStyle(
                          fontSize: 13, height: 1.5, color: Colors.black87)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
