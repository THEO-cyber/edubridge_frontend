import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/review_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);

class PostSessionReviewScreen extends StatefulWidget {
  final String courseId;
  final String? courseTitle;

  const PostSessionReviewScreen({
    super.key,
    required this.courseId,
    this.courseTitle,
  });

  @override
  State<PostSessionReviewScreen> createState() => _PostSessionReviewScreenState();
}

class _PostSessionReviewScreenState extends State<PostSessionReviewScreen> {
  int _selectedRating = 0;
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _done = false;
  String _title = 'Leave a Review';

  @override
  void initState() {
    super.initState();
    if (widget.courseTitle != null && widget.courseTitle!.isNotEmpty) {
      _title = widget.courseTitle!;
    } else {
      _loadTitle();
    }
  }

  Future<void> _loadTitle() async {
    try {
      final token = await SecureStorage.getToken();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.courseDetails(widget.courseId)}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final t = (data['title'] ?? '').toString();
        if (t.isNotEmpty) setState(() => _title = t);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap a star to rate the course')),
      );
      return;
    }
    final token = await SecureStorage.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ReviewRemoteDataSource().postReview(
        widget.courseId,
        _controller.text.trim(),
        _selectedRating,
        token,
      );
      if (mounted) setState(() { _done = true; _submitting = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Session'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
      ),
      body: _done ? _buildThankyou() : _buildForm(),
    );
  }

  Widget _buildThankyou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text('Thank you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kNavy)),
          const SizedBox(height: 12),
          const Text(
            'Your review has been submitted.\nIt helps other students choose the right course.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Course name header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Session completed', style: TextStyle(color: Colors.black45, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kNavy)),
          ]),
        ),
        const SizedBox(height: 28),

        // Star picker
        const Text('How would you rate this course?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _selectedRating = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 48,
              ),
            ),
          )),
        ),
        if (_selectedRating > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_selectedRating],
              style: const TextStyle(color: _kNavy, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 28),

        // Comment
        const Text('Tell us more (optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'What did you like or dislike about the session?',
            filled: true,
            fillColor: const Color(0xFFF0F4FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip for now', style: TextStyle(color: Colors.black45)),
          ),
        ),
      ]),
    );
  }
}
