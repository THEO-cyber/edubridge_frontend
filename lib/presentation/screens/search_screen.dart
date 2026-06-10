import 'package:flutter/material.dart';
import '../../data/datasources/course_remote_data_source.dart';
import 'course_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _courseDs = CourseRemoteDataSource();
  final _focus = FocusNode();

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await _courseDs.searchCourses(q);
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white70,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            setState(() {});
            if (v.length >= 2) _search(v);
            if (v.isEmpty) _search('');
          },
          onSubmitted: _search,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_searched && _controller.text.isEmpty) {
      return _buildEmptyPrompt();
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _search(_controller.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_searched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.blueGrey.shade300),
            const SizedBox(height: 12),
            Text(
              'No results for "${_controller.text.trim()}"',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try different keywords',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (_, i) => _CourseResultCard(
        course: _results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(
              courseId: (_results[i]['id'] ?? _results[i]['_id'] ?? '').toString(),
              title: (_results[i]['title'] ?? 'Untitled').toString(),
              description: (_results[i]['description'] ?? '').toString(),
              imageUrl: _results[i]['imageUrl']?.toString(),
              price: double.tryParse((_results[i]['price'] ?? 0).toString()) ?? 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.search, size: 64, color: Colors.blueGrey.shade200),
        const SizedBox(height: 16),
        Text(
          'Search for courses',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade400),
        ),
        const SizedBox(height: 8),
        Text(
          'Type at least 2 characters to start searching',
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Popular searches',
                  style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Flutter', 'Python', 'React', 'Data Science',
                    'UI/UX', 'Machine Learning']
                    .map((tag) => ActionChip(
                          label: Text(tag),
                          onPressed: () {
                            _controller.text = tag;
                            _search(tag);
                          },
                          backgroundColor:
                              const Color(0xFF1A237E).withValues(alpha: 0.08),
                          labelStyle: const TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w500),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseResultCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;

  const _CourseResultCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (course['title'] ?? 'Untitled').toString();
    final description = (course['description'] ?? '').toString();
    final instructor = (course['instructor']?['name'] ??
            course['instructorName'] ??
            '')
        .toString();
    final price = (course['price'] ?? 0);
    final level = (course['level'] ?? '').toString();
    final rating = (course['averageRating'] ?? course['rating'] ?? 0.0);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book,
                    color: Color(0xFF1A237E), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (instructor.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text('By $instructor',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (level.isNotEmpty) ...[
                          _tag(level, Colors.blue),
                          const SizedBox(width: 6),
                        ],
                        if (rating is num && rating > 0) ...[
                          const Icon(Icons.star,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          price == 0 ? 'Free' : '₦$price',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: price == 0
                                ? Colors.green
                                : const Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(description,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey.shade400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
