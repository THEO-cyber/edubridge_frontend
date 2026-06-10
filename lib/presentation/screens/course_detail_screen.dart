import 'package:edubridge/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handling.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/progress_remote_data_source.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../blocs/enrollment_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import '../blocs/payment_bloc_provider.dart';
import 'payment_screen_enhanced.dart';

const _kNavy = Color(0xFF1A237E);

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
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
        courseId: courseId,
        isPaid: price > 0,
      ),
    );
  }
}

class _CourseDetailBody extends StatefulWidget {
  final String courseId;
  final String title;
  final String description;
  final String? imageUrl;
  final double price;
  final bool isPaid;

  const _CourseDetailBody({
    required this.courseId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isPaid,
  });

  @override
  State<_CourseDetailBody> createState() => _CourseDetailBodyState();
}

class _CourseDetailBodyState extends State<_CourseDetailBody> {
  final _wishlistDs = WishlistRemoteDataSource();
  bool _inWishlist = false;
  bool _wishlistLoading = false;
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return;
      final courses = await ProgressRemoteDataSource().fetchEnrolledCourses(token);
      final enrolled = courses.any((c) {
        final id = (c['courseId'] ?? c['course']?['id'] ?? c['id'] ?? '').toString();
        return id == widget.courseId;
      });
      if (mounted) setState(() => _isEnrolled = enrolled);
    } catch (_) {}
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
            const SnackBar(
              content: Text('Added to wishlist!'),
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
    return BlocListener<EnrollmentBloc, EnrollmentState>(
      listener: (context, state) {
        if (state is EnrollmentSuccess) setState(() => _isEnrolled = true);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        actions: [
          _wishlistLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  tooltip: _inWishlist
                      ? 'Remove from wishlist'
                      : 'Add to wishlist',
                  icon: Icon(
                    _inWishlist
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _inWishlist ? Colors.red[300] : Colors.white,
                  ),
                  onPressed: _toggleWishlist,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 220,
              width: double.infinity,
              child: widget.imageUrl != null
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  if (widget.isPaid)
                    Text(
                      '₦${widget.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: _kNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Free',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'About this course',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: TextStyle(
                          color: Colors.blueGrey.shade700, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _EnrollButton(
                    courseId: widget.courseId,
                    title: widget.title,
                    price: widget.price,
                    isPaid: widget.isPaid,
                  ),
                  const SizedBox(height: 12),
                  // Wishlist secondary button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _wishlistLoading ? null : _toggleWishlist,
                      icon: Icon(
                        _inWishlist
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _inWishlist ? Colors.red : _kNavy,
                        size: 20,
                      ),
                      label: Text(
                        _inWishlist
                            ? 'Remove from Wishlist'
                            : 'Save to Wishlist',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kNavy,
                        side: BorderSide(
                          color: _inWishlist ? Colors.red : _kNavy,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RatingSection(courseId: widget.courseId, canSubmit: _isEnrolled),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: _kNavy.withValues(alpha: 0.08),
      child: const Center(
          child: Icon(Icons.menu_book, size: 80, color: _kNavy)),
    );
  }
}

class _EnrollButton extends StatelessWidget {
  final String courseId;
  final String title;
  final double price;
  final bool isPaid;

  const _EnrollButton({
    required this.courseId,
    required this.title,
    required this.price,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EnrollmentBloc, EnrollmentState>(
      listener: (context, state) {
        if (state is EnrollmentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Enrolled successfully!'),
                backgroundColor: Colors.green),
          );
        } else if (state is EnrollmentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is EnrollmentLoading) {
          return const Center(child: CircularProgressIndicator(color: _kNavy));
        }
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              final token = await SecureStorage.getToken();
              if (!context.mounted) return;
              if (token == null || token.isEmpty) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                return;
              }
              if (isPaid) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PaymentBlocProvider(
                      child: PaymentScreenEnhanced(
                        courseId: courseId,
                        courseName: title,
                        price: price,
                      ),
                    ),
                  ),
                );
              } else {
                context
                    .read<EnrollmentBloc>()
                    .add(EnrollEvent(courseId, token));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isPaid
                  ? 'Buy Now — ₦${price.toStringAsFixed(2)}'
                  : 'Enroll for Free',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}

class _RatingSection extends StatefulWidget {
  final String courseId;
  final bool canSubmit;
  const _RatingSection({required this.courseId, required this.canSubmit});

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();
  bool _submitting = false;

  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewRemoteDataSource().fetchReviews(widget.courseId);
      if (mounted) setState(() { _reviews = reviews; _loadingReviews = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
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
        _reviewController.text.trim(),
        _selectedRating,
        token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() { _selectedRating = 0; _reviewController.clear(); });
      _loadReviews(); // refresh list after posting
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<num>(0, (s, r) => s + ((r['rating'] as num?) ?? 0));
    return sum / _reviews.length;
  }

  String _userName(Map<String, dynamic> r) {
    final u = r['user'] as Map<String, dynamic>?;
    if (u == null) return 'Anonymous';
    final username = (u['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;
    final first = (u['firstName'] ?? '').toString().trim();
    final last = (u['lastName'] ?? '').toString().trim();
    return '$first $last'.trim().isNotEmpty ? '$first $last'.trim() : 'Anonymous';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    const palette = [Color(0xFF37474F), Color(0xFF00695C), Color(0xFF283593), Color(0xFF4A148C)];
    return name.isEmpty ? palette[0] : palette[name.codeUnitAt(0) % palette.length];
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(children: [
          const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kNavy)),
          const SizedBox(width: 10),
          if (!_loadingReviews && _reviews.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => Icon(
                i < _avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 16,
              )),
            ),
            const SizedBox(width: 4),
            Text(
              '${_avgRating.toStringAsFixed(1)} (${_reviews.length})',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ]),
        const SizedBox(height: 12),

        // ── Reviews list ──
        if (_loadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: _kNavy, strokeWidth: 2)),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.rate_review_outlined, color: _kNavy, size: 36),
              SizedBox(height: 8),
              Text('No reviews yet. Be the first!',
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
            ]),
          )
        else
          ...(_reviews.map((r) {
            final name = _userName(r);
            final rating = (r['rating'] as num?)?.toInt() ?? 0;
            final content = (r['content'] ?? r['comment'] ?? '').toString().trim();
            final date = _formatDate(r['createdAt']?.toString());
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarColor(name),
                  child: Text(_initials(name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                    Text(date, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 14,
                    )),
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(content, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                  ],
                ])),
              ]),
            );
          })),

        // ── Submit form (enrolled users only) ──
        if (widget.canSubmit) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Leave a Review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kNavy)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _selectedRating = i + 1),
              child: Icon(
                i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber, size: 36,
              ),
            )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your review (optional)...',
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
                backgroundColor: _kNavy,
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
}
