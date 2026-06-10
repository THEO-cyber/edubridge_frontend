import 'package:edubridge/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handling.dart';
import '../../core/secure_storage.dart';
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

  @override
  void initState() {
    super.initState();
    _checkWishlist();
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
    return Scaffold(
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
                  _RatingSection(courseId: widget.courseId),
                ],
              ),
            ),
          ],
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
  const _RatingSection({required this.courseId});

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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
      setState(() {
        _selectedRating = 0;
        _reviewController.clear();
      });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate this Course',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = i + 1),
              child: Icon(
                i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 36,
              ),
            );
          }),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Submit Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }
}
