import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/discussions_remote_data_source.dart';

class CourseDiscussionsScreen extends StatefulWidget {
  final String courseId;

  const CourseDiscussionsScreen({super.key, required this.courseId});

  @override
  State<CourseDiscussionsScreen> createState() =>
      _CourseDiscussionsScreenState();
}

class _CourseDiscussionsScreenState extends State<CourseDiscussionsScreen> {
  final _ds = DiscussionsRemoteDataSource();
  String? _token;
  List<dynamic> _threads = [];
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
    final threads =
        await _ds.getCourseDiscussions(widget.courseId, _token!);
    if (mounted) {
      setState(() {
        _threads = threads;
        _loading = false;
      });
    }
  }

  void _showNewThreadDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ask a Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Question title',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    border: OutlineInputBorder()),
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
              if (titleCtrl.text.trim().isEmpty) return;
              try {
                final thread = await _ds.createThread(
                    widget.courseId,
                    titleCtrl.text.trim(),
                    contentCtrl.text.trim(),
                    _token!);
                setState(() => _threads.insert(0, thread));
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Failed to post question'),
                      backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Q&A / Discussions'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewThreadDialog,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.help_outline),
        label: const Text('Ask'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _threads.length,
                    itemBuilder: (_, i) => _buildThreadCard(_threads[i]),
                  ),
                ),
    );
  }

  Widget _buildThreadCard(Map<String, dynamic> t) {
    final title = t['title'] ?? '';
    final content = t['content'] ?? '';
    final replyCount = t['replyCount'] ?? 0;
    final isAnswered = t['isAnswered'] ?? false;
    final author = t['author']?['name'] ?? t['authorName'] ?? 'Student';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ThreadDetailScreen(
              thread: t, token: _token!, ds: _ds),
        ),
      ).then((_) => _load()),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isAnswered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Answered',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  if (isAnswered) const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.blueGrey.shade600, fontSize: 13)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(author,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueGrey)),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline,
                      size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text('$replyCount replies',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined,
                size: 56, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text('No questions yet. Be the first to ask!',
                style: TextStyle(color: Colors.blueGrey.shade500)),
          ],
        ),
      );
}

class _ThreadDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  final String token;
  final DiscussionsRemoteDataSource ds;

  const _ThreadDetailScreen(
      {required this.thread, required this.token, required this.ds});

  @override
  State<_ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<_ThreadDetailScreen> {
  final _replyCtrl = TextEditingController();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail =
          await widget.ds.getThread(widget.thread['id'], widget.token);
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postReply() async {
    final content = _replyCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _posting = true);
    try {
      await widget.ds
          .replyToThread(widget.thread['id'], content, widget.token);
      _replyCtrl.clear();
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to post reply'),
            backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _detail?['title'] ?? widget.thread['title'] ?? '';
    final replies = (_detail?['replies'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPost(
                          _detail ?? widget.thread, isOriginal: true),
                      if (replies.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Replies',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blueGrey)),
                        ),
                        ...replies.map((r) => _buildPost(r)),
                      ],
                    ],
                  ),
                ),
                _buildReplyBar(),
              ],
            ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post, {bool isOriginal = false}) {
    final content = post['content'] ?? '';
    final author =
        post['author']?['name'] ?? post['authorName'] ?? 'User';
    final isAnswered = post['isAnswer'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOriginal
            ? const Color(0xFF1A237E).withValues(alpha: 0.04)
            : isAnswered
                ? Colors.green.withValues(alpha: 0.06)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswered ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF1A237E),
                child: Text(author.isNotEmpty ? author[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(author,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              if (isAnswered) ...[
                const Spacer(),
                const Icon(Icons.verified,
                    color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text('Answer',
                    style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildReplyBar() => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _posting ? null : _postReply,
              icon: _posting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: Color(0xFF1A237E)),
            ),
          ],
        ),
      );
}
