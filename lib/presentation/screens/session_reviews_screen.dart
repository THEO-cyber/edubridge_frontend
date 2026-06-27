import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/admin_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);

class SessionReviewsScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const SessionReviewsScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<SessionReviewsScreen> createState() => _SessionReviewsScreenState();
}

class _SessionReviewsScreenState extends State<SessionReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await SecureStorage.getToken() ?? '';
      final reviews = await AdminRemoteDataSource()
          .fetchSessionReviews(widget.sessionId, token);
      if (mounted) setState(() { _reviews = reviews; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  double get _avg {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<num>(0, (s, r) => s + ((r['rating'] as num?) ?? 0));
    return sum / _reviews.length;
  }

  String _name(Map<String, dynamic> r) {
    final u = r['user'] as Map<String, dynamic>?;
    if (u == null) return 'Student';
    final username = (u['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;
    return '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim().isNotEmpty
        ? '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim()
        : 'Student';
  }

  Color _color(String name) {
    const p = [Color(0xFF37474F), Color(0xFF00695C), Color(0xFF283593), Color(0xFF4A148C)];
    return name.isEmpty ? p[0] : p[name.codeUnitAt(0) % p.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _date(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Session Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(widget.sessionTitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis),
        ]),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                        child: const Text('Retry')),
                  ]),
                ))
              : _reviews.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: Colors.black26),
                      SizedBox(height: 16),
                      Text('No reviews for this session yet.',
                          style: TextStyle(color: Colors.black45, fontSize: 15)),
                    ]))
                  : _buildList(),
    );
  }

  Widget _buildList() {
    return Column(children: [
      // Summary bar
      Container(
        color: _kNavy,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(children: [
          Text(_avg.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: List.generate(5, (i) => Icon(
              i < _avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber, size: 18,
            ))),
            const SizedBox(height: 2),
            Text('${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reviews.length,
          itemBuilder: (_, i) {
            final r = _reviews[i];
            final name = _name(r);
            final rating = (r['rating'] as num?)?.toInt() ?? 0;
            final content = (r['content'] ?? r['comment'] ?? '').toString().trim();
            final date = _date(r['createdAt']?.toString());
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _color(name),
                    child: Text(_initials(name),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis)),
                      Text(date, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: List.generate(5, (j) => Icon(
                      j < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 15,
                    ))),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(content,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                    ],
                  ])),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
