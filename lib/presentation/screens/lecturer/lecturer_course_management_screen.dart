import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../constants/api_constants.dart';
import '../../../core/cache/app_cache.dart';
import '../../../core/secure_storage.dart';
import '../../../core/money.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../../data/datasources/course_remote_data_source.dart';
import '../../../data/datasources/lesson_remote_data_source.dart';
import '../../../data/datasources/video_processing_remote_data_source.dart';
import '../instructor_quiz_screen.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class LecturerCourseManagementScreen extends StatefulWidget {
  const LecturerCourseManagementScreen({super.key});

  @override
  State<LecturerCourseManagementScreen> createState() =>
      _LecturerCourseManagementScreenState();
}

class _LecturerCourseManagementScreenState
    extends State<LecturerCourseManagementScreen> {
  final _courseDs = CourseRemoteDataSource();
  final _lessonDs = LessonRemoteDataSource();
  final _videoDs = VideoProcessingRemoteDataSource();

  bool _isLoading = true;
  String? _token;
  String? _error;
  List<Map<String, dynamic>> _courses = [];
  String _filter = 'All'; // 'All' | 'Published' | 'Drafts'

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    const key = 'instructor_courses';

    // Serve cache immediately — no spinner on revisit
    final cached = AppCache.get<List<Map<String, dynamic>>>(key);
    if (cached != null) {
      setState(() { _courses = cached; _isLoading = false; });
    } else {
      setState(() { _isLoading = true; _error = null; });
    }

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      if (cached == null) setState(() { _isLoading = false; _error = 'Please login again.'; });
      return;
    }
    _token = token;

    try {
      final courses = await _courseDs.fetchInstructorCourses(token);
      AppCache.set(key, courses);
      if (!mounted) return;
      setState(() { _courses = courses; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      if (cached == null) {
        setState(() { _isLoading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
      }
    }
  }

  String _courseId(Map<String, dynamic> c) =>
      (c['id'] ?? c['_id'] ?? '').toString();
  String _courseTitle(Map<String, dynamic> c) =>
      (c['title'] ?? 'Untitled').toString();
  String _courseDescription(Map<String, dynamic> c) =>
      (c['description'] ?? '').toString();
  bool _isPublished(Map<String, dynamic> c) =>
      c['isPublished'] == true || c['published'] == true;
  String _courseCategory(Map<String, dynamic> c) {
    final cat = c['category'];
    if (cat is Map) return (cat['name'] ?? 'General').toString();
    return (cat ?? 'General').toString();
  }
  String _courseLevel(Map<String, dynamic> c) =>
      (c['level'] ?? 'Beginner').toString();
  double _coursePrice(Map<String, dynamic> c) =>
      double.tryParse(c['price']?.toString() ?? '0') ?? 0;

  Future<void> _createCourse() async {
    final token = _token ?? await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      _showError('Session expired. Please log in again.');
      return;
    }
    _token = token;
    final form = await _showCourseSheet();
    if (form == null) return;
    try {
      await _courseDs.createCourse(form, token);
      AppCache.invalidate('instructor_courses');
      if (!mounted) return;
      _showSuccess('Course created successfully!');
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? e.toString().replaceFirst(RegExp(r'^[A-Za-z]*Exception:\s*'), '')
          : e.toString();
      _showError('Create failed: $msg');
    }
  }

  Future<void> _updateCourse(Map<String, dynamic> course) async {
    final token = _token ?? await SecureStorage.getToken();
    if (token == null || token.isEmpty) { _showError('Session expired.'); return; }
    _token = token;
    final id = _courseId(course);
    if (id.isEmpty) return;
    final form = await _showCourseSheet(initial: course);
    if (form == null) return;
    try {
      await _courseDs.updateCourse(id, form, token);
      AppCache.invalidate('instructor_courses');
      if (!mounted) return;
      _showSuccess('Course updated!');
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? e.toString().replaceFirst(RegExp(r'^[A-Za-z]*Exception:\s*'), '')
          : e.toString();
      _showError('Update failed: $msg');
    }
  }

  Future<void> _publishCourse(Map<String, dynamic> course) async {
    final token = _token ?? await SecureStorage.getToken();
    if (token == null || token.isEmpty) { _showError('Session expired.'); return; }
    _token = token;
    final id = _courseId(course);
    if (id.isEmpty) return;
    try {
      await _courseDs.publishCourse(id, token);
      AppCache.invalidate('instructor_courses');
      if (!mounted) return;
      _showSuccess('Course submitted for review!');
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      _showError('Publish failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    final token = _token ?? await SecureStorage.getToken();
    if (token == null || token.isEmpty) { _showError('Session expired.'); return; }
    _token = token;
    final id = _courseId(course);
    if (id.isEmpty) return;
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete course?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete "${_courseTitle(course)}" and all its content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _courseDs.deleteCourse(id, token);
      AppCache.invalidate('instructor_courses');
      if (!mounted) return;
      _showSuccess('Course deleted.');
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      _showError('Delete failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _manageContent(Map<String, dynamic> course) async {
    final courseId = _courseId(course);
    if (_token == null || courseId.isEmpty) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CourseContentScreen(
        courseTitle: _courseTitle(course),
        courseId: courseId,
        token: _token!,
        lessonDs: _lessonDs,
        videoDs: _videoDs,
      ),
    ));

    // Refresh after returning — publish status or content may have changed
    AppCache.invalidate('instructor_courses');
    await _loadCourses();
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, maxLines: 6, overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  PopupMenuItem<String> _filterItem(String value, IconData icon) {
    final selected = _filter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: selected ? _kNavy : Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? _kNavy : Colors.grey.shade800)),
          if (selected) ...[const Spacer(), const Icon(Icons.check_rounded, size: 16, color: _kNavy)],
        ],
      ),
    );
  }

  // ── Beautiful full-screen sheet form ──────────────────────────────────────
  Future<Map<String, dynamic>?> _showCourseSheet({
    Map<String, dynamic>? initial,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourseFormSheet(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final published = _courses.where(_isPublished).length;
    final drafts = _courses.length - published;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      floatingActionButton: _isLoading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _createCourse,
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              elevation: 6,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Course', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: Column(
        children: [
          _buildHeader(published: published, drafts: drafts),
          Expanded(
            child: _isLoading
                ? const CourseListSkeleton(count: 3)
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        color: _kNavy,
                        onRefresh: _loadCourses,
                        child: _courses.isEmpty ? _buildEmpty() : _buildList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({int published = 0, int drafts = 0}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Courses',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        ),
                        Text(
                          _isLoading
                              ? 'Loading...'
                              : '${_courses.length} course${_courses.length == 1 ? '' : 's'} in your portfolio',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => setState(() => _filter = value),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    offset: const Offset(0, 48),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(_filter, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                    itemBuilder: (_) => [
                      _filterItem('All', Icons.library_books_rounded),
                      _filterItem('Published', Icons.public_rounded),
                      _filterItem('Drafts', Icons.edit_note_rounded),
                    ],
                  ),
                ],
              ),
              if (_courses.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatBadge(count: _courses.length, label: 'Total', icon: Icons.library_books_rounded, color: Colors.white.withValues(alpha: 0.18)),
                    const SizedBox(width: 10),
                    _StatBadge(count: published, label: 'Published', icon: Icons.public_rounded, color: Colors.green.withValues(alpha: 0.35)),
                    const SizedBox(width: 10),
                    _StatBadge(count: drafts, label: 'Drafts', icon: Icons.edit_note_rounded, color: Colors.orange.withValues(alpha: 0.35)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kNavy.withValues(alpha: 0.12), _kBlue.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_stories_outlined, size: 60, color: _kNavy.withValues(alpha: 0.45)),
              ),
              const SizedBox(height: 28),
              const Text('No courses yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), letterSpacing: -0.3)),
              const SizedBox(height: 10),
              Text(
                'Create your first course and start sharing\nyour knowledge with students.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade400, height: 1.6, fontSize: 14),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _createCourse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0D1B6E), Color(0xFF1565C0)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _kNavy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Create First Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final filtered = _courses.where((c) {
      if (_filter == 'Published') return _isPublished(c);
      if (_filter == 'Drafts') return !_isPublished(c);
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off_rounded, size: 52, color: Colors.blueGrey.shade200),
            const SizedBox(height: 14),
            Text('No $_filter courses', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 6),
            Text('Try a different filter above.', style: TextStyle(color: Colors.blueGrey.shade400)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _CourseCard(
        course: filtered[i],
        courseTitle: _courseTitle(filtered[i]),
        courseDescription: _courseDescription(filtered[i]),
        courseCategory: _courseCategory(filtered[i]),
        courseLevel: _courseLevel(filtered[i]),
        coursePrice: _coursePrice(filtered[i]),
        isPublished: _isPublished(filtered[i]),
        onEdit: () => _updateCourse(filtered[i]),
        onPublish: () => _publishCourse(filtered[i]),
        onDelete: () => _deleteCourse(filtered[i]),
        onManageContent: () => _manageContent(filtered[i]),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  const _StatBadge({required this.count, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1)),
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final String courseTitle;
  final String courseDescription;
  final String courseCategory;
  final String courseLevel;
  final double coursePrice;
  final bool isPublished;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onDelete;
  final VoidCallback onManageContent;

  const _CourseCard({
    required this.course,
    required this.courseTitle,
    required this.courseDescription,
    required this.courseCategory,
    required this.courseLevel,
    required this.coursePrice,
    required this.isPublished,
    required this.onEdit,
    required this.onPublish,
    required this.onDelete,
    required this.onManageContent,
  });

  Color get _accentColor {
    final cat = courseCategory.toLowerCase();
    if (cat.contains('dev') || cat.contains('program')) return const Color(0xFF1565C0);
    if (cat.contains('design')) return const Color(0xFF7B1FA2);
    if (cat.contains('business')) return const Color(0xFF00796B);
    if (cat.contains('photo')) return const Color(0xFFE64A19);
    if (cat.contains('it') || cat.contains('software')) return const Color(0xFF0D47A1);
    if (cat.contains('math') || cat.contains('science')) return const Color(0xFF00838F);
    return const Color(0xFF283593);
  }

  Color get _levelColor {
    switch (courseLevel.toUpperCase()) {
      case 'BEGINNER': return const Color(0xFF2E7D32);
      case 'INTERMEDIATE': return const Color(0xFFE65100);
      case 'ADVANCED': return const Color(0xFFC62828);
      default: return Colors.blueGrey;
    }
  }

  String get _levelLabel {
    switch (courseLevel.toUpperCase()) {
      case 'BEGINNER': return 'Beginner';
      case 'INTERMEDIATE': return 'Intermediate';
      case 'ADVANCED': return 'Advanced';
      default: return courseLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = (course['thumbnailUrl'] ?? course['thumbnail'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _accentColor.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner / thumbnail ──────────────────────────────
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  thumbnail.isNotEmpty
                      ? Image.network(thumbnail, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CourseBanner(color: _accentColor))
                      : _CourseBanner(color: _accentColor),
                  // Dark gradient overlay at bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Category pill (top-left)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _accentColor.withValues(alpha: 0.4), blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_rounded, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(courseCategory, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  // Status chip (top-right)
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPublished ? Colors.green.shade600 : Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPublished ? Icons.public_rounded : Icons.edit_note_rounded, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(isPublished ? 'Published' : 'Draft', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  // Price (bottom-right)
                  Positioned(
                    bottom: 10, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: coursePrice == 0 ? Colors.green.shade700 : Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        coursePrice == 0 ? 'Free' : Money.xaf(coursePrice),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  // Level badge (bottom-left)
                  Positioned(
                    bottom: 10, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _levelColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_levelLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                courseTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (courseDescription.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  courseDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13, height: 1.5),
                ),
              ),

            // ── Action row ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Row(
                children: [
                  _CardAction(icon: Icons.edit_rounded, label: 'Edit', color: _kBlue, onTap: onEdit),
                  const SizedBox(width: 6),
                  _CardAction(icon: Icons.folder_open_rounded, label: 'Content', color: Colors.orange.shade700, onTap: onManageContent),
                  const Spacer(),
                  if (!isPublished) ...[
                    _CardAction(icon: Icons.rocket_launch_rounded, label: 'Publish', color: Colors.green.shade700, onTap: onPublish),
                    const SizedBox(width: 6),
                  ],
                  _CardAction(icon: Icons.delete_rounded, label: 'Delete', color: Colors.red.shade600, onTap: onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseBanner extends StatelessWidget {
  final Color color;
  const _CourseBanner({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.auto_stories_rounded, size: 52, color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CardAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}


// ── Create/Edit Course Sheet ──────────────────────────────────────────────────

class _CourseFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _CourseFormSheet({this.initial});

  @override
  State<_CourseFormSheet> createState() => _CourseFormSheetState();
}

class _CourseFormSheetState extends State<_CourseFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _thumbnailCtrl = TextEditingController();
  final _reqInputCtrl = TextEditingController();
  final _objInputCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> _requirements = [];
  List<String> _objectives = [];
  bool _isFree = false;

  // Categories loaded from API — each entry has 'id' and 'name'
  List<Map<String, String>> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;

  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _levelApiValues = {
    'Beginner': 'BEGINNER',
    'Intermediate': 'INTERMEDIATE',
    'Advanced': 'ADVANCED',
  };
  String _selectedLevel = 'Beginner';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    final i = widget.initial;
    if (i != null) {
      _titleCtrl.text = (i['title'] ?? '').toString();
      _descCtrl.text = (i['description'] ?? '').toString();
      _priceCtrl.text = (i['price'] ?? '0').toString();
      _thumbnailCtrl.text = (i['thumbnailUrl'] ?? i['thumbnail'] ?? '').toString();
      final reqs = i['requirements'];
      if (reqs is List) _requirements = List<String>.from(reqs);
      final objs = i['objectives'];
      if (objs is List) _objectives = List<String>.from(objs);
      final lvl = (i['level'] ?? '').toString();
      final price = double.tryParse(i['price']?.toString() ?? '0') ?? 0;
      _isFree = price == 0;
      // Normalize level from API (e.g. "BEGINNER" → "Beginner")
      final normalized = lvl.isEmpty ? '' : lvl[0].toUpperCase() + lvl.substring(1).toLowerCase();
      if (_levels.contains(normalized)) _selectedLevel = normalized;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchCategories}'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> raw = body is List
            ? body
            : (body is Map ? (body['data'] ?? body['categories'] ?? []) : []);
        final cats = <Map<String, String>>[];
        for (final item in raw) {
          if (item is Map) {
            final id = (item['id'] ?? item['_id'] ?? '').toString();
            final name = (item['name'] ?? item['title'] ?? item['category'] ?? '').toString();
            if (name.isNotEmpty) cats.add({'id': id, 'name': name});
          } else if (item is String && item.isNotEmpty) {
            cats.add({'id': '', 'name': item});
          }
        }
        if (mounted) {
          setState(() {
            _categories = cats;
            _loadingCategories = false;
            // Pre-select from existing course
            final i = widget.initial;
            if (i != null) {
              final existingCatId = (i['categoryId'] ?? '').toString();
              final existingCatName = (i['category'] is Map
                  ? (i['category']['name'] ?? '')
                  : (i['category'] ?? '')).toString();
              final match = cats.firstWhere(
                (c) => c['id'] == existingCatId || c['name'] == existingCatName,
                orElse: () => {},
              );
              if (match.isNotEmpty) {
                _selectedCategoryId = match['id'];
              }
            }
            if (_selectedCategoryId == null && cats.isNotEmpty) {
              _selectedCategoryId = cats.first['id'];
            }
          });
        }
      } else {
        if (mounted) setState(() => _loadingCategories = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _thumbnailCtrl.dispose();
    _reqInputCtrl.dispose();
    _objInputCtrl.dispose();
    super.dispose();
  }

  void _addRequirement() {
    final text = _reqInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _requirements.add(text); _reqInputCtrl.clear(); });
  }

  void _addObjective() {
    final text = _objInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _objectives.add(text); _objInputCtrl.clear(); });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one requirement')),
      );
      return;
    }
    if (_objectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one learning objective')),
      );
      return;
    }
    final thumb = _thumbnailCtrl.text.trim();
    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'categoryId': _selectedCategoryId,
      'level': _levelApiValues[_selectedLevel] ?? _selectedLevel.toUpperCase(),
      'requirements': _requirements,
      'objectives': _objectives,
      'price': _isFree ? 0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0),
      if (!_isFree) 'currency': 'XAF',
      if (thumb.isNotEmpty) 'thumbnailUrl': thumb,
    };
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final mq = MediaQuery.of(context);
    return Container(
      height: mq.size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHeader(isEdit),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, mq.viewInsets.bottom + 20),
                children: [
                  _buildBasicsCard(),
                  const SizedBox(height: 14),
                  _buildCategoryCard(),
                  const SizedBox(height: 14),
                  _buildLevelCard(),
                  const SizedBox(height: 14),
                  _buildPricingCard(),
                  const SizedBox(height: 14),
                  _buildRequirementsCard(),
                  const SizedBox(height: 14),
                  _buildObjectivesCard(),
                  const SizedBox(height: 14),
                  _buildThumbnailCard(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(isEdit),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black38)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.auto_stories_rounded,
                      color: Colors.white, size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Course' : 'Create New Course',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.bold, letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit
                              ? 'Update your course information'
                              : 'Share your knowledge with the world',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[900], letterSpacing: -0.2)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
        ],
      ),
    );
  }

  Widget _buildBasicsCard() => _card(
    icon: Icons.edit_document,
    iconColor: _kNavy,
    title: 'Course Basics',
    child: Column(children: [
      _FormField(
        controller: _titleCtrl,
        label: 'Course Title',
        hint: 'e.g. Complete Flutter Development Bootcamp',
        icon: Icons.title_rounded,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
      ),
      const SizedBox(height: 14),
      _FormField(
        controller: _descCtrl,
        label: 'Description',
        hint: 'Describe what students will learn and achieve...',
        icon: Icons.description_outlined,
        maxLines: 4,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
      ),
    ]),
  );

  Widget _buildCategoryCard() => _card(
    icon: Icons.category_rounded,
    iconColor: const Color(0xFF7B1FA2),
    title: 'Category',
    child: _loadingCategories
        ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _kNavy)))
        : _categories.isEmpty
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                child: Text('Could not load categories. Check your connection.', style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
              )
            : Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategoryId == cat['id'] && cat['id']!.isNotEmpty;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF7B1FA2) : const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: selected ? const Color(0xFF7B1FA2) : Colors.purple.shade100),
                        boxShadow: selected ? [BoxShadow(color: Colors.purple.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white), const SizedBox(width: 5)],
                          Text(cat['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.purple.shade700)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
  );

  Widget _buildLevelCard() {
    final levelData = {
      'Beginner':     {'icon': Icons.spa_outlined,                   'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9), 'desc': 'No prior knowledge needed'},
      'Intermediate': {'icon': Icons.local_fire_department_outlined, 'color': const Color(0xFFE65100), 'bg': const Color(0xFFFFF3E0), 'desc': 'Some experience required'},
      'Advanced':     {'icon': Icons.bolt_rounded,                   'color': const Color(0xFFC62828), 'bg': const Color(0xFFFFEBEE), 'desc': 'Expert-level content'},
    };
    return _card(
      icon: Icons.signal_cellular_alt_rounded,
      iconColor: const Color(0xFFE65100),
      title: 'Difficulty Level',
      child: Column(
        children: _levels.map((lvl) {
          final d = levelData[lvl]!;
          final selected = _selectedLevel == lvl;
          final color = d['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedLevel = lvl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? color : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? color : Colors.grey.shade200, width: selected ? 1.5 : 1),
                boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))] : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.2) : d['bg'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(d['icon'] as IconData, size: 20, color: selected ? Colors.white : color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lvl, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey.shade800)),
                        Text(d['desc'] as String, style: TextStyle(fontSize: 12, color: selected ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingCard() => _card(
    icon: Icons.payments_outlined,
    iconColor: const Color(0xFF00695C),
    title: 'Pricing',
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _PriceToggle(label: 'Paid', icon: Icons.attach_money_rounded, selected: !_isFree, color: const Color(0xFF00695C), onTap: () => setState(() => _isFree = false)),
              _PriceToggle(label: 'Free', icon: Icons.card_giftcard_rounded, selected: _isFree, color: Colors.blue.shade700, onTap: () => setState(() => _isFree = true)),
            ],
          ),
        ),
        if (!_isFree) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                child: const Text('FCFA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
              ),
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 20, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: const Color(0xFFE8F5E9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00695C), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            ),
            validator: (v) {
              if (_isFree) return null;
              if (v == null || v.isEmpty) return 'Enter a price';
              if (double.tryParse(v) == null) return 'Invalid price';
              return null;
            },
          ),
        ],
      ],
    ),
  );

  Widget _buildTagSection({
    required TextEditingController ctrl,
    required List<String> items,
    required Color color,
    required String hint,
    required String subtitle,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: 8, runSpacing: 8,
            children: items.asMap().entries.map((e) => _TagChip(
              label: e.value, color: color,
              onRemove: () => onRemove(e.key),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => onAdd(),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  filled: true,
                  fillColor: color.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementsCard() => _card(
    icon: Icons.checklist_rounded,
    iconColor: const Color(0xFF1565C0),
    title: 'Requirements',
    child: _buildTagSection(
      ctrl: _reqInputCtrl,
      items: _requirements,
      color: const Color(0xFF1565C0),
      hint: 'e.g. Basic knowledge of algebra',
      subtitle: 'What should students know before starting?',
      onAdd: _addRequirement,
      onRemove: (i) => setState(() => _requirements.removeAt(i)),
    ),
  );

  Widget _buildObjectivesCard() => _card(
    icon: Icons.flag_outlined,
    iconColor: const Color(0xFF6A1B9A),
    title: 'Learning Objectives',
    child: _buildTagSection(
      ctrl: _objInputCtrl,
      items: _objectives,
      color: const Color(0xFF6A1B9A),
      hint: 'e.g. Build a full-stack Flutter app',
      subtitle: 'What will students achieve by the end?',
      onAdd: _addObjective,
      onRemove: (i) => setState(() => _objectives.removeAt(i)),
    ),
  );

  Widget _buildThumbnailCard() => _card(
    icon: Icons.image_outlined,
    iconColor: const Color(0xFFBF360C),
    title: 'Thumbnail (optional)',
    child: Column(
      children: [
        TextFormField(
          controller: _thumbnailCtrl,
          keyboardType: TextInputType.url,
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'https://example.com/course-cover.jpg',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFFBF360C)),
            filled: true,
            fillColor: const Color(0xFFFBE9E7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBF360C), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (_thumbnailCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _thumbnailCtrl.text.trim(),
              height: 140, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 36),
                  const SizedBox(height: 6),
                  Text('Invalid image URL', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildSubmitButton(bool isEdit) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D1B6E), Color(0xFF1565C0)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isEdit ? Icons.save_rounded : Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Save Changes' : 'Launch Course',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PriceToggle({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, size: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;
  const _FormField({required this.controller, required this.label, required this.hint, required this.icon, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF455A64), letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A237E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1976D2)),
            filled: true,
            fillColor: const Color(0xFFF0F4FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kNavy, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
          ),
        ),
      ],
    );
  }
}

// ── Course Content Screen ────────────────────────────────────────────────────

class CourseContentScreen extends StatefulWidget {
  final String courseTitle;
  final String courseId;
  final String token;
  final LessonRemoteDataSource lessonDs;
  final VideoProcessingRemoteDataSource videoDs;

  const CourseContentScreen({
    super.key,
    required this.courseTitle,
    required this.courseId,
    required this.token,
    required this.lessonDs,
    required this.videoDs,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _sections = [];

  // Session cache so video status survives _load() calls when the backend
  // doesn't populate videoStatus in the sections response.
  static final Map<String, String> _vsCache = {};  // lessonId → videoStatus
  static final Map<String, String> _viCache = {};  // lessonId → videoId

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Derive a canonical videoStatus string from whatever the backend sends.
  String _normVideoStatus(Map<String, dynamic> l) {
    // Primary: videos[] array — take first element's status
    final videos = l['videos'];
    if (videos is List && videos.isNotEmpty) {
      final first = videos[0];
      if (first is Map) {
        final s = (first['status'] ?? '').toString().trim().toUpperCase();
        if (s.isNotEmpty) return s;
      }
    }

    // Legacy: direct videoStatus field
    final direct = (l['videoStatus'] ?? l['video_status'] ?? '').toString().trim().toUpperCase();
    if (direct.isNotEmpty) return direct;

    // Legacy: nested video object
    final video = l['video'];
    if (video is Map) {
      final s = (video['status'] ?? '').toString().trim().toUpperCase();
      if (s.isNotEmpty) return s;
      final url = (video['url'] ?? video['streamUrl'] ?? video['videoUrl'] ?? '').toString();
      if (url.isNotEmpty) return 'READY';
    }

    // Legacy: flat videoUrl
    final url = (l['videoUrl'] ?? l['streamUrl'] ?? l['video_url'] ?? '').toString();
    if (url.isNotEmpty) return 'READY';

    if (l['hasVideo'] == true || l['has_video'] == true) return 'READY';

    return '';
  }

  String _normVideoId(Map<String, dynamic> l) {
    // Primary: videos[] array
    final videos = l['videos'];
    if (videos is List && videos.isNotEmpty) {
      final first = videos[0];
      if (first is Map) {
        final id = (first['id'] ?? first['videoId'] ?? '').toString();
        if (id.isNotEmpty) return id;
      }
    }

    // Legacy
    final direct = (l['videoId'] ?? l['video_id'] ?? '').toString();
    if (direct.isNotEmpty) return direct;
    final video = l['video'];
    if (video is Map) return (video['id'] ?? video['videoId'] ?? '').toString();
    return '';
  }

  Map<String, dynamic> _normLesson(Map<String, dynamic> l) {
    final lessonId = (l['id'] ?? l['_id'] ?? l['lessonId'] ?? '').toString();
    var status = _normVideoStatus(l);
    var videoId = _normVideoId(l);

    // Fall back to session cache when backend returns empty status
    if (status.isEmpty && lessonId.isNotEmpty) status = _vsCache[lessonId] ?? '';
    if (videoId.isEmpty && lessonId.isNotEmpty) videoId = _viCache[lessonId] ?? '';

    return {
      ...l,
      'videoStatus': status,
      if (videoId.isNotEmpty) 'videoId': videoId,
    };
  }

  Map<String, dynamic> _normSection(Map<String, dynamic> s) {
    final rawLessons = s['lessons'];
    if (rawLessons is! List) return s;
    return {
      ...s,
      'lessons': rawLessons
          .whereType<Map>()
          .map((l) => _normLesson(Map<String, dynamic>.from(l)))
          .toList(),
    };
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = _sections.isEmpty; _error = null; });

    // ── 1. Try dedicated sections endpoint ───────────────────────────────────
    try {
      // GET /lessons/sections/{courseId}  — courseId is a path segment
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.lessons}/sections/${widget.courseId}');
      final r = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      }).timeout(const Duration(seconds: 12));
      debugPrint('-- loadSections → ${r.statusCode} ${r.body.substring(0, r.body.length.clamp(0, 200))}');

      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        final raw = decoded is List
            ? decoded
            : ((decoded is Map
                    ? (decoded['data'] ?? decoded['sections'] ?? decoded['items'])
                    : null) ??
                []) as List;
        final sections = raw
            .whereType<Map>()
            .map((s) => _normSection(Map<String, dynamic>.from(s)))
            .toList()
          ..sort((a, b) =>
              ((a['sortOrder'] ?? a['order'] ?? 0) as num)
                  .compareTo(((b['sortOrder'] ?? b['order'] ?? 0) as num)));
        if (sections.isNotEmpty) {
          debugPrint('-- section[0] lessons sample: '
              '${(sections[0]['lessons'] as List?)?.take(1).toList()}');
        }
        if (!mounted) return;
        setState(() { _sections = sections; _isLoading = false; });
        return;
      }
      // non-200: fall through to lessons fallback
    } catch (e) {
      debugPrint('-- loadSections error: $e');
      // network error on sections endpoint — try lessons fallback
    }

    // ── 2. Lessons fallback: group flat lessons by section ───────────────────
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.lessons}'
            '?courseId=${widget.courseId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 12));
      debugPrint('-- loadLessons → ${r.statusCode}');

      if (!mounted) return;

      if (r.statusCode != 200) {
        // 404 or any other code = treat as empty course (not an error)
        setState(() { _sections = []; _isLoading = false; });
        return;
      }

      final decoded = jsonDecode(r.body);
      final raw = decoded is List
          ? decoded
          : ((decoded is Map
                  ? (decoded['data'] ?? decoded['lessons'] ?? decoded['items'])
                  : null) ??
              []) as List;

      if (raw.isEmpty) {
        setState(() { _sections = []; _isLoading = false; });
        return;
      }

      final ordered = <String>[];
      final grouped = <String, Map<String, dynamic>>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final lesson = _normLesson(Map<String, dynamic>.from(item));
        final sec = lesson['section'];
        final sid = (lesson['sectionId'] ??
                (sec is Map ? sec['id'] : null) ??
                (sec is String ? sec : null) ??
                '_none')
            .toString();
        final stitle = (lesson['sectionTitle'] ??
                (sec is Map ? sec['title'] : null) ??
                (sid == '_none' ? 'Lessons' : 'Section'))
            .toString();
        final sorder =
            ((lesson['sectionOrder'] ?? (sec is Map ? sec['order'] : null) ?? ordered.length) as num);
        if (!grouped.containsKey(sid)) {
          ordered.add(sid);
          grouped[sid] = {'id': sid, 'title': stitle, 'sortOrder': sorder, 'lessons': <Map<String, dynamic>>[]};
        }
        (grouped[sid]!['lessons'] as List<Map<String, dynamic>>).add(lesson);
      }
      final sections = ordered.map((k) => grouped[k]!).toList()
        ..sort((a, b) =>
            ((a['sortOrder'] ?? 0) as num)
                .compareTo(((b['sortOrder'] ?? 0) as num)));
      setState(() { _sections = sections; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      // Network failure on BOTH endpoints — show error only if we have nothing
      if (_sections.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Could not connect to server. Check your connection.';
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, maxLines: 4)),
      ]),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 6),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Optimistic state helpers ─────────────────────────────────────────────────

  static String _id(Map<String, dynamic> m) =>
      (m['id'] ?? m['_id'] ?? m['sectionId'] ?? m['lessonId'] ?? '').toString();

  void _applyAddSection(Map<String, dynamic> res, String fallbackTitle, int fallbackOrder) {
    final s = <String, dynamic>{
      'id': _id(res).isNotEmpty ? _id(res) : '_tmp_${DateTime.now().millisecondsSinceEpoch}',
      'title': res['title'] ?? fallbackTitle,
      'sortOrder': res['sortOrder'] ?? res['order'] ?? fallbackOrder,
      'lessons': <Map<String, dynamic>>[],
    };
    setState(() {
      _sections = [..._sections, s]
        ..sort((a, b) =>
            ((a['sortOrder'] ?? a['order'] ?? 0) as num)
                .compareTo(((b['sortOrder'] ?? b['order'] ?? 0) as num)));
    });
  }

  void _applyUpdateSection(String id, Map<String, dynamic> fields) {
    setState(() {
      _sections = _sections.map((s) {
        if (_id(s) == id) return {...s, ...fields};
        return s;
      }).toList();
    });
  }

  void _applyDeleteSection(String id) {
    setState(() => _sections = _sections.where((s) => _id(s) != id).toList());
  }

  void _applyAddLesson(String sectionId, Map<String, dynamic> res, String fallbackTitle) {
    final newId = _id(res).isNotEmpty ? _id(res) : '_tmp_${DateTime.now().millisecondsSinceEpoch}';
    final l = <String, dynamic>{
      'id': newId,
      'title': res['title'] ?? fallbackTitle,
      'videoStatus': res['videoStatus'] ?? '',
      'content': res['content'] ?? '',
    };
    setState(() {
      _sections = _sections.map((s) {
        if (_id(s) != sectionId) return s;
        final lessons = List<Map<String, dynamic>>.from(
            (s['lessons'] as List? ?? []));
        return {...s, 'lessons': [...lessons, l]};
      }).toList();
    });
  }

  void _applyUpdateLesson(String lessonId, Map<String, dynamic> fields) {
    // Persist video status / id in the session cache so _load() can restore
    // them even when the backend returns empty videoStatus in sections.
    final vs = fields['videoStatus']?.toString();
    final vi = fields['videoId']?.toString();
    if (vs != null && vs.isNotEmpty) _vsCache[lessonId] = vs;
    if (vi != null && vi.isNotEmpty) _viCache[lessonId] = vi;

    setState(() {
      _sections = _sections.map((s) {
        final lessons = (s['lessons'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        if (!lessons.any((l) => _id(l) == lessonId)) return s;
        return {
          ...s,
          'lessons': lessons.map((l) {
            if (_id(l) == lessonId) return {...l, ...fields};
            return l;
          }).toList(),
        };
      }).toList();
    });
  }

  void _applyDeleteLesson(String lessonId) {
    setState(() {
      _sections = _sections.map((s) {
        final lessons = (s['lessons'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        if (!lessons.any((l) => _id(l) == lessonId)) return s;
        return {
          ...s,
          'lessons': lessons.where((l) => _id(l) != lessonId).toList(),
        };
      }).toList();
    });
  }

  // ── Section CRUD ─────────────────────────────────────────────────────────────

  Future<void> _addSection() async {
    final titleCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '${_sections.length + 1}');
    final ok = await _showFieldDialog(
      title: 'Add Section',
      icon: Icons.add_box_outlined,
      color: _kBlue,
      fields: [
        _DialogField('Section Title', Icons.title_rounded, titleCtrl),
        _DialogField('Order', Icons.sort_rounded, orderCtrl, isNumber: true),
      ],
    );
    if (ok != true) return;
    final t = titleCtrl.text.trim();
    if (t.isEmpty) return;
    final order = int.tryParse(orderCtrl.text.trim()) ?? (_sections.length + 1);
    try {
      final res = await widget.lessonDs.addSection(
          widget.courseId, {'title': t, 'order': order}, widget.token);
      _applyAddSection(res, t, order);
      _showSuccess('Section "$t" added!');
    } catch (e) {
      _showError('Add section failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _editSection(Map<String, dynamic> section) async {
    final id = _id(section);
    if (id.isEmpty) return;
    final titleCtrl = TextEditingController(text: (section['title'] ?? '').toString());
    final orderCtrl = TextEditingController(
        text: (section['sortOrder'] ?? section['order'] ?? '').toString());
    final ok = await _showFieldDialog(
      title: 'Edit Section',
      icon: Icons.edit_note_outlined,
      color: Colors.orange[700]!,
      fields: [
        _DialogField('Title', Icons.title_rounded, titleCtrl),
        _DialogField('Order', Icons.sort_rounded, orderCtrl, isNumber: true),
      ],
    );
    if (ok != true) return;
    final t = titleCtrl.text.trim();
    if (t.isEmpty) return;
    final body = <String, dynamic>{'title': t};
    final o = int.tryParse(orderCtrl.text.trim());
    if (o != null) body['sortOrder'] = o;
    try {
      await widget.lessonDs.updateSection(widget.courseId, id, body, widget.token);
      _applyUpdateSection(id, {'title': t, if (o != null) 'sortOrder': o});
      _showSuccess('Section updated!');
    } catch (e) {
      _showError('Update failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _deleteSection(Map<String, dynamic> section) async {
    final id = _id(section);
    final title = (section['title'] ?? 'this section').toString();
    if (id.isEmpty) return;
    final ok = await _confirmDelete('"$title" and all its lessons');
    if (ok != true) return;
    try {
      await widget.lessonDs.deleteSection(widget.courseId, id, widget.token);
      _applyDeleteSection(id);
      _showSuccess('Section deleted.');
    } catch (e) {
      _showError('Delete failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ── Lesson CRUD ──────────────────────────────────────────────────────────────

  Future<void> _addLesson(Map<String, dynamic> section) async {
    final sectionId = _id(section);
    if (sectionId.isEmpty) return;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final ok = await _showFieldDialog(
      title: 'Add Lesson',
      icon: Icons.playlist_add_outlined,
      color: Colors.green[700]!,
      fields: [
        _DialogField('Lesson Title', Icons.title_rounded, titleCtrl),
        _DialogField('Description (optional)', Icons.notes_rounded, contentCtrl, maxLines: 3),
      ],
    );
    if (ok != true) return;
    final t = titleCtrl.text.trim();
    if (t.isEmpty) return;
    final lessons = (section['lessons'] as List? ?? []);
    final body = <String, dynamic>{
      'title': t,
      'sortOrder': lessons.length + 1,
    };
    final c = contentCtrl.text.trim();
    if (c.isNotEmpty) body['content'] = c;
    try {
      final res = await widget.lessonDs.addLesson(sectionId, body, widget.token);
      _applyAddLesson(sectionId, res, t);
      _showSuccess('Lesson "$t" added! Use the ⋮ menu to upload a video.');
    } catch (e) {
      _showError('Add lesson failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _editLesson(Map<String, dynamic> lesson) async {
    final id = _id(lesson);
    if (id.isEmpty) return;
    final titleCtrl = TextEditingController(text: (lesson['title'] ?? '').toString());
    final contentCtrl = TextEditingController(
        text: (lesson['content'] ?? lesson['description'] ?? '').toString());
    final ok = await _showFieldDialog(
      title: 'Edit Lesson',
      icon: Icons.edit_outlined,
      color: Colors.teal[600]!,
      fields: [
        _DialogField('Title', Icons.title_rounded, titleCtrl),
        _DialogField('Description (optional)', Icons.notes_rounded, contentCtrl, maxLines: 3),
      ],
    );
    if (ok != true) return;
    final t = titleCtrl.text.trim();
    if (t.isEmpty) return;
    final body = <String, dynamic>{'title': t};
    final c = contentCtrl.text.trim();
    if (c.isNotEmpty) body['content'] = c;
    try {
      await widget.lessonDs.updateLesson(id, body, widget.token);
      _applyUpdateLesson(id, {'title': t, if (c.isNotEmpty) 'content': c});
      _showSuccess('Lesson updated!');
    } catch (e) {
      _showError('Update failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final id = _id(lesson);
    final title = (lesson['title'] ?? 'this lesson').toString();
    if (id.isEmpty) return;
    final ok = await _confirmDelete('"$title"');
    if (ok != true) return;
    try {
      await widget.lessonDs.deleteLesson(id, widget.token);
      _applyDeleteLesson(id);
      _showSuccess('Lesson deleted.');
    } catch (e) {
      _showError('Delete failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _uploadVideo(Map<String, dynamic> lesson) async {
    final id = _id(lesson);
    if (id.isEmpty) return;
    final fileResult =
        await FilePicker.pickFiles(type: FileType.video, allowMultiple: false);
    if (fileResult == null || fileResult.files.single.path == null) return;
    if (!mounted) return;
    final filePath = fileResult.files.single.path!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UploadingDialog(),
    );
    _applyUpdateLesson(id, {'videoStatus': 'UPLOADED'});

    try {
      // Step 1: get presigned upload URL + videoId from backend
      final initRes = await widget.videoDs.initiateUpload(id, widget.token, filePath);
      final uploadUrl = (initRes['uploadUrl'] ?? '').toString();
      final videoId = (initRes['videoId'] ?? initRes['id'] ?? '').toString();
      if (uploadUrl.isEmpty || videoId.isEmpty) {
        throw Exception('Invalid response from server (missing uploadUrl or videoId)');
      }

      // Step 2: PUT raw bytes directly to MinIO (no auth header)
      await widget.videoDs.uploadToStorage(uploadUrl, filePath);

      // Step 3: notify backend to start processing
      await widget.videoDs.completeUpload(videoId, widget.token);

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Cache immediately so _load() always shows correct status if user navigates away
      _applyUpdateLesson(id, {'videoStatus': 'PROCESSING', 'videoId': videoId});

      if (mounted) {
        final result = await showDialog<Map?>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _VideoProcessingDialog(videoId: videoId, token: widget.token),
        );
        final status = result?['status']?.toString();
        final thumb = result?['thumbnailUrl']?.toString();
        if (status == 'READY') {
          _applyUpdateLesson(id, {
            'videoStatus': 'READY',
            'videoId': videoId,
            if (thumb != null && thumb.isNotEmpty) 'thumbnailUrl': thumb,
          });
          _showSuccess('Video is ready! Students can now watch this lesson.');
        } else if (status == 'PENDING_REVIEW') {
          _applyUpdateLesson(id, {
            'videoStatus': 'PENDING_REVIEW',
            'videoId': videoId,
            if (thumb != null && thumb.isNotEmpty) 'thumbnailUrl': thumb,
          });
          _showSuccess('Video submitted for admin review. It will be available once approved.');
        } else if (status == 'FAILED') {
          _applyUpdateLesson(id, {'videoStatus': 'FAILED', 'videoId': videoId});
          _showError('Video processing failed. Please try uploading again.');
        } else {
          // null = user dismissed dialog while still processing
          _applyUpdateLesson(id, {'videoStatus': 'PROCESSING', 'videoId': videoId});
          _showSuccess('Processing continues in the background. Use "Check Status" on the lesson to see when it\'s ready.');
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _applyUpdateLesson(id, {'videoStatus': ''});
      _showError('Upload failed: ${e.toString().replaceFirst('ApiException: ', '')}');
    }
  }

  Future<void> _checkVideoStatus(Map<String, dynamic> lesson) async {
    final id = _id(lesson);
    final videoId = (lesson['videoId'] ?? '').toString();
    if (videoId.isEmpty) {
      _showError('No video ID — please re-upload the video.');
      return;
    }
    if (!mounted) return;
    final result = await showDialog<Map?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VideoProcessingDialog(videoId: videoId, token: widget.token),
    );
    final status = result?['status']?.toString();
    final thumb = result?['thumbnailUrl']?.toString();
    if (status == 'READY') {
      _applyUpdateLesson(id, {
        'videoStatus': 'READY',
        if (thumb != null && thumb.isNotEmpty) 'thumbnailUrl': thumb,
      });
      _showSuccess('Video is ready! Students can now watch this lesson.');
    } else if (status == 'PENDING_REVIEW') {
      _applyUpdateLesson(id, {
        'videoStatus': 'PENDING_REVIEW',
        if (thumb != null && thumb.isNotEmpty) 'thumbnailUrl': thumb,
      });
      _showSuccess('Awaiting admin approval.');
    } else if (status == 'FAILED') {
      _applyUpdateLesson(id, {'videoStatus': 'FAILED'});
      _showError('Video processing failed. Please re-upload.');
    } else {
      _applyUpdateLesson(id, {'videoStatus': 'PROCESSING'});
    }
  }

  Future<void> _manageQuiz(Map<String, dynamic> lesson) async {
    final id = _id(lesson);
    final title = (lesson['title'] ?? 'Lesson').toString();
    if (id.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => InstructorQuizScreen(lessonId: id, lessonTitle: title),
    ));
  }

  // ── Shared dialogs ───────────────────────────────────────────────────────────

  Future<bool?> _confirmDelete(String what) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('$what will be permanently deleted.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  Future<bool?> _showFieldDialog({
    required String title,
    required IconData icon,
    required Color color,
    required List<_DialogField> fields,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: _kNavy)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: f.controller,
                          keyboardType: f.isNumber
                              ? TextInputType.number
                              : TextInputType.multiline,
                          maxLines: f.maxLines,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: f.label,
                            prefixIcon: Icon(f.icon, size: 18, color: _kBlue),
                            filled: true,
                            fillColor: const Color(0xFFF0F4FF),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: _kNavy, width: 1.5)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black45))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Course Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(widget.courseTitle,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSection,
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Section', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const LessonListSkeleton()
          : _error != null
              ? _buildError()
              : _sections.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kNavy,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                        itemCount: _sections.length,
                        itemBuilder: (_, i) => _SectionTile(
                          section: _sections[i],
                          sectionIndex: i,
                          onEditSection: () => _editSection(_sections[i]),
                          onDeleteSection: () => _deleteSection(_sections[i]),
                          onAddLesson: () => _addLesson(_sections[i]),
                          onEditLesson: _editLesson,
                          onDeleteLesson: _deleteLesson,
                          onUploadVideo: _uploadVideo,
                          onCheckStatus: _checkVideoStatus,
                          onManageQuiz: _manageQuiz,
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration:
                    BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
              ),
              const SizedBox(height: 20),
              const Text('Failed to load content',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kNavy)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: _kNavy.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(Icons.auto_stories_outlined,
                size: 56, color: _kNavy.withValues(alpha: 0.45)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Build your course curriculum',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: _kNavy)),
        const SizedBox(height: 8),
        Text(
          'Your course has no content yet.\nFollow these steps to add it:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        // Step-by-step guide
        _StepCard(
          step: 1,
          icon: Icons.add_box_outlined,
          color: _kBlue,
          title: 'Add a Section',
          body: 'Sections group related lessons — e.g. "Introduction", "Chapter 1". '
              'Tap the blue "Add Section" button at the bottom of this screen.',
        ),
        _StepCard(
          step: 2,
          icon: Icons.playlist_add_outlined,
          color: Colors.green[700]!,
          title: 'Add Lessons to each Section',
          body: 'After adding a section, tap "Add Lesson" inside it. '
              'Give the lesson a title and optional description.',
        ),
        _StepCard(
          step: 3,
          icon: Icons.video_file_outlined,
          color: Colors.purple[700]!,
          title: 'Upload a Video',
          body: 'Tap the ⋮ menu on any lesson and choose "Upload Video". '
              'Pick a video file — the app will upload and process it automatically.',
        ),
        _StepCard(
          step: 4,
          icon: Icons.quiz_outlined,
          color: Colors.indigo[700]!,
          title: 'Add a Quiz (optional)',
          body: 'Use the ⋮ menu → "Manage Quiz" to add questions and test student knowledge.',
        ),
        const SizedBox(height: 24),
        // CTA button
        GestureDetector(
          onTap: _addSection,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D1B6E), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: _kNavy.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5))
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Add First Section',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _StepCard({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text('$step',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color)),
                ]),
                const SizedBox(height: 6),
                Text(body,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey.shade500,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogField {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isNumber;
  final int maxLines;
  const _DialogField(this.label, this.icon, this.controller,
      {this.isNumber = false, this.maxLines = 1});
}

// ── Section tile (expandable) ─────────────────────────────────────────────────

class _SectionTile extends StatefulWidget {
  final Map<String, dynamic> section;
  final int sectionIndex;
  final VoidCallback onEditSection;
  final VoidCallback onDeleteSection;
  final VoidCallback onAddLesson;
  final void Function(Map<String, dynamic>) onEditLesson;
  final void Function(Map<String, dynamic>) onDeleteLesson;
  final void Function(Map<String, dynamic>) onUploadVideo;
  final void Function(Map<String, dynamic>) onCheckStatus;
  final void Function(Map<String, dynamic>) onManageQuiz;

  const _SectionTile({
    required this.section,
    required this.sectionIndex,
    required this.onEditSection,
    required this.onDeleteSection,
    required this.onAddLesson,
    required this.onEditLesson,
    required this.onDeleteLesson,
    required this.onUploadVideo,
    required this.onCheckStatus,
    required this.onManageQuiz,
  });

  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  bool _expanded = true;

  String get _title => (widget.section['title'] ?? 'Untitled Section').toString();

  List<Map<String, dynamic>> get _lessons {
    final l = widget.section['lessons'];
    if (l is List) return l.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _kNavy.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Section header ─────────────────────────────────────
            Material(
              color: const Color(0xFFF0F4FF),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: _kNavy, borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text('${widget.sectionIndex + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _kNavy),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${lessons.length} lesson${lessons.length == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: Colors.blueGrey.shade400,
                        onPressed: widget.onEditSection,
                        tooltip: 'Edit section',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: Colors.red.shade300,
                        onPressed: widget.onDeleteSection,
                        tooltip: 'Delete section',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 22, color: Colors.blueGrey.shade400),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Lessons (collapsible) ──────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _expanded
                  ? Column(
                      key: const ValueKey('expanded'),
                      children: [
                        const Divider(height: 1, indent: 14, endIndent: 14),
                        if (lessons.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 20),
                            child: Text(
                              'No lessons yet — tap below to add one.',
                              style: TextStyle(
                                  color: Colors.blueGrey.shade300, fontSize: 13),
                            ),
                          ),
                        ...lessons.map((l) => _LessonRow(
                              lesson: l,
                              onEdit: () => widget.onEditLesson(l),
                              onDelete: () => widget.onDeleteLesson(l),
                              onUploadVideo: () => widget.onUploadVideo(l),
                              onCheckStatus: () => widget.onCheckStatus(l),
                              onManageQuiz: () => widget.onManageQuiz(l),
                            )),
                        // Add lesson button
                        InkWell(
                          onTap: widget.onAddLesson,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    size: 17,
                                    color: _kBlue.withValues(alpha: 0.8)),
                                const SizedBox(width: 6),
                                Text('Add Lesson',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kBlue.withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('collapsed')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lesson row with popup menu ────────────────────────────────────────────────

class _LessonRow extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUploadVideo;
  final VoidCallback onCheckStatus;
  final VoidCallback onManageQuiz;

  const _LessonRow({
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
    required this.onUploadVideo,
    required this.onCheckStatus,
    required this.onManageQuiz,
  });

  String get _title => (lesson['title'] ?? 'Untitled').toString();
  String get _status =>
      (lesson['videoStatus'] ?? '').toString().toUpperCase();

  Color get _statusColor {
    switch (_status) {
      case 'READY':          return Colors.green[700]!;
      case 'PROCESSING':     return Colors.orange[700]!;
      case 'UPLOADED':       return Colors.blue[600]!;
      case 'PENDING_REVIEW': return Colors.purple[600]!;
      case 'FAILED':         return Colors.red[600]!;
      default:               return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'READY':          return Icons.play_circle_outline_rounded;
      case 'PROCESSING':     return Icons.hourglass_top_rounded;
      case 'UPLOADED':       return Icons.cloud_done_outlined;
      case 'PENDING_REVIEW': return Icons.pending_outlined;
      case 'FAILED':         return Icons.error_outline_rounded;
      default:               return Icons.videocam_off_outlined;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'READY':          return 'Ready';
      case 'PROCESSING':     return 'Processing…';
      case 'UPLOADED':       return 'Upload received';
      case 'PENDING_REVIEW': return 'Awaiting admin approval';
      case 'FAILED':         return 'Processing failed — tap ⋮ to retry';
      default:               return 'No video uploaded';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon, size: 16, color: _statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(_statusLabel,
                        style: TextStyle(fontSize: 11, color: _statusColor)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: Colors.grey.shade500),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (v) {
                  switch (v) {
                    case 'edit': onEdit(); break;
                    case 'upload': onUploadVideo(); break;
                    case 'check': onCheckStatus(); break;
                    case 'quiz': onManageQuiz(); break;
                    case 'delete': onDelete(); break;
                  }
                },
                itemBuilder: (_) => [
                  _item('edit', Icons.edit_outlined, 'Edit Title', Colors.blueGrey.shade700),
                  if (_status == 'PROCESSING' || _status == 'UPLOADED' || _status == 'PENDING_REVIEW')
                    _item('check', Icons.refresh_rounded, 'Check Status', Colors.orange[700]!),
                  _item('upload', Icons.video_file_outlined,
                      _status == 'FAILED' ? 'Retry Upload' : 'Upload Video',
                      _status == 'FAILED' ? Colors.red[600]! : Colors.purple[700]!),
                  _item('quiz', Icons.quiz_outlined, 'Manage Quiz', Colors.indigo[700]!),
                  _item('delete', Icons.delete_outline_rounded, 'Delete', Colors.red[600]!),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _item(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Upload progress spinner ───────────────────────────────────────────────────

class _UploadingDialog extends StatelessWidget {
  const _UploadingDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kNavy),
            SizedBox(width: 20),
            Expanded(
              child: Text('Uploading video…',
                  style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video processing polling dialog ──────────────────────────────────────────

class _VideoProcessingDialog extends StatefulWidget {
  final String videoId;
  final String token;

  const _VideoProcessingDialog({
    required this.videoId,
    required this.token,
  });

  @override
  State<_VideoProcessingDialog> createState() => _VideoProcessingDialogState();
}

class _VideoProcessingDialogState extends State<_VideoProcessingDialog> {
  Timer? _timer;
  String _status = 'UPLOADED';
  double _progress = 0;
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _poll(); // immediate first check
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final data = await VideoProcessingRemoteDataSource()
          .getVideoStatus(widget.videoId, widget.token);
      if (!mounted) return;
      final status = (data['status'] ?? 'PROCESSING').toString();
      final progress = (data['progress'] as num?)?.toDouble() ?? 0;
      final thumb = (data['thumbnailUrl'] ?? data['thumbnail'] ?? '').toString();
      setState(() {
        _status = status;
        _progress = progress;
        if (thumb.isNotEmpty) _thumbnailUrl = thumb;
      });
      if (status == 'READY' || status == 'PENDING_REVIEW' || status == 'FAILED') {
        _timer?.cancel();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pop({'status': status, 'thumbnailUrl': _thumbnailUrl});
        }
      }
    } catch (_) {
      // keep polling on transient errors
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'UPLOADED':
        return 'Video uploaded, waiting to process…';
      case 'PROCESSING':
        return 'Processing video… ${_progress.toStringAsFixed(0)}%';
      case 'PENDING_REVIEW':
        return 'Awaiting admin approval…';
      case 'READY':
        return 'Video is ready!';
      case 'FAILED':
        return 'Processing failed.';
      default:
        return 'Processing…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone =
        _status == 'READY' || _status == 'PENDING_REVIEW' || _status == 'FAILED';
    final isFailed = _status == 'FAILED';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isFailed
                ? Icons.error_outline
                : isDone
                    ? Icons.check_circle_outline
                    : Icons.video_file_outlined,
            color: isFailed
                ? Colors.red[700]
                : isDone
                    ? Colors.green[700]
                    : _kNavy,
          ),
          const SizedBox(width: 10),
          const Text('Processing Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_statusLabel,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isDone ? 1.0 : (_status == 'UPLOADED' ? null : _progress / 100),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isFailed ? Colors.red[400]! : _kNavy,
              ),
            ),
          ),
          if (!isDone) ...[
            const SizedBox(height: 12),
            const Text(
              'You can close this dialog — processing continues in the background.',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ],
      ),
      actions: [
        if (!isDone)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Close', style: TextStyle(color: Colors.black45)),
          ),
      ],
    );
  }
}
