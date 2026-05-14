import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/secure_storage.dart';
import '../../../data/datasources/course_remote_data_source.dart';
import '../../../data/datasources/lesson_remote_data_source.dart';
import '../../../data/datasources/video_processing_remote_data_source.dart';

class LecturerCourseManagementScreen extends StatefulWidget {
  const LecturerCourseManagementScreen({super.key});

  @override
  State<LecturerCourseManagementScreen> createState() =>
      _LecturerCourseManagementScreenState();
}

class _LecturerCourseManagementScreenState
    extends State<LecturerCourseManagementScreen> {
  final CourseRemoteDataSource _courseRemoteDataSource =
      CourseRemoteDataSource();
  final LessonRemoteDataSource _lessonRemoteDataSource =
      LessonRemoteDataSource();
  final VideoProcessingRemoteDataSource _videoProcessingRemoteDataSource =
      VideoProcessingRemoteDataSource();

  bool _isLoading = true;
  String? _token;
  String? _error;
  List<Map<String, dynamic>> _courses = [];

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

    try {
      final courses = await _courseRemoteDataSource.fetchInstructorCourses(
        token,
      );
      if (!mounted) return;
      setState(() {
        _token = token;
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _courseId(Map<String, dynamic> course) =>
      (course['id'] ?? course['_id'] ?? '').toString();

  String _courseTitle(Map<String, dynamic> course) =>
      (course['title'] ?? 'Untitled course').toString();

  String _courseDescription(Map<String, dynamic> course) =>
      (course['description'] ?? '').toString();

  bool _isPublished(Map<String, dynamic> course) =>
      course['isPublished'] == true || course['published'] == true;

  Future<void> _createCourse() async {
    if (_token == null) return;
    final form = await _showCourseForm();
    if (form == null) return;
    try {
      await _courseRemoteDataSource.createCourse(form, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully.')),
      );
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    }
  }

  Future<void> _updateCourse(Map<String, dynamic> course) async {
    if (_token == null) return;
    final id = _courseId(course);
    if (id.isEmpty) return;
    final form = await _showCourseForm(initial: course);
    if (form == null) return;
    try {
      await _courseRemoteDataSource.updateCourse(id, form, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully.')),
      );
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _publishCourse(Map<String, dynamic> course) async {
    if (_token == null) return;
    final id = _courseId(course);
    if (id.isEmpty) return;
    try {
      await _courseRemoteDataSource.publishCourse(id, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course submitted for review.')),
      );
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    }
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    if (_token == null) return;
    final id = _courseId(course);
    if (id.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('This will delete "${_courseTitle(course)}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _courseRemoteDataSource.deleteCourse(id, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Course deleted.')));
      await _loadCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _manageContent(Map<String, dynamic> course) async {
    final courseId = _courseId(course);
    if (_token == null || courseId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Add Section'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _addSection(courseId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('Update Section'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _updateSection(courseId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Section'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _deleteSection(courseId);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.playlist_add_outlined),
                title: const Text('Add Lesson'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _addLesson();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Update Lesson'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _updateLesson();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Delete Lesson'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _deleteLesson();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.video_file_outlined),
                title: const Text('Upload Lesson Video'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _uploadLessonVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showCourseForm({
    Map<String, dynamic>? initial,
  }) async {
    final titleController = TextEditingController(
      text: (initial?['title'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (initial?['description'] ?? '').toString(),
    );
    final categoryController = TextEditingController(
      text: (initial?['category'] ?? 'General').toString(),
    );
    final levelController = TextEditingController(
      text: (initial?['level'] ?? 'Beginner').toString(),
    );
    final priceController = TextEditingController(
      text: ((initial?['price'] ?? 0).toString()),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initial == null ? 'Create Course' : 'Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: levelController,
                  decoration: const InputDecoration(labelText: 'Level'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': categoryController.text.trim().isEmpty
                      ? 'General'
                      : categoryController.text.trim(),
                  'level': levelController.text.trim().isEmpty
                      ? 'Beginner'
                      : levelController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    levelController.dispose();
    priceController.dispose();

    return result;
  }

  Future<void> _addSection(String courseId) async {
    if (_token == null) return;
    final titleController = TextEditingController();
    final sectionOrderController = TextEditingController();
    final payload = await _showPayloadDialog(
      title: 'Add Section',
      fields: [
        _DialogField('title', titleController),
        _DialogField('order', sectionOrderController),
      ],
    );
    titleController.dispose();
    sectionOrderController.dispose();
    if (payload == null) return;

    try {
      await _lessonRemoteDataSource.addSection(courseId, payload, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Section added.')));
    } catch (e) {
      _showError('Add section failed: $e');
    }
  }

  Future<void> _updateSection(String courseId) async {
    if (_token == null) return;
    final sectionIdController = TextEditingController();
    final titleController = TextEditingController();
    final payload = await _showPayloadDialog(
      title: 'Update Section',
      fields: [
        _DialogField('sectionId', sectionIdController),
        _DialogField('title', titleController),
      ],
    );
    final sectionId = sectionIdController.text.trim();
    sectionIdController.dispose();
    titleController.dispose();
    if (payload == null || sectionId.isEmpty) return;

    try {
      payload.remove('sectionId');
      await _lessonRemoteDataSource.updateSection(
        courseId,
        sectionId,
        payload,
        _token!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Section updated.')));
    } catch (e) {
      _showError('Update section failed: $e');
    }
  }

  Future<void> _deleteSection(String courseId) async {
    if (_token == null) return;
    final sectionIdController = TextEditingController();
    final result = await _showPayloadDialog(
      title: 'Delete Section',
      fields: [_DialogField('sectionId', sectionIdController)],
    );
    final sectionId = sectionIdController.text.trim();
    sectionIdController.dispose();
    if (result == null || sectionId.isEmpty) return;

    try {
      await _lessonRemoteDataSource.deleteSection(courseId, sectionId, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Section deleted.')));
    } catch (e) {
      _showError('Delete section failed: $e');
    }
  }

  Future<void> _addLesson() async {
    if (_token == null) return;
    final sectionIdController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final payload = await _showPayloadDialog(
      title: 'Add Lesson',
      fields: [
        _DialogField('sectionId', sectionIdController),
        _DialogField('title', titleController),
        _DialogField('content', contentController),
      ],
    );

    final sectionId = sectionIdController.text.trim();
    sectionIdController.dispose();
    titleController.dispose();
    contentController.dispose();

    if (payload == null || sectionId.isEmpty) return;

    try {
      payload.remove('sectionId');
      await _lessonRemoteDataSource.addLesson(sectionId, payload, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lesson added.')));
    } catch (e) {
      _showError('Add lesson failed: $e');
    }
  }

  Future<void> _updateLesson() async {
    if (_token == null) return;
    final lessonIdController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final payload = await _showPayloadDialog(
      title: 'Update Lesson',
      fields: [
        _DialogField('lessonId', lessonIdController),
        _DialogField('title', titleController),
        _DialogField('content', contentController),
      ],
    );

    final lessonId = lessonIdController.text.trim();
    lessonIdController.dispose();
    titleController.dispose();
    contentController.dispose();

    if (payload == null || lessonId.isEmpty) return;

    try {
      payload.remove('lessonId');
      await _lessonRemoteDataSource.updateLesson(lessonId, payload, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lesson updated.')));
    } catch (e) {
      _showError('Update lesson failed: $e');
    }
  }

  Future<void> _deleteLesson() async {
    if (_token == null) return;
    final lessonIdController = TextEditingController();
    final result = await _showPayloadDialog(
      title: 'Delete Lesson',
      fields: [_DialogField('lessonId', lessonIdController)],
    );
    final lessonId = lessonIdController.text.trim();
    lessonIdController.dispose();
    if (result == null || lessonId.isEmpty) return;

    try {
      await _lessonRemoteDataSource.deleteLesson(lessonId, _token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lesson deleted.')));
    } catch (e) {
      _showError('Delete lesson failed: $e');
    }
  }

  Future<void> _uploadLessonVideo() async {
    if (_token == null) return;
    final lessonIdController = TextEditingController();
    final result = await _showPayloadDialog(
      title: 'Upload Lesson Video',
      fields: [_DialogField('lessonId (optional)', lessonIdController)],
    );
    final lessonIdText = lessonIdController.text.trim();
    lessonIdController.dispose();
    if (result == null) return;

    final fileResult = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (fileResult == null || fileResult.files.single.path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video selection cancelled.')),
      );
      return;
    }

    final filePath = fileResult.files.single.path!;

    try {
      await _videoProcessingRemoteDataSource.uploadLessonVideo(
        filePath,
        _token!,
        lessonId: lessonIdText.isEmpty ? null : lessonIdText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully.')),
      );
    } catch (e) {
      _showError('Video upload failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _showPayloadDialog({
    required String title,
    required List<_DialogField> fields,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: field.controller,
                        decoration: InputDecoration(labelText: field.label),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = <String, dynamic>{};
                for (final field in fields) {
                  final value = field.controller.text.trim();
                  if (value.isNotEmpty) {
                    final numeric = num.tryParse(value);
                    result[field.label.split(' ').first] = numeric ?? value;
                  }
                }
                Navigator.of(context).pop(result);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadCourses, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCourse,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: _courses.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('No courses yet. Create your first course.'),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final published = _isPublished(course);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _courseTitle(course),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _courseDescription(course),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(published ? 'Published' : 'Draft'),
                                avatar: Icon(
                                  published
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  size: 16,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => _updateCourse(course),
                                child: const Text('Edit'),
                              ),
                              if (!published)
                                ElevatedButton(
                                  onPressed: () => _publishCourse(course),
                                  child: const Text('Publish'),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => _manageContent(course),
                                icon: const Icon(Icons.menu_book),
                                label: const Text('Manage Content'),
                              ),
                              TextButton(
                                onPressed: () => _deleteCourse(course),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _DialogField {
  final String label;
  final TextEditingController controller;

  _DialogField(this.label, this.controller);
}
