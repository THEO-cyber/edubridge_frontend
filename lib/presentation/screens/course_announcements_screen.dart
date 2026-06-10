import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/announcements_remote_data_source.dart';

class CourseAnnouncementsScreen extends StatefulWidget {
  final String courseId;
  final bool isInstructor;

  const CourseAnnouncementsScreen({
    super.key,
    required this.courseId,
    this.isInstructor = false,
  });

  @override
  State<CourseAnnouncementsScreen> createState() =>
      _CourseAnnouncementsScreenState();
}

class _CourseAnnouncementsScreenState
    extends State<CourseAnnouncementsScreen> {
  final _ds = AnnouncementsRemoteDataSource();
  String? _token;
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _token = await SecureStorage.getToken();
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }
    final list =
        await _ds.getCourseAnnouncements(widget.courseId, _token!);
    if (mounted) {
      setState(() {
        _announcements = list;
        _loading = false;
      });
    }
  }

  void _showCreateDialog({Map<String, dynamic>? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl =
        TextEditingController(text: existing?['content'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'New Announcement' : 'Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Content', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (existing == null) {
                  final a = await _ds.createAnnouncement(
                      widget.courseId,
                      titleCtrl.text.trim(),
                      contentCtrl.text.trim(),
                      _token!);
                  setState(() => _announcements.insert(0, a));
                } else {
                  await _ds.updateAnnouncement(existing['id'],
                      titleCtrl.text.trim(), contentCtrl.text.trim(), _token!);
                  final idx = _announcements
                      .indexWhere((a) => a['id'] == existing['id']);
                  if (idx != -1) {
                    setState(() {
                      _announcements[idx] = {
                        ..._announcements[idx],
                        'title': titleCtrl.text.trim(),
                        'content': contentCtrl.text.trim(),
                      };
                    });
                  }
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Failed to save announcement'),
                      backgroundColor: Colors.red));
                }
              }
            },
            child: Text(existing == null ? 'Post' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.isInstructor
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (_, i) =>
                        _buildCard(_announcements[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final title = a['title'] ?? '';
    final content = a['content'] ?? '';
    final createdAt = a['createdAt'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign,
                      color: Color(0xFF1A237E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (createdAt.isNotEmpty)
                        Text(_formatDate(createdAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400)),
                    ],
                  ),
                ),
                if (widget.isInstructor)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _showCreateDialog(existing: a);
                      if (v == 'delete') _delete(a['id']);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content,
                style: TextStyle(
                    color: Colors.blueGrey.shade700, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    if (_token == null) return;
    await _ds.deleteAnnouncement(id, _token!);
    setState(() => _announcements.removeWhere((a) => a['id'] == id));
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_outlined,
                size: 56, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              widget.isInstructor
                  ? 'No announcements yet. Tap + to post one.'
                  : 'No announcements from your instructor yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade500),
            ),
          ],
        ),
      );
}
