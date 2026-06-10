import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../constants/api_constants.dart';
import '../../../core/secure_storage.dart';
import '../../../data/datasources/course_remote_data_source.dart';
import '../../../data/datasources/lesson_remote_data_source.dart';
import '../../../data/datasources/video_processing_remote_data_source.dart';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Please login again to manage your courses.';
      });
      return;
    }
    _token = token; // store token immediately so create/edit works even if list fails
    try {
      final courses = await _courseDs.fetchInstructorCourses(token);
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
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

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentMenuSheet(
        courseTitle: _courseTitle(course),
        courseId: courseId,
        token: _token!,
        lessonDs: _lessonDs,
        videoDs: _videoDs,
        onMessage: (msg) => _showSuccess(msg),
        onError: (msg) => _showError(msg),
      ),
    );
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
                ? const Center(child: CircularProgressIndicator(color: _kNavy))
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
                        coursePrice == 0 ? 'Free' : '\$${coursePrice.toStringAsFixed(2)}',
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
    final price = _isFree ? 0.0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0.0);
    final thumb = _thumbnailCtrl.text.trim();
    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'categoryId': _selectedCategoryId,
      'level': _levelApiValues[_selectedLevel] ?? _selectedLevel.toUpperCase(),
      'language': 'en',
      'price': price,
      'currency': 'USD',
      'requirements': _requirements,
      'objectives': _objectives,
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
                child: const Text('USD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
              ),
              hintText: '0.00',
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
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _FormField({required this.controller, required this.label, required this.hint, required this.icon, this.maxLines = 1, this.keyboardType, this.validator});

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
          keyboardType: keyboardType,
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

// ── Content Management Sheet ──────────────────────────────────────────────────

class _ContentMenuSheet extends StatelessWidget {
  final String courseTitle;
  final String courseId;
  final String token;
  final LessonRemoteDataSource lessonDs;
  final VideoProcessingRemoteDataSource videoDs;
  final void Function(String) onMessage;
  final void Function(String) onError;

  const _ContentMenuSheet({
    required this.courseTitle,
    required this.courseId,
    required this.token,
    required this.lessonDs,
    required this.videoDs,
    required this.onMessage,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
         child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_open_rounded, color: _kNavy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Manage Content',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _kNavy)),
                        Text(courseTitle,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            _ContentItem(
              icon: Icons.add_box_outlined,
              label: 'Add Section',
              color: _kBlue,
              onTap: () async {
                Navigator.pop(context);
                await _addSection(context);
              },
            ),
            _ContentItem(
              icon: Icons.playlist_add_outlined,
              label: 'Add Lesson',
              color: Colors.green[700]!,
              onTap: () async {
                Navigator.pop(context);
                await _addLesson(context);
              },
            ),
            _ContentItem(
              icon: Icons.video_file_outlined,
              label: 'Upload Lesson Video',
              color: Colors.purple[700]!,
              onTap: () async {
                Navigator.pop(context);
                await _uploadVideo(context);
              },
            ),
            _ContentItem(
              icon: Icons.edit_note_outlined,
              label: 'Update Section',
              color: Colors.orange[700]!,
              onTap: () async {
                Navigator.pop(context);
                await _updateSection(context);
              },
            ),
            _ContentItem(
              icon: Icons.edit_outlined,
              label: 'Update Lesson',
              color: Colors.teal[600]!,
              onTap: () async {
                Navigator.pop(context);
                await _updateLesson(context);
              },
            ),
            _ContentItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Section',
              color: Colors.red[600]!,
              onTap: () async {
                Navigator.pop(context);
                await _deleteSection(context);
              },
            ),
            _ContentItem(
              icon: Icons.delete_forever_outlined,
              label: 'Delete Lesson',
              color: Colors.red[800]!,
              onTap: () async {
                Navigator.pop(context);
                await _deleteLesson(context);
              },
            ),
            const SizedBox(height: 12),
          ],
         ),
        ),
      ),
    );
  }

  Future<void> _addSection(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Add Section', [
      _FI('Section Title', Icons.title_rounded),
      _FI('Order (number)', Icons.sort_rounded, isNumber: true),
    ]);
    if (result == null) return;
    try {
      await lessonDs.addSection(courseId, result, token);
      onMessage('Section added!');
    } catch (e) {
      onError('Add section failed: $e');
    }
  }

  Future<void> _updateSection(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Update Section', [
      _FI('Section ID', Icons.tag_rounded),
      _FI('New Title', Icons.title_rounded),
    ]);
    if (result == null) return;
    final sectionId = result.remove('sectionId')?.toString() ??
        result.remove('Section ID')?.toString() ?? '';
    if (sectionId.isEmpty) return;
    try {
      await lessonDs.updateSection(courseId, sectionId, result, token);
      onMessage('Section updated!');
    } catch (e) {
      onError('Update section failed: $e');
    }
  }

  Future<void> _deleteSection(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Delete Section', [
      _FI('Section ID', Icons.tag_rounded),
    ]);
    if (result == null) return;
    final sectionId = result['sectionId']?.toString() ??
        result['Section ID']?.toString() ?? '';
    if (sectionId.isEmpty) return;
    try {
      await lessonDs.deleteSection(courseId, sectionId, token);
      onMessage('Section deleted.');
    } catch (e) {
      onError('Delete section failed: $e');
    }
  }

  Future<void> _addLesson(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Add Lesson', [
      _FI('Section ID', Icons.tag_rounded),
      _FI('Lesson Title', Icons.title_rounded),
      _FI('Content', Icons.notes_rounded),
    ]);
    if (result == null) return;
    final sectionId = result.remove('sectionId')?.toString() ??
        result.remove('Section ID')?.toString() ?? '';
    if (sectionId.isEmpty) return;
    try {
      await lessonDs.addLesson(sectionId, result, token);
      onMessage('Lesson added!');
    } catch (e) {
      onError('Add lesson failed: $e');
    }
  }

  Future<void> _updateLesson(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Update Lesson', [
      _FI('Lesson ID', Icons.tag_rounded),
      _FI('New Title', Icons.title_rounded),
      _FI('Content', Icons.notes_rounded),
    ]);
    if (result == null) return;
    final lessonId = result.remove('lessonId')?.toString() ??
        result.remove('Lesson ID')?.toString() ?? '';
    if (lessonId.isEmpty) return;
    try {
      await lessonDs.updateLesson(lessonId, result, token);
      onMessage('Lesson updated!');
    } catch (e) {
      onError('Update lesson failed: $e');
    }
  }

  Future<void> _deleteLesson(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Delete Lesson', [
      _FI('Lesson ID', Icons.tag_rounded),
    ]);
    if (result == null) return;
    final lessonId = result['lessonId']?.toString() ??
        result['Lesson ID']?.toString() ?? '';
    if (lessonId.isEmpty) return;
    try {
      await lessonDs.deleteLesson(lessonId, token);
      onMessage('Lesson deleted.');
    } catch (e) {
      onError('Delete lesson failed: $e');
    }
  }

  Future<void> _uploadVideo(BuildContext ctx) async {
    final result = await _showSimpleForm(ctx, 'Upload Video', [
      _FI('Lesson ID (optional)', Icons.tag_rounded),
    ]);
    if (result == null) return;
    final lessonId = result['lessonId']?.toString() ??
        result['Lesson ID (optional)']?.toString() ?? '';

    final fileResult = await FilePicker.pickFiles(
        type: FileType.video, allowMultiple: false);
    if (fileResult == null || fileResult.files.single.path == null) return;

    try {
      await videoDs.uploadLessonVideo(
        fileResult.files.single.path!,
        token,
        lessonId: lessonId.isEmpty ? null : lessonId,
      );
      onMessage('Video uploaded!');
    } catch (e) {
      onError('Upload failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _showSimpleForm(
    BuildContext ctx,
    String title,
    List<_FI> fields,
  ) {
    final controllers = {for (final f in fields) f.label: TextEditingController()};

    return showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: _kNavy)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[f.label],
                  keyboardType: f.isNumber
                      ? TextInputType.number
                      : TextInputType.text,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: f.label,
                    prefixIcon: Icon(f.icon, size: 18, color: _kBlue),
                    filled: true,
                    fillColor: const Color(0xFFF0F4FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kNavy, width: 1.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final result = <String, dynamic>{};
              for (final f in fields) {
                final val = controllers[f.label]!.text.trim();
                if (val.isNotEmpty) {
                  final camelKey = f.label
                      .split(' ')
                      .first
                      .toLowerCase()
                      .replaceAll(RegExp(r'\(.*\)'), '')
                      .trim();
                  final numeric = num.tryParse(val);
                  result[camelKey] = numeric ?? val;
                }
              }
              Navigator.pop(dialogCtx, result);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ContentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContentItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
    );
  }
}

class _FI {
  final String label;
  final IconData icon;
  final bool isNumber;
  const _FI(this.label, this.icon, {this.isNumber = false});
}
