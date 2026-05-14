import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/review_entity.dart';
import '../blocs/review_bloc.dart';

class ReviewScreenEnhanced extends StatefulWidget {
  final String courseId;
  final String token;

  const ReviewScreenEnhanced({
    Key? key,
    required this.courseId,
    required this.token,
  }) : super(key: key);

  @override
  State<ReviewScreenEnhanced> createState() => _ReviewScreenEnhancedState();
}

class _ReviewScreenEnhancedState extends State<ReviewScreenEnhanced> {
  late TextEditingController reviewController;
  double rating = 5.0;

  @override
  void initState() {
    super.initState();
    reviewController = TextEditingController();
    context.read<ReviewBloc>().add(LoadReviewsEvent(widget.courseId));
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Reviews')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPostReviewSection(),
            const SizedBox(height: 24),
            _buildReviewsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostReviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Your Review',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience with this course...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                child: const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      children: [
        Text('Rating: ', style: Theme.of(context).textTheme.bodyMedium),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () {
                setState(() {
                  rating = (index + 1).toDouble();
                });
              },
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 28,
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Reviews',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<ReviewBloc, ReviewState>(
          builder: (context, state) {
            if (state is ReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReviewLoaded) {
              if (state.reviews.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No reviews yet'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.reviews.length,
                itemBuilder: (context, index) {
                  final review = state.reviews[index];
                  return _buildReviewCard(review);
                },
              );
            } else if (state is ReviewError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewEntity review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.studentAvatar != null
                      ? NetworkImage(review.studentAvatar!)
                      : null,
                  child: review.studentAvatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.studentName ?? 'Anonymous',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _submitReview() {
    if (reviewController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a review')));
      return;
    }

    context.read<ReviewBloc>().add(
      PostReviewEvent(
        widget.courseId,
        reviewController.text,
        rating.toInt(),
        widget.token,
      ),
    );

    reviewController.clear();
    setState(() => rating = 5.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully')),
    );
  }
}
